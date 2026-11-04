---------------- MODULE PSb2_Client ----------------
EXTENDS Naturals
CONSTANT MaxReqs
VARIABLES issued, ok, limited
cvars == <<issued, ok, limited>>
Init == issued = 0 /\ ok = 0 /\ limited = 0
Outstanding == issued > ok + limited
Send == /\ ~Outstanding                 \* one request at a time
        /\ issued < MaxReqs
        /\ issued' = issued + 1
        /\ UNCHANGED <<ok, limited>>
GotOk == /\ Outstanding
         /\ ok' = ok + 1
         /\ UNCHANGED <<issued, limited>>
Got429 == /\ Outstanding
          /\ limited' = limited + 1
          /\ UNCHANGED <<issued, ok>>
Next == Send \/ GotOk \/ Got429
Spec == Init /\ [][Next]_cvars
====================================================
