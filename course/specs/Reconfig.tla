---------------- MODULE Reconfig ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Mode
ASSUME Mode \in {"Direct", "CopyOnly", "JointNoEvidence", "Joint", "OldLingers"}
Old == {"A", "B", "C"}
New == {"C", "D", "E"}
Nodes == Old \cup New
Values == {"X", "Y"}
VARIABLES phase,     \* "old", "joint", or "new"
          val,       \* val[n]: the value node n has durably stored
          decided,   \* values acknowledged as decided
          copied     \* new nodes that have run the state copy
vars == <<phase, val, decided, copied>>

Init == /\ phase = "old"
        /\ val = [n \in Nodes |-> "none"]
        /\ decided = {}
        /\ copied = {}

Holding(v) == {n \in Nodes : val[n] = v}
Majority(s, c) == Cardinality(s \cap c) * 2 > Cardinality(c)
JointAck(s) == Majority(s, Old) /\ Majority(s, New)

\* The rule this phase uses to acknowledge a decision.
CanDecide(v) ==
    \/ phase = "old" /\ Majority(Holding(v), Old)
    \/ phase = "joint" /\ JointAck(Holding(v))
    \/ phase = "new" /\ Majority(Holding(v), New)
    \/ Mode = "OldLingers" /\ Majority(Holding(v), Old)

Voters == CASE phase = "old" -> Old
            [] phase = "joint" -> Nodes
            [] phase = "new" ->
                 IF Mode = "OldLingers" THEN Nodes ELSE New

Store(n, v) == /\ n \in Voters
               /\ val[n] = "none"
               /\ val' = [val EXCEPT ![n] = v]
               /\ UNCHANGED <<phase, decided, copied>>

Decide(v) == /\ CanDecide(v)
             /\ decided' = decided \cup {v}
             /\ UNCHANGED <<phase, val, copied>>

\* Copy the decided state, as it is right now, to a new node.
Copy(n) == /\ n \in New
           /\ copied' = copied \cup {n}
           /\ val' = IF decided = {} THEN val
                     ELSE [val EXCEPT ![n] = CHOOSE v \in decided : TRUE]
           /\ UNCHANGED <<phase, decided>>

UsesJoint == Mode \in {"JointNoEvidence", "Joint", "OldLingers"}

EnterJoint == /\ UsesJoint /\ phase = "old"
              /\ phase' = "joint"
              /\ UNCHANGED <<val, decided, copied>>

\* What must be true before the new configuration takes over.
ReadyToActivate ==
    CASE Mode = "Direct" -> phase = "old"
      [] Mode = "CopyOnly" -> phase = "old" /\ Majority(copied, New)
      [] Mode = "JointNoEvidence" -> phase = "joint"
      [] Mode \in {"Joint", "OldLingers"} ->
           /\ phase = "joint"
           /\ \A v \in decided : Majority(Holding(v), New)

Activate == /\ ReadyToActivate
            /\ phase' = "new"
            /\ UNCHANGED <<val, decided, copied>>

Next == \/ \E n \in Nodes, v \in Values : Store(n, v)
        \/ \E v \in Values : Decide(v)
        \/ \E n \in New : Copy(n)
        \/ EnterJoint \/ Activate
Spec == Init /\ [][Next]_vars

TypeOK == /\ phase \in {"old", "joint", "new"}
          /\ val \in [Nodes -> Values \cup {"none"}]
          /\ decided \subseteq Values
          /\ copied \subseteq New
Agreement == Cardinality(decided) <= 1
================================================
