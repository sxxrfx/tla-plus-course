------------------------------ MODULE PSl4_Hanoi4 ------------------------------
EXTENDS Integers
VARIABLES d1, d2, d3, d4

TypeOK == /\ d1 \in 1..3
          /\ d2 \in 1..3
          /\ d3 \in 1..3
          /\ d4 \in 1..3

Init == /\ d1 = 1
        /\ d2 = 1
        /\ d3 = 1
        /\ d4 = 1

MoveD1 == /\ d1' \in IF d1 = 1 THEN {2, 3}
                     ELSE IF d1 = 2 THEN {1, 3}
                     ELSE {1, 2}
          /\ d2' = d2
          /\ d3' = d3
          /\ d4' = d4

MoveD2 == /\ d1 /= d2
          /\ d2' = 6 - d1 - d2
          /\ d1' = d1
          /\ d3' = d3
          /\ d4' = d4

MoveD3 == /\ d1 = d2
          /\ d1 /= d3
          /\ d3' = 6 - d1 - d3
          /\ d1' = d1
          /\ d2' = d2
          /\ d4' = d4

\* d4 can move only when d1, d2 and d3 are all on the same other peg.
MoveD4 == /\ d1 = d2
          /\ d2 = d3
          /\ d1 /= d4
          /\ d4' = 6 - d1 - d4
          /\ d1' = d1
          /\ d2' = d2
          /\ d3' = d3

Next == MoveD1 \/ MoveD2 \/ MoveD3 \/ MoveD4

NotSolved == ~(d1 = 3 /\ d2 = 3 /\ d3 = 3 /\ d4 = 3)
=============================================================================
