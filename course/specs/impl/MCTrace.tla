------------------------------ MODULE MCTrace -------------------------------
EXTENDS TwoPhase
NotAllCommitted == \E r \in RM : rmState[r] # "committed"
=============================================================================
