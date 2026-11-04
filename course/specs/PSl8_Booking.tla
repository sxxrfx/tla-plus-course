---------------------------- MODULE PSl8_Booking ----------------------------
\* Two-phase commit for the trip booking, plus the operator's escape hatch:
\* a participant stuck in "prepared" can be forced to roll back by hand.
EXTENDS TwoPhase
BookSpec == TPInit /\ [][TPNext]_vars

HeuristicAbort(r) == /\ rmState[r] = "prepared"
                     /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
                     /\ UNCHANGED <<tmState, tmPrepared, msgs>>
OpsNext == TPNext \/ \E r \in RM : HeuristicAbort(r)
OpsSpec == TPInit /\ [][OpsNext]_vars

AG == INSTANCE PSl8_Agreement
Agreement == AG!ASpec
THEOREM BookSpec => Agreement
=============================================================================
