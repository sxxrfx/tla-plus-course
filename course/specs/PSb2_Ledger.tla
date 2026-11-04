---------------- MODULE PSb2_Ledger ----------------
EXTENDS Naturals
Accounts == {"alice", "bob"}
Xfers == {1, 2}
From == [x \in Xfers |-> IF x = 1 THEN "alice" ELSE "bob"]
To   == [x \in Xfers |-> IF x = 1 THEN "bob" ELSE "alice"]
Amt  == [x \in Xfers |-> IF x = 1 THEN 1 ELSE 2]
Total == 3
VARIABLES bal, status
vars == <<bal, status>>
Init == /\ bal = [a \in Accounts |-> IF a = "alice" THEN 2 ELSE 1]
        /\ status = [x \in Xfers |-> "new"]
Debit(x) == /\ status[x] = "new"
            /\ bal[From[x]] >= Amt[x]
            /\ bal' = [bal EXCEPT ![From[x]] = bal[From[x]] - Amt[x]]
            /\ status' = [status EXCEPT ![x] = "debited"]
Credit(x) == /\ status[x] = "debited"
             /\ bal' = [bal EXCEPT ![To[x]] = bal[To[x]] + Amt[x]]
             /\ status' = [status EXCEPT ![x] = "credited"]
Next == \E x \in Xfers : Debit(x) \/ Credit(x)
Spec == Init /\ [][Next]_vars

RECURSIVE SumOver(_, _)
SumOver(f, S) == IF S = {} THEN 0
                 ELSE LET s == CHOOSE e \in S : TRUE
                      IN  f[s] + SumOver(f, S \ {s})
InFlight == [x \in Xfers |-> IF status[x] = "debited" THEN Amt[x] ELSE 0]

TypeOK == /\ bal \in [Accounts -> 0..Total]
          /\ status \in [Xfers -> {"new", "debited", "credited"}]
NoMint == SumOver(bal, Accounts) <= Total
Conservation == SumOver(bal, Accounts) + SumOver(InFlight, Xfers) = Total
IndNoMint == TypeOK /\ NoMint
IndCons   == TypeOK /\ Conservation
====================================================
