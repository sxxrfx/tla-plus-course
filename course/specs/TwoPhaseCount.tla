---- MODULE TwoPhaseCount ----
\* The TM counts Prepared messages instead of adding RMs to a set.
EXTENDS TwoPhase, Integers, FiniteSets
VARIABLE tmCount
CountInit == TPInit /\ tmCount = 0
TMRcvCount(r) ==
  /\ tmState = "init"
  /\ [type |-> "Prepared", rm |-> r] \in msgs
  /\ tmCount < Cardinality(RM)
  /\ tmCount' = tmCount + 1
  /\ UNCHANGED vars
TMCommitCount ==
  /\ tmState = "init"
  /\ tmCount = Cardinality(RM)
  /\ tmState' = "done"
  /\ msgs' = msgs \cup {[type |-> "Commit"]}
  /\ UNCHANGED <<rmState, tmPrepared, tmCount>>
CountNext ==
  \/ TMCommitCount
  \/ \E r \in RM : TMRcvCount(r)
  \/ /\ TMAbort \/ \E r \in RM : \/ RMPrepare(r) \/ RMChooseToAbort(r)
                                 \/ RMRcvCommitMsg(r) \/ RMRcvAbortMsg(r)
     /\ UNCHANGED tmCount
====
