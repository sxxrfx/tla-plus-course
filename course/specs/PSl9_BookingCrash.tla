------------------------- MODULE PSl9_BookingCrash --------------------------
\* Not shown: SFSpec plus a TM crash. After Crash no TM action is enabled.
EXTENDS PSl9_BookingLive
VARIABLE tmUp
CInit == Init /\ tmUp = TRUE
Crash == tmUp /\ tmUp' = FALSE /\ UNCHANGED vars
TMActs == TMDecide \/ \E r \in RM : TMRcvPrepared(r) \/ TMResend(r)
RMActs == Lose \/ \E r \in RM : \/ RMPrepare(r) \/ RMChooseToAbort(r) \/ RMResend(r)
                                \/ RMRcvCommit(r) \/ RMRcvAbort(r)
CNext == Crash \/ (tmUp /\ TMActs /\ UNCHANGED tmUp) \/ (RMActs /\ UNCHANGED tmUp)
cv == <<vars, tmUp>>
CSpec == CInit /\ [][CNext]_cv
  /\ WF_cv(tmUp /\ TMDecide /\ UNCHANGED tmUp)
  /\ \A r \in RM : /\ WF_cv((RMPrepare(r) \/ RMChooseToAbort(r)) /\ UNCHANGED tmUp)
                   /\ WF_cv(RMResend(r) /\ UNCHANGED tmUp)
                   /\ WF_cv(tmUp /\ TMResend(r) /\ UNCHANGED tmUp)
                   /\ SF_cv(tmUp /\ TMRcvPrepared(r) /\ UNCHANGED tmUp)
                   /\ SF_cv((RMRcvCommit(r) \/ RMRcvAbort(r)) /\ UNCHANGED tmUp)
=============================================================================
