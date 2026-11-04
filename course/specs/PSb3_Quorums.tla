---------------- MODULE PSb3_Quorums ----------------
EXTENDS Naturals, FiniteSets
CONSTANTS Old, New
Majorities(S) == {Q \in SUBSET S : 2 * Cardinality(Q) > Cardinality(S)}
VARIABLES q1, q2   \* an old-configuration quorum and a new one
InitAll == /\ q1 \in Majorities(Old)
           /\ q2 \in Majorities(New)
InitDisjoint == InitAll /\ q1 \cap q2 = {}
Next == UNCHANGED <<q1, q2>>     \* only the initial states matter
Overlap == q1 \cap q2 # {}
=====================================================
