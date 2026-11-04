------------------------------ MODULE PSl4_Hanoi ------------------------------
EXTENDS Integers

\* d1 is the smallest disk, d3 the largest. Each holds the peg (1, 2 or 3)
\* the disk is on. On any peg, the disks sit in size order.
VARIABLES d1, d2, d3

TypeOK == /\ d1 \in 1..3
          /\ d2 \in 1..3
          /\ d3 \in 1..3

Init == /\ d1 = 1
        /\ d2 = 1
        /\ d3 = 1

\* The smallest disk is always on top, and can go to either other peg.
MoveD1 == /\ d1' \in IF d1 = 1 THEN {2, 3}
                     ELSE IF d1 = 2 THEN {1, 3}
                     ELSE {1, 2}
          /\ d2' = d2
          /\ d3' = d3

\* d2 is on top if d1 isn't on its peg. It can't go onto d1, so it goes to
\* the one remaining peg. Pegs are 1, 2, 3, so the third one is 6 - d1 - d2.
MoveD2 == /\ d1 /= d2
          /\ d2' = 6 - d1 - d2
          /\ d1' = d1
          /\ d3' = d3

\* d3 can move only when d1 and d2 are both on the same other peg.
MoveD3 == /\ d1 = d2
          /\ d1 /= d3
          /\ d3' = 6 - d1 - d3
          /\ d1' = d1
          /\ d2' = d2

Next == MoveD1 \/ MoveD2 \/ MoveD3

NotSolved == ~(d1 = 3 /\ d2 = 3 /\ d3 = 3)
=============================================================================
