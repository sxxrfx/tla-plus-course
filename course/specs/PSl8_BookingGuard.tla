------------------------- MODULE PSl8_BookingGuard --------------------------
\* Not shown: heuristic rollback allowed only while no Commit has been sent.
EXTENDS PSl8_Booking
GuardedAbort(r) == [type |-> "Commit"] \notin msgs /\ HeuristicAbort(r)
GNext == TPNext \/ \E r \in RM : GuardedAbort(r)
GSpec == TPInit /\ [][GNext]_vars
=============================================================================
