------------------------------- MODULE MCAB2Pw ------------------------------
EXTENDS AB2P
Bound == (Len(AtoB2) <= 2) /\ (Len(BtoA2) <= 2)
HighFair == ABS!FairSpec
NoGoodFairness == SpecP /\ WF_varsP(ARcvP) /\ WF_varsP(BRcvP)
                        /\ WF_varsP(ASndP) /\ WF_varsP(BSndP)
=============================================================================
