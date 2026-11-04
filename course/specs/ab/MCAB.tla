-------------------------------- MODULE MCAB --------------------------------
EXTENDS AB
Bound == (Len(AtoB) <= 2) /\ (Len(BtoA) <= 2)
HighSafety == ABS!Spec
HighFair == ABS!FairSpec
Delivered == \A v \in Data \X {0, 1} : (AVar = v) ~> (BVar = v)
WeakSpec == Spec /\ WF_vars(ARcv) /\ WF_vars(BRcv)
                 /\ WF_vars(ASnd) /\ WF_vars(BSnd)
WFNextSpec == Spec /\ WF_vars(Next)
=============================================================================
