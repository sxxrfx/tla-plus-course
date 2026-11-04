------------------ MODULE PSl2_Bisect ------------------
EXTENDS Integers
VARIABLES lo, hi

Init == /\ lo = 1
        /\ hi = 16

MarkBad == /\ lo < hi
           /\ hi' \in lo..(hi - 1)
           /\ lo' = lo

MarkGood == /\ lo < hi
            /\ lo' \in (lo + 1)..hi
            /\ hi' = hi

Next == MarkBad \/ MarkGood
========================================================
