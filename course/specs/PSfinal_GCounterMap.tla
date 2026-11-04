---------------- MODULE PSfinal_GCounterMap ----------------
EXTENDS PSfinal_GCounter
\* A different mapping: the contract's count is what one replica displays.
Watched == CHOOSE r \in Replicas : TRUE
Displayed == INSTANCE PSfinal_Counter WITH count <- Value(Watched)
RefinesDisplayed == Displayed!Spec
=============================================================
