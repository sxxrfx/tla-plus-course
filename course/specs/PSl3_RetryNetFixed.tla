----------------- MODULE PSl3_RetryNetFixed -----------------
EXTENDS Integers
VARIABLES attempts, ok, pc, resp

Init == /\ attempts = 0
        /\ ok = FALSE
        /\ pc = "test"
        /\ resp = "none"

Test == /\ pc = "test"
        /\ ~ok
        /\ attempts < 3
        /\ pc' = "send"
        /\ attempts' = attempts
        /\ ok' = ok
        /\ resp' = resp

Exit == /\ pc = "test"
        /\ (ok \/ ~(attempts < 3))
        /\ pc' = "done"
        /\ attempts' = attempts
        /\ ok' = ok
        /\ resp' = resp

Send == /\ pc = "send"
        /\ (resp' = "ok" \/ resp' = "err" \/ resp' = "lost")
        /\ pc' = "wait"
        /\ attempts' = attempts
        /\ ok' = ok

GotOk  == /\ pc = "wait"
          /\ resp = "ok"
          /\ ok' = TRUE
          /\ pc' = "count"
          /\ attempts' = attempts
          /\ resp' = resp

GotErr == /\ pc = "wait"
          /\ resp = "err"
          /\ ok' = FALSE
          /\ pc' = "count"
          /\ attempts' = attempts
          /\ resp' = resp

Timeout == /\ pc = "wait"
           /\ resp = "lost"
           /\ ok' = FALSE
           /\ pc' = "count"
           /\ attempts' = attempts
           /\ resp' = resp

Count == /\ pc = "count"
         /\ attempts' = attempts + 1
         /\ pc' = "test"
         /\ ok' = ok
         /\ resp' = resp

Done == /\ pc = "done"
        /\ pc' = pc
        /\ attempts' = attempts
        /\ ok' = ok
        /\ resp' = resp

Next == Test \/ Exit \/ Send \/ GotOk \/ GotErr \/ Timeout \/ Count \/ Done

BudgetOK == attempts \in 0..3
========================================================
