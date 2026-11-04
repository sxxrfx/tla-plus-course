--------------------------- MODULE PSl7_Placement ---------------------------
\* Where to put the members of a quorum-based cluster. DCs is a set of sets:
\* each element is the set of nodes in one data centre. The variable lost is
\* the one data centre that has gone dark; Init lets TLC try each in turn.
EXTENDS Integers, FiniteSets
CONSTANTS Node, DCs, QSize
ASSUME \A d1, d2 \in DCs : d1 # d2 => d1 \cap d2 = {}   \* no node in two DCs
ASSUME \A n \in Node : \E d \in DCs : n \in d           \* every node placed
VARIABLE lost
Quorum == {Q \in SUBSET Node : Cardinality(Q) >= QSize}
\* The property Paxos and Raft rely on, checked before any state is explored.
QuorumsOverlap == \A Q1, Q2 \in Quorum : Q1 \cap Q2 # {}
ASSUME QuorumsOverlap

Init == lost \in DCs
Next == UNCHANGED lost

\* Some quorum is made only of nodes outside the lost data centre.
QuorumSurvives == \E Q \in Quorum : Q \cap lost = {}
=============================================================================
