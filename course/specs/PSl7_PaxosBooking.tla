------------------------- MODULE PSl7_PaxosBooking --------------------------
\* Paxos Commit for the booking, with some acceptors crashed for good.
\* Only acceptors in Up ever take a step; the others stay silent forever.
\* Leader actions need no "up" flag: any live process may act as leader.
EXTENDS PaxosCommit
CONSTANT Up
ASSUME Up \subseteq Acceptor

UpNext ==
  \/ \E r \in RM : \/ RMPrepare(r) \/ RMChooseToAbort(r)
                   \/ RMRcvCommitMsg(r) \/ RMRcvAbortMsg(r)
  \/ \E bal \in Ballot \ {0}, r \in RM : Phase1a(bal, r) \/ Phase2a(bal, r)
  \/ PCDecide
  \/ \E acc \in Up : Phase1b(acc) \/ Phase2b(acc)

\* Claims that FAIL exactly when the protocol can still make progress:
NeverAllCommitted == \E r \in RM : rmState[r] # "committed"
NeverDecided == [type |-> "Commit"] \notin msgs /\ [type |-> "Abort"] \notin msgs
=============================================================================
