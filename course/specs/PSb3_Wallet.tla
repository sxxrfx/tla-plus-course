---------------- MODULE PSb3_Wallet ----------------
EXTENDS Naturals
CONSTANTS Handlers, Mode
ASSUME Mode \in {"NoTx", "KeyThenDebit", "TxAfterCheck", "KeyFirstTx"}
VARIABLES ledger,   \* durable: debit rows written for key k
          stored,   \* durable: does the idem row for k exist?
          pc,       \* pc[h]: volatile position of handler h
          replied   \* the client has received "ok"
vars == <<ledger, stored, pc, replied>>

Init == /\ ledger = 0
        /\ stored = FALSE
        /\ pc = [h \in Handlers |-> "idle"]
        /\ replied = FALSE

Go(h, where) == pc' = [pc EXCEPT ![h] = where]

\* An attempt (the first try or a retry with the same key) reaches h.
Receive(h) == /\ pc[h] = "idle"
              /\ Go(h, "select")
              /\ UNCHANGED <<ledger, stored, replied>>

\* SELECT response FROM idem WHERE key = k
Select(h) == /\ pc[h] = "select" /\ Mode # "KeyFirstTx"
             /\ Go(h, IF stored THEN "reply" ELSE "write")
             /\ UNCHANGED <<ledger, stored, replied>>

\* NoTx: two autocommitted INSERTs.
Debit(h)   == /\ pc[h] = "write" /\ Mode = "NoTx"
              /\ ledger' = ledger + 1
              /\ Go(h, "key")
              /\ UNCHANGED <<stored, replied>>
SaveKey(h) == /\ pc[h] = "key"
              /\ stored' = TRUE
              /\ Go(h, "reply")
              /\ UNCHANGED <<ledger, replied>>

\* KeyThenDebit: the same two INSERTs, in the other order.
KeyFirst(h)  == /\ pc[h] = "write" /\ Mode = "KeyThenDebit"
                /\ stored' = TRUE
                /\ Go(h, "debit")
                /\ UNCHANGED <<ledger, replied>>
DebitLast(h) == /\ pc[h] = "debit"
                /\ ledger' = ledger + 1
                /\ Go(h, "reply")
                /\ UNCHANGED <<stored, replied>>

\* TxAfterCheck: both INSERTs in one transaction, after the SELECT.
Commit(h) == /\ pc[h] = "write" /\ Mode = "TxAfterCheck"
             /\ ledger' = ledger + 1
             /\ stored' = TRUE
             /\ Go(h, "reply")
             /\ UNCHANGED replied

\* KeyFirstTx: BEGIN; INSERT INTO idem (k is its primary key);
\* INSERT INTO ledger; COMMIT. If k already exists the INSERT fails,
\* nothing is written, and the handler returns the stored response.
KeyTx(h) == /\ pc[h] = "select" /\ Mode = "KeyFirstTx"
            /\ IF stored THEN UNCHANGED <<ledger, stored>>
                         ELSE /\ ledger' = ledger + 1
                              /\ stored' = TRUE
            /\ Go(h, "reply")
            /\ UNCHANGED replied

Reply(h) == /\ pc[h] = "reply"
            /\ replied' = TRUE
            /\ Go(h, "idle")
            /\ UNCHANGED <<ledger, stored>>

\* The process dies: its position is lost, the database is not.
Crash(h) == /\ pc[h] # "idle"
            /\ Go(h, "idle")
            /\ UNCHANGED <<ledger, stored, replied>>

Next == \E h \in Handlers :
          \/ Receive(h) \/ Select(h) \/ Debit(h) \/ SaveKey(h)
          \/ KeyFirst(h) \/ DebitLast(h)
          \/ Commit(h) \/ KeyTx(h) \/ Reply(h) \/ Crash(h)
Spec == Init /\ [][Next]_vars

AtMostOnce    == ledger <= 1
OkMeansDebited == replied => ledger >= 1
Bound         == ledger <= 2      \* keeps the buggy designs finite
====================================================
