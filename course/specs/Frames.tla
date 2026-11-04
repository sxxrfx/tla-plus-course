---------------- MODULE Frames ----------------
VARIABLES x, y
vars == <<x, y>>
Init == x = 0 /\ y = 0
\* Each component written as if it owned the whole state:
A == x = 0 /\ x' = 1 /\ y' = y
B == y = 0 /\ y' = 1 /\ x' = x
SpecA == Init /\ [][A]_vars
SpecB == Init /\ [][B]_vars
Conjoined == [A]_vars /\ [B]_vars
Interleaved == A \/ B
\* Each component constrains only its own variable:
OwnX == x = 0 /\ x' = 1
OwnY == y = 0 /\ y' = 1
OwnVars == [OwnX]_x /\ [OwnY]_y
===============================================
