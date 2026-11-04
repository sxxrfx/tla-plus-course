------------------------------ MODULE MCABSpec ------------------------------
EXTENDS ABSpec
Delivered == \A v \in Data \X {0, 1} : (AVar = v) ~> (BVar = v)
SenderMayStop == Spec /\ WF_vars(B)
FairAB == Spec /\ WF_vars(A) /\ WF_vars(B)
KeepsSending == \A v \in Data \X {0, 1} : []<>(AVar # v)
=============================================================================
