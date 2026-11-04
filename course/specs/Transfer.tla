---------------- MODULE Transfer ----------------
EXTENDS Naturals
VARIABLES alice, transit, bob
vars == <<alice, transit, bob>>
Init == alice = 2 /\ transit = 0 /\ bob = 0
Debit == /\ alice = 2           \* one transfer only
         /\ alice' = alice - 1
         /\ transit' = transit + 1
         /\ UNCHANGED bob
Credit == /\ transit > 0
          /\ transit' = transit - 1
          /\ bob' = bob + 1
          /\ UNCHANGED alice
Next == Debit \/ Credit
Spec == Init /\ [][Next]_vars
TypeOK == /\ alice \in 0..2
          /\ transit \in 0..2
          /\ bob \in 0..2
Naive == alice + bob = 2
BobAtMostOne == bob <= 1
Inv == TypeOK /\ alice + transit + bob = 2
\* Start TLC from every state a candidate allows:
IndCandidate == TypeOK /\ BobAtMostOne
=================================================
