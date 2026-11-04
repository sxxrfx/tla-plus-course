-------------------------------- MODULE AB2H --------------------------------
EXTENDS Integers, Sequences
CONSTANTS Data, Bad
VARIABLES AVar, BVar, AtoB2, BtoA2

AB2 == INSTANCE AB2

VARIABLES AtoB, BtoA

RECURSIVE RemoveBad(_)
RemoveBad(seq) == IF seq = <<>>
                    THEN <<>>
                    ELSE IF Head(seq) = Bad
                           THEN RemoveBad(Tail(seq))
                           ELSE <<Head(seq)>> \o RemoveBad(Tail(seq))

SpecH == /\ AB2!Spec
         /\ [] /\ AtoB = RemoveBad(AtoB2)
               /\ BtoA = RemoveBad(BtoA2)

AB == INSTANCE AB

THEOREM SpecH => AB!Spec
=============================================================================
