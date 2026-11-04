------------------ MODULE PSl3_Euclid1218 ------------------
EXTENDS Integers
VARIABLES x, y

M == 12
N == 18

Init == /\ x = M
        /\ y = N

SubY == /\ y < x
        /\ x' = x - y
        /\ y' = y

SubX == /\ x < y
        /\ y' = y - x
        /\ x' = x

Next == SubY \/ SubX

Positive == x > 0 /\ y > 0
Answer   == (x = y) => (x = 6)
========================================================
