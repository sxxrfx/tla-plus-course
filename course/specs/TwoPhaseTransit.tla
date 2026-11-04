---- MODULE TwoPhaseTransit ----
\* msgs holds only messages in transit: receiving a message removes it.
\* There is still one Commit record for all RMs.
EXTENDS TwoPhase
Rcv(m) == msgs' = msgs \ {m}
RcvPrepared(r) ==
  /\ tmState = "init"
  /\ [type |-> "Prepared", rm |-> r] \in msgs
  /\ tmPrepared' = tmPrepared \cup {r}
  /\ Rcv([type |-> "Prepared", rm |-> r])
  /\ UNCHANGED <<rmState, tmState>>
RcvCommit(r) ==
  /\ [type |-> "Commit"] \in msgs
  /\ rmState' = [rmState EXCEPT ![r] = "committed"]
  /\ Rcv([type |-> "Commit"])
  /\ UNCHANGED <<tmState, tmPrepared>>
RcvAbort(r) ==
  /\ [type |-> "Abort"] \in msgs
  /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
  /\ Rcv([type |-> "Abort"])
  /\ UNCHANGED <<tmState, tmPrepared>>
TransitNext ==
  \/ TMCommit \/ TMAbort
  \/ \E r \in RM : RcvPrepared(r) \/ RMPrepare(r) \/ RMChooseToAbort(r)
                     \/ RcvCommit(r) \/ RcvAbort(r)
NeverAllCommitted == ~ \A r \in RM : rmState[r] = "committed"
====
