---- MODULE TwoPhaseCopies ----
\* In-transit messages again, now with one addressed copy per RM.
EXTENDS TwoPhase
Copies(t) == {[type |-> t, to |-> r] : r \in RM}
CM(r) == [type |-> "Commit", to |-> r]
AM(r) == [type |-> "Abort", to |-> r]
RcvPrepared(r) ==
  /\ tmState = "init"
  /\ [type |-> "Prepared", rm |-> r] \in msgs
  /\ tmPrepared' = tmPrepared \cup {r}
  /\ msgs' = msgs \ {[type |-> "Prepared", rm |-> r]}
  /\ UNCHANGED <<rmState, tmState>>
SendCommit == /\ tmState = "init" /\ tmPrepared = RM
              /\ tmState' = "done"
              /\ msgs' = msgs \cup Copies("Commit")
              /\ UNCHANGED <<rmState, tmPrepared>>
SendAbort ==  /\ tmState = "init"
              /\ tmState' = "done"
              /\ msgs' = msgs \cup Copies("Abort")
              /\ UNCHANGED <<rmState, tmPrepared>>
RcvCommit(r) == /\ CM(r) \in msgs
                /\ rmState' = [rmState EXCEPT ![r] = "committed"]
                /\ msgs' = msgs \ {CM(r)}
                /\ UNCHANGED <<tmState, tmPrepared>>
RcvAbort(r) ==  /\ AM(r) \in msgs
                /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
                /\ msgs' = msgs \ {AM(r)}
                /\ UNCHANGED <<tmState, tmPrepared>>
CopiesNext ==
  \/ SendCommit \/ SendAbort
  \/ \E r \in RM : RcvPrepared(r) \/ RMPrepare(r) \/ RMChooseToAbort(r)
                     \/ RcvCommit(r) \/ RcvAbort(r)
NeverAllCommitted == ~ \A r \in RM : rmState[r] = "committed"
====
