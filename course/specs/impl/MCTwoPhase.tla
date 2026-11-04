------------------------------ MODULE MCTwoPhase ----------------------------
EXTENDS TwoPhase
AlwaysTypeOK == []TPTypeOK
\* TCNext with the subscript widened to every TwoPhase variable: the only
\* stuttering this allows is a step that changes none of the four variables.
NoInvisibleSteps == [][TCNext]_<<rmState, tmState, tmPrepared, msgs>>
=============================================================================
