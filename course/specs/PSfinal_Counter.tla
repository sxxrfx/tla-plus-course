---------------- MODULE PSfinal_Counter ----------------
EXTENDS Naturals
VARIABLE count          \* likes on one post: the contract
Init == count = 0
Next == count' = count + 1
Spec == Init /\ [][Next]_count
=========================================================
