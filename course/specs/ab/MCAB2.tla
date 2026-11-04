-------------------------------- MODULE MCAB2 -------------------------------
EXTENDS AB2
Bound == (Len(AtoB2) <= 2) /\ (Len(BtoA2) <= 2)
HighSafety == ABS!Spec
HighFair == ABS!FairSpec
ABSafety == AB!Spec
\* A wrong refinement mapping: keep the corrupted slots.
WrongAB == INSTANCE AB WITH AtoB <- AtoB2, BtoA <- BtoA2
WrongMapping == WrongAB!Spec
\* Another wrong one: forget the channels altogether.
EmptyAB == INSTANCE AB WITH AtoB <- <<>>, BtoA <- <<>>
EmptyMapping == EmptyAB!Spec
=============================================================================
