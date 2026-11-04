-------------------------- MODULE PSl7_TwoPCBooking -------------------------
\* Two-phase commit for the booking, plus a coordinator crash: after Crash
\* the TM takes no step ever again. RMs are unchanged from TwoPhase.
EXTENDS TwoPhase
VARIABLE tmUp
CInit == TPInit /\ tmUp = TRUE
Crash == /\ tmUp
         /\ tmUp' = FALSE
         /\ UNCHANGED vars
CNext == \/ Crash
         \/ /\ tmUp
            /\ \/ TMCommit \/ TMAbort
               \/ \E r \in RM : TMRcvPrepared(r)
            /\ UNCHANGED tmUp
         \/ /\ \E r \in RM : \/ RMPrepare(r) \/ RMChooseToAbort(r)
                             \/ RMRcvCommitMsg(r) \/ RMRcvAbortMsg(r)
            /\ UNCHANGED tmUp
NeverDecided == [type |-> "Commit"] \notin msgs /\ [type |-> "Abort"] \notin msgs
\* Everyone has voted yes and nobody can ever learn the outcome.
InDoubt == ~tmUp /\ NeverDecided /\ \A r \in RM : rmState[r] = "prepared"
NotInDoubt == ~InDoubt
=============================================================================
