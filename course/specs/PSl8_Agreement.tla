--------------------------- MODULE PSl8_Agreement ---------------------------
\* All-or-nothing agreement, TCommit with its spec written as one formula.
CONSTANT RM
VARIABLE rmState
AInit == rmState = [r \in RM |-> "working"]
canCommit == \A r \in RM : rmState[r] \in {"prepared", "committed"}
notCommitted == \A r \in RM : rmState[r] # "committed"
Prepare(r) == /\ rmState[r] = "working"
              /\ rmState' = [rmState EXCEPT ![r] = "prepared"]
Decide(r) == \/ /\ rmState[r] = "prepared"
                /\ canCommit
                /\ rmState' = [rmState EXCEPT ![r] = "committed"]
             \/ /\ rmState[r] \in {"working", "prepared"}
                /\ notCommitted
                /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
ANext == \E r \in RM : Prepare(r) \/ Decide(r)
ASpec == AInit /\ [][ANext]_rmState
=============================================================================
