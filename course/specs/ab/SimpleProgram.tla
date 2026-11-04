----------------------------- MODULE SimpleProgram --------------------------
EXTENDS Integers
VARIABLES i, pc
vars == <<pc, i>>
Init == (pc = "start") /\ (i = 0)
Next == \/ /\ pc = "start"
           /\ i' \in 0..1000
           /\ pc' = "middle"
        \/ /\ pc = "middle"
           /\ i' = i + 1
           /\ pc' = "done"
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ WF_vars(Next)
Terminates == <>(pc = "done")
NoDeadlockHack == Next \/ UNCHANGED vars
=============================================================================
