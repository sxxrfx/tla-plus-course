---------------- MODULE CounterBug ----------------
EXTENDS Integers
VARIABLE x

Max == 3

Init == x = 0

Next == /\ x =< Max
        /\ x' = x + 1

Safe == x =< Max
================================================
