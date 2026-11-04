---------------------------- MODULE PSl7_Quorum -----------------------------
\* One key of a Dynamo-style store with replication factor N = |Replica|.
\* Every replica holds version 1. A client writes version 2: the coordinator
\* stores it replica by replica and reports success once W replicas have it.
\* A later read asks R replicas and returns the highest version it hears.
EXTENDS Integers, FiniteSets
CONSTANTS Replica, W, R
VARIABLES version,   \* version[n]: the version replica n stores
          acked,     \* the coordinator has told the client "write succeeded"
          seen       \* what the read returned (0 = no read yet)
vars == <<version, acked, seen>>

Maximum(S) == IF S = {} THEN -1
                        ELSE CHOOSE n \in S : \A m \in S : n >= m
WriteSets == {Q \in SUBSET Replica : Cardinality(Q) = W}
ReadSets  == {Q \in SUBSET Replica : Cardinality(Q) = R}

Init == /\ version = [n \in Replica |-> 1]
        /\ acked = FALSE
        /\ seen = 0

Store(n) == /\ version[n] = 1
            /\ version' = [version EXCEPT ![n] = 2]
            /\ UNCHANGED <<acked, seen>>

Ack == /\ ~acked
       /\ \E Q \in WriteSets : \A n \in Q : version[n] = 2
       /\ acked' = TRUE
       /\ UNCHANGED <<version, seen>>

Read == /\ acked
        /\ seen = 0
        /\ \E Q \in ReadSets : seen' = Maximum({version[n] : n \in Q})
        /\ UNCHANGED <<version, acked>>

Next == Ack \/ Read \/ \E n \in Replica : Store(n)

ReadsLatest == seen \in {0, 2}
Overlap == \A Wq \in WriteSets, Rq \in ReadSets : Wq \cap Rq # {}
=============================================================================
