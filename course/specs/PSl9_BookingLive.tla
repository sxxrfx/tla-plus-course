-------------------------- MODULE PSl9_BookingLive --------------------------
\* Two-phase commit for the trip booking over a network that loses messages.
\* net holds the messages in flight: receiving or losing one removes it, so
\* a lost message is gone unless someone sends it again. net is a set, so it
\* never holds more than the finitely many different messages.
CONSTANT RM
VARIABLES rmState, tmState, tmPrepared, net
vars == <<rmState, tmState, tmPrepared, net>>
Prep(r) == [type |-> "Prepared", rm |-> r]
Dec(r)  == [type |-> IF tmState = "commit" THEN "Commit" ELSE "Abort", rm |-> r]

Init == /\ rmState = [r \in RM |-> "working"]
        /\ tmState = "init"          \* then "commit" or "abort"
        /\ tmPrepared = {}
        /\ net = {}
-----------------------------------------------------------------------------
RMPrepare(r) == /\ rmState[r] = "working"
                /\ rmState' = [rmState EXCEPT ![r] = "prepared"]
                /\ net' = net \cup {Prep(r)}
                /\ UNCHANGED <<tmState, tmPrepared>>
RMChooseToAbort(r) == /\ rmState[r] = "working"
                      /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
                      /\ UNCHANGED <<tmState, tmPrepared, net>>
RMRcvCommit(r) == /\ [type |-> "Commit", rm |-> r] \in net
                  /\ rmState' = [rmState EXCEPT ![r] = "committed"]
                  /\ net' = net \ {[type |-> "Commit", rm |-> r]}
                  /\ UNCHANGED <<tmState, tmPrepared>>
RMRcvAbort(r) == /\ [type |-> "Abort", rm |-> r] \in net
                 /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
                 /\ net' = net \ {[type |-> "Abort", rm |-> r]}
                 /\ UNCHANGED <<tmState, tmPrepared>>
TMRcvPrepared(r) == /\ tmState = "init"
                    /\ Prep(r) \in net
                    /\ tmPrepared' = tmPrepared \cup {r}
                    /\ net' = net \ {Prep(r)}
                    /\ UNCHANGED <<rmState, tmState>>
\* The TM decides and sends one copy of the decision to every RM.
TMDecide ==
  /\ tmState = "init"
  /\ \/ /\ tmPrepared = RM
        /\ tmState' = "commit"
        /\ net' = net \cup {[type |-> "Commit", rm |-> r] : r \in RM}
     \/ /\ tmState' = "abort"                 \* e.g. after a timeout
        /\ net' = net \cup {[type |-> "Abort", rm |-> r] : r \in RM}
  /\ UNCHANGED <<rmState, tmPrepared>>
Lose == \E m \in net : /\ net' = net \ {m}
                       /\ UNCHANGED <<rmState, tmState, tmPrepared>>
\* Retries.
RMResend(r) == /\ rmState[r] = "prepared"
               /\ net' = net \cup {Prep(r)}
               /\ UNCHANGED <<rmState, tmState, tmPrepared>>
TMResend(r) == /\ tmState # "init"
               /\ net' = net \cup {Dec(r)}
               /\ UNCHANGED <<rmState, tmState, tmPrepared>>
-----------------------------------------------------------------------------
Core == \/ TMDecide \/ Lose
        \/ \E r \in RM : \/ RMPrepare(r) \/ RMChooseToAbort(r)
                         \/ RMRcvCommit(r) \/ RMRcvAbort(r) \/ TMRcvPrepared(r)
Next          == Core \/ \E r \in RM : RMResend(r) \/ TMResend(r)
NoTMRetryNext == Core \/ \E r \in RM : RMResend(r)
NoRMRetryNext == Core \/ \E r \in RM : TMResend(r)

Base == /\ WF_vars(TMDecide)
        /\ \A r \in RM : WF_vars(RMPrepare(r) \/ RMChooseToAbort(r))
WFRcv == \A r \in RM : /\ WF_vars(TMRcvPrepared(r))
                       /\ WF_vars(RMRcvCommit(r) \/ RMRcvAbort(r))
SFRcv == \A r \in RM : /\ SF_vars(TMRcvPrepared(r))
                       /\ SF_vars(RMRcvCommit(r) \/ RMRcvAbort(r))
RMRetry == \A r \in RM : WF_vars(RMResend(r))
TMRetry == \A r \in RM : WF_vars(TMResend(r))

WFSpec        == Init /\ [][Next]_vars /\ Base /\ WFRcv /\ RMRetry /\ TMRetry
SFSpec        == Init /\ [][Next]_vars /\ Base /\ SFRcv /\ RMRetry /\ TMRetry
NoTMRetrySpec == Init /\ [][NoTMRetryNext]_vars /\ Base /\ SFRcv /\ RMRetry
NoRMRetrySpec == Init /\ [][NoRMRetryNext]_vars /\ Base /\ SFRcv /\ TMRetry

Decided(r) == rmState[r] \in {"committed", "aborted"}
EveryoneDecides == \A r \in RM : <>Decided(r)
Consistent == \A r1, r2 \in RM : ~(rmState[r1] = "aborted" /\ rmState[r2] = "committed")
=============================================================================
