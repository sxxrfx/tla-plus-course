-------------------------- MODULE PSl7_QuorumAny ----------------------------
\* Not shown: the read returns the version of any one replica it asked.
EXTENDS PSl7_Quorum
ReadAny == /\ acked
           /\ seen = 0
           /\ \E Q \in ReadSets : \E n \in Q : seen' = version[n]
           /\ UNCHANGED <<version, acked>>
NextAny == Ack \/ ReadAny \/ \E n \in Replica : Store(n)
=============================================================================
