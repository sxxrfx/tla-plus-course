------------------------------- MODULE PSl4_Dosing -------------------------------
EXTENDS Integers

Small == 4    \* litres the small chamber holds
Big   == 6    \* litres the big chamber holds

VARIABLES small, big

TypeOK == /\ small \in 0..Small
          /\ big   \in 0..Big

Init == /\ small = 0
        /\ big   = 0

FillSmall == /\ small' = Small
             /\ big'   = big

FillBig == /\ big'   = Big
           /\ small' = small

EmptySmall == /\ small' = 0
              /\ big'   = big

EmptyBig == /\ big'   = 0
            /\ small' = small

SmallToBig == IF big + small =< Big
                THEN /\ big'   = big + small
                     /\ small' = 0
                ELSE /\ big'   = Big
                     /\ small' = small - (Big - big)

BigToSmall == IF big + small =< Small
                THEN /\ big'   = 0
                     /\ small' = big + small
                ELSE /\ big'   = big - (Small - small)
                     /\ small' = Small

Next == \/ FillSmall  \/ FillBig
        \/ EmptySmall \/ EmptyBig
        \/ SmallToBig \/ BigToSmall

NoThree == /\ small /= 3
           /\ big   /= 3
NoTwo   == big /= 2
Even    == /\ small \in {0, 2, 4}
           /\ big   \in {0, 2, 4, 6}
=============================================================================
