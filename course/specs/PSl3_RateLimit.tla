----------------- MODULE PSl3_RateLimit -----------------
EXTENDS Integers
VARIABLES half, a1, a2, p2

Limit == 3

Init == /\ half = 1
        /\ a1 = 0
        /\ a2 = 0
        /\ p2 = 0

AcceptFirst  == /\ half = 1
                /\ a1 + a2 < Limit
                /\ a1' = a1 + 1
                /\ a2' = a2
                /\ p2' = p2
                /\ half' = half

AcceptSecond == /\ half = 2
                /\ a1 + a2 < Limit
                /\ a2' = a2 + 1
                /\ a1' = a1
                /\ p2' = p2
                /\ half' = half

Tick == \/ /\ half = 1
           /\ half' = 2
           /\ a1' = a1
           /\ a2' = a2
           /\ p2' = p2
        \/ /\ half = 2
           /\ half' = 1
           /\ p2' = a2
           /\ a1' = 0
           /\ a2' = 0

Next == AcceptFirst \/ AcceptSecond \/ Tick

WindowOK  == a1 + a2 =< Limit
SlidingOK == p2 + a1 =< Limit
=========================================================
