------------------ MODULE PSl2_Retry ------------------
EXTENDS Integers
VARIABLES attempts, ok, pc

Init == /\ attempts = 0
        /\ ok = FALSE
        /\ pc = "test"

Test == /\ pc = "test"
        /\ ~ok
        /\ attempts < 3
        /\ pc' = "send"
        /\ attempts' = attempts
        /\ ok' = ok

Exit == /\ pc = "test"
        /\ (ok \/ ~(attempts < 3))
        /\ pc' = "done"
        /\ attempts' = attempts
        /\ ok' = ok

Send == /\ pc = "send"
        /\ (ok' = TRUE \/ ok' = FALSE)
        /\ pc' = "count"
        /\ attempts' = attempts

Count == /\ pc = "count"
         /\ attempts' = attempts + 1
         /\ pc' = "test"
         /\ ok' = ok

Next == Test \/ Exit \/ Send \/ Count

BudgetOK == attempts \in 0..3
DoneOK == pc = "done" => (ok \/ attempts = 3)
=======================================================
