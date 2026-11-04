---------------- MODULE PSl10_Counter ----------------
EXTENDS Naturals
VARIABLE count
Init == count = 0
Inc == count' = count + 1
Spec == Init /\ [][Inc]_count
======================================================
