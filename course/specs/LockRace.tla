---------------- MODULE LockRace ----------------
EXTENDS Naturals, FiniteSets
CONSTANTS Processes, NoOwner
VARIABLES owner, pc
vars == <<owner, pc>>
Init == /\ owner = NoOwner
        /\ pc = [p \in Processes |-> "outside"]
Look(p) ==
    /\ pc[p] = "outside"
    /\ owner = NoOwner
    /\ pc' = [pc EXCEPT ![p] = "saw-free"]
    /\ UNCHANGED owner
Take(p) ==
    /\ pc[p] = "saw-free"
    /\ owner' = p
    /\ pc' = [pc EXCEPT ![p] = "critical"]
Release(p) ==
    /\ pc[p] = "critical"
    /\ owner' = NoOwner
    /\ pc' = [pc EXCEPT ![p] = "outside"]
Next == \E p \in Processes: Look(p) \/ Take(p) \/ Release(p)
Spec == Init /\ [][Next]_vars
MutualExclusion ==
    Cardinality({p \in Processes : pc[p] = "critical"}) <= 1
==================================================
