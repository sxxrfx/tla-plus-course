---- MODULE TwoPhaseBlock ----
\* TwoPhase plus one action: the TM crashes and never comes back.
EXTENDS TwoPhase
VARIABLE tmAlive
BlockInit == TPInit /\ tmAlive = TRUE
TMCrash == /\ tmAlive
           /\ tmAlive' = FALSE
           /\ UNCHANGED vars
BlockNext ==
  \/ TMCrash
  \/ /\ tmAlive
     /\ TMCommit \/ TMAbort \/ \E r \in RM : TMRcvPrepared(r)
     /\ UNCHANGED tmAlive
  \/ /\ \E r \in RM : \/ RMPrepare(r) \/ RMChooseToAbort(r)
                      \/ RMRcvCommitMsg(r) \/ RMRcvAbortMsg(r)
     /\ UNCHANGED tmAlive
NoDecision == [type |-> "Commit"] \notin msgs /\ [type |-> "Abort"] \notin msgs
Blocked == /\ ~tmAlive
           /\ NoDecision
           /\ \A r \in RM : rmState[r] = "prepared"
NotBlocked == ~Blocked
\* Once Blocked holds, no allowed step changes anything.
BlockedForever == [][Blocked => UNCHANGED <<vars, tmAlive>>]_<<vars, tmAlive>>
====
