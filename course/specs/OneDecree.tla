----------------------------- MODULE OneDecree ------------------------------
\* One Paxos consensus instance, cut out of PaxosCommit: the ins field and the
\* RMs are gone, and with no earlier evidence a leader may propose any value.
EXTENDS Integers
Maximum(S) == IF S = {} THEN -1
                        ELSE CHOOSE n \in S : \A m \in S : n >= m
CONSTANTS Value, Acceptor, Majority, Ballot
ASSUME /\ Ballot \subseteq Nat \ {0}
       /\ \A MS1, MS2 \in Majority : MS1 \cap MS2 # {}
VARIABLES aState, msgs
vars == <<aState, msgs>>

Init == /\ aState = [a \in Acceptor |-> [mbal |-> 0, bal |-> -1, val |-> "none"]]
        /\ msgs = {}
Send(m) == msgs' = msgs \cup {m}

Phase1a(b) == /\ Send([type |-> "1a", bal |-> b])
              /\ UNCHANGED aState

Phase1b(a) ==
  \E m \in msgs :
    /\ m.type = "1a"
    /\ aState[a].mbal < m.bal
    /\ aState' = [aState EXCEPT ![a].mbal = m.bal]
    /\ Send([type |-> "1b", mbal |-> m.bal, bal |-> aState[a].bal,
             val |-> aState[a].val, acc |-> a])

Reports(b, MS) == {m \in msgs : /\ m.type = "1b" /\ m.mbal = b /\ m.acc \in MS}
FromAll(b, MS) == \A a \in MS : \E m \in Reports(b, MS) : m.acc = a
NotUsed(b) == ~\E m \in msgs : m.type = "2a" /\ m.bal = b

\* The rule that matters: repeat the value of the highest ballot reported.
Phase2a(b) ==
  /\ NotUsed(b)
  /\ \E MS \in Majority, v \in Value :
       LET maxbal == Maximum({m.bal : m \in Reports(b, MS)})
       IN  /\ FromAll(b, MS)
           /\ \/ maxbal = -1
              \/ \E m \in Reports(b, MS) : m.bal = maxbal /\ m.val = v
           /\ Send([type |-> "2a", bal |-> b, val |-> v])
  /\ UNCHANGED aState

\* The broken version: same quorum, but the reports are ignored.
Phase2aForget(b) ==
  /\ NotUsed(b)
  /\ \E MS \in Majority, v \in Value :
       /\ FromAll(b, MS)
       /\ Send([type |-> "2a", bal |-> b, val |-> v])
  /\ UNCHANGED aState

Phase2b(a) ==
  \E m \in msgs :
    /\ m.type = "2a"
    /\ aState[a].mbal <= m.bal
    /\ aState' = [aState EXCEPT ![a].mbal = m.bal,
                                ![a].bal  = m.bal,
                                ![a].val  = m.val]
    /\ Send([type |-> "2b", bal |-> m.bal, val |-> m.val, acc |-> a])

Next == \/ \E b \in Ballot : Phase1a(b) \/ Phase2a(b)
        \/ \E a \in Acceptor : Phase1b(a) \/ Phase2b(a)
NextForget == \/ \E b \in Ballot : Phase1a(b) \/ Phase2aForget(b)
              \/ \E a \in Acceptor : Phase1b(a) \/ Phase2b(a)

Chosen(v) == \E b \in Ballot, MS \in Majority :
               \A a \in MS : [type |-> "2b", bal |-> b, val |-> v, acc |-> a] \in msgs
Agreement == \A v, w \in Value : Chosen(v) /\ Chosen(w) => v = w
OneValuePerBallot == \A m1, m2 \in msgs :
  (m1.type = "2b" /\ m2.type = "2b" /\ m1.bal = m2.bal) => m1.val = m2.val
=============================================================================
