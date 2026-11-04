----------------------------- MODULE PSl9_Sensor ----------------------------
\* The alternating bit protocol between a sensor (A) and a gateway (B).
\* As module AB, except a receiver may take ANY message in its channel when
\* Reorder is TRUE, as over UDP. With Reorder = FALSE it is exactly AB.
EXTENDS Integers, Sequences
CONSTANTS Data, Reorder
Remove(i, seq) ==
  [j \in 1..(Len(seq) - 1) |-> IF j < i THEN seq[j] ELSE seq[j + 1]]
VARIABLES AVar, BVar, AtoB, BtoA
vars == <<AVar, BVar, AtoB, BtoA>>
TypeOK == /\ AVar \in Data \X {0, 1}
          /\ BVar \in Data \X {0, 1}
          /\ AtoB \in Seq(Data \X {0, 1})
          /\ BtoA \in Seq({0, 1})
Init == /\ AVar \in Data \X {1}
        /\ BVar = AVar
        /\ AtoB = <<>>
        /\ BtoA = <<>>
\* The positions a receiver may take a message from.
Pick(ch) == IF Reorder THEN 1..Len(ch) ELSE 1..1

ASnd == /\ AtoB' = Append(AtoB, AVar)
        /\ UNCHANGED <<AVar, BtoA, BVar>>
ARcv == /\ BtoA # <<>>
        /\ \E i \in Pick(BtoA) :
             /\ IF BtoA[i] = AVar[2]
                  THEN \E d \in Data : AVar' = <<d, 1 - AVar[2]>>
                  ELSE AVar' = AVar
             /\ BtoA' = Remove(i, BtoA)
        /\ UNCHANGED <<AtoB, BVar>>
BSnd == /\ BtoA' = Append(BtoA, BVar[2])
        /\ UNCHANGED <<AVar, BVar, AtoB>>
BRcv == /\ AtoB # <<>>
        /\ \E i \in Pick(AtoB) :
             /\ IF AtoB[i][2] # BVar[2]
                  THEN BVar' = AtoB[i]
                  ELSE BVar' = BVar
             /\ AtoB' = Remove(i, AtoB)
        /\ UNCHANGED <<AVar, BtoA>>
LoseMsg == /\ \/ /\ \E i \in 1..Len(AtoB) : AtoB' = Remove(i, AtoB)
                 /\ BtoA' = BtoA
              \/ /\ \E i \in 1..Len(BtoA) : BtoA' = Remove(i, BtoA)
                 /\ AtoB' = AtoB
           /\ UNCHANGED <<AVar, BVar>>
Next == ASnd \/ ARcv \/ BSnd \/ BRcv \/ LoseMsg
Spec == Init /\ [][Next]_vars

ABS == INSTANCE PSl9_LinkSpec
HighSafety == ABS!Spec
Bound == (Len(AtoB) <= 2) /\ (Len(BtoA) <= 2)
=============================================================================
