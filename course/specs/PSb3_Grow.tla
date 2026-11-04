---------------- MODULE PSb3_Grow ----------------
EXTENDS Naturals, Sequences, FiniteSets
CONSTANTS Plan, Guarded
ASSUME Plan \in {"3to4", "3to5", "3to4to5"} /\ Guarded \in BOOLEAN
C3 == {"A", "B", "C"}
C4 == {"A", "B", "C", "D"}
C5 == {"A", "B", "C", "D", "E"}
Configs == CASE Plan = "3to4"    -> <<C3, C4>>
             [] Plan = "3to5"    -> <<C3, C5>>
             [] Plan = "3to4to5" -> <<C3, C4, C5>>
Nodes == C5
Values == {"X", "Y"}
VARIABLES cfg,      \* index of the active configuration in Configs
          val,      \* val[n]: the value node n has durably stored
          decided   \* values acknowledged as decided
vars == <<cfg, val, decided>>

Init == /\ cfg = 1
        /\ val = [n \in Nodes |-> "none"]
        /\ decided = {}

Majority(S, c) == 2 * Cardinality(S \cap c) > Cardinality(c)
Holding(v) == {n \in Nodes : val[n] = v}

Store(n, v) == /\ n \in Configs[cfg]
               /\ val[n] = "none"
               /\ val' = [val EXCEPT ![n] = v]
               /\ UNCHANGED <<cfg, decided>>

Decide(v) == /\ Majority(Holding(v), Configs[cfg])
             /\ decided' = decided \cup {v}
             /\ UNCHANGED <<cfg, val>>

\* Switch to the next configuration. Guarded: only once a majority of
\* the next configuration already stores every decided value.
Activate == /\ cfg < Len(Configs)
            /\ Guarded => \A v \in decided :
                             Majority(Holding(v), Configs[cfg + 1])
            /\ cfg' = cfg + 1
            /\ UNCHANGED <<val, decided>>

Next == \/ \E n \in Nodes, v \in Values : Store(n, v)
        \/ \E v \in Values : Decide(v)
        \/ Activate
Spec == Init /\ [][Next]_vars
Agreement == Cardinality(decided) <= 1
==================================================
