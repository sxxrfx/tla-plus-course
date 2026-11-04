---- MODULE TCommitBad ----
\* Decide with the notCommitted guard removed from the abort branch.
EXTENDS TCommit
BadDecide(r) == \/ /\ rmState[r] = "prepared"
                   /\ canCommit
                   /\ rmState' = [rmState EXCEPT ![r] = "committed"]
                \/ /\ rmState[r] \in {"working", "prepared"}
                   /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
BadNext == \E r \in RM : Prepare(r) \/ BadDecide(r)
====
