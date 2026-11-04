----------------------------- MODULE PriceQuorum ----------------------------
EXTENDS Integers, FiniteSets
CONSTANTS Replica, W, R          \* write-set size and read-set size
VARIABLES stored, acked, result  \* result: what a read returned (0 = none yet)
vars == <<stored, acked, result>>

WriteSets == {Q \in SUBSET Replica : Cardinality(Q) = W}
ReadSets  == {Q \in SUBSET Replica : Cardinality(Q) = R}

PInit == /\ stored = [n \in Replica |-> 7]
         /\ acked = FALSE
         /\ result = 0

Store(n) == /\ stored' = [stored EXCEPT ![n] = 8]
            /\ UNCHANGED <<acked, result>>

Ack == /\ \E Q \in WriteSets : \A n \in Q : stored[n] = 8
       /\ acked' = TRUE
       /\ UNCHANGED <<stored, result>>

\* A read after the ack hears from one read set and keeps the newer version.
Read == /\ acked
        /\ result = 0
        /\ \E Q \in ReadSets :
             result' = IF \E n \in Q : stored[n] = 8 THEN 8 ELSE 7
        /\ UNCHANGED <<stored, acked>>

PNext == Ack \/ Read \/ \E n \in Replica : Store(n)

SeesAckedWrite == result \in {0, 8}
=============================================================================
