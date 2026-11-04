---- MODULE MCTwoPhase ----
EXTENDS TwoPhase, TLC
CONSTANTS r1, r2, r3
RMs == {r1, r2, r3}
Sym == Permutations(RMs)
====
