------------------ MODULE PSl3_EuclidBug ------------------
EXTENDS Integers
VARIABLES x, y

M == 34
N == 21

Init == /\ x = M
        /\ y = N

SubY == /\ y =< x
        /\ x' = x - y
        /\ y' = y

SubX == /\ x < y
        /\ y' = y - x
        /\ x' = x

Next == SubY \/ SubX

Positive == x > 0 /\ y > 0
Answer   == (x = y) => (x = 1)
========================================================
