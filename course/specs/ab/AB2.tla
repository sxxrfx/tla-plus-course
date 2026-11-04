--------------------------------- MODULE AB2 --------------------------------
EXTENDS Integers, Sequences

CONSTANTS Data, Bad

ASSUME Bad \notin (Data \X {0, 1}) \cup {0, 1}

VARIABLES AVar, BVar, AtoB2, BtoA2

vars == <<AVar, BVar, AtoB2, BtoA2>>

TypeOK == /\ AVar \in Data \X {0, 1}
          /\ BVar \in Data \X {0, 1}
          /\ AtoB2 \in Seq((Data \X {0, 1}) \cup {Bad})
          /\ BtoA2 \in Seq({0, 1, Bad})

Init == /\ AVar \in Data \X {1}
        /\ BVar = AVar
        /\ AtoB2 = <<>>
        /\ BtoA2 = <<>>

ASnd == /\ AtoB2' = Append(AtoB2, AVar)
        /\ UNCHANGED <<AVar, BtoA2, BVar>>

ARcv == /\ BtoA2 # <<>>
        /\ IF Head(BtoA2) = AVar[2]
             THEN \E d \in Data : AVar' = <<d, 1 - AVar[2]>>
             ELSE AVar' = AVar
        /\ BtoA2' = Tail(BtoA2)
        /\ UNCHANGED <<AtoB2, BVar>>

BSnd == /\ BtoA2' = Append(BtoA2, BVar[2])
        /\ UNCHANGED <<AVar, BVar, AtoB2>>

BRcv == /\ AtoB2 # <<>>
        /\ IF (Head(AtoB2) # Bad) /\ (Head(AtoB2)[2] # BVar[2])
             THEN BVar' = Head(AtoB2)
             ELSE BVar' = BVar
        /\ AtoB2' = Tail(AtoB2)
        /\ UNCHANGED <<AVar, BtoA2>>

CorruptMsg == /\ \/ /\ \E i \in 1..Len(AtoB2) :
                         AtoB2' = [AtoB2 EXCEPT ![i] = Bad]
                    /\ BtoA2' = BtoA2
                 \/ /\ \E i \in 1..Len(BtoA2) :
                         BtoA2' = [BtoA2 EXCEPT ![i] = Bad]
                    /\ AtoB2' = AtoB2
              /\ UNCHANGED <<AVar, BVar>>

Next == ASnd \/ ARcv \/ BSnd \/ BRcv \/ CorruptMsg

Spec == Init /\ [][Next]_vars

ABS == INSTANCE ABSpec

THEOREM Spec => ABS!Spec

FairSpec == Spec /\ SF_vars(ARcv) /\ SF_vars(BRcv)
                 /\ WF_vars(ASnd) /\ WF_vars(BSnd)

RECURSIVE RemoveBad(_)
RemoveBad(seq) == IF seq = <<>>
                    THEN <<>>
                    ELSE IF Head(seq) = Bad
                           THEN RemoveBad(Tail(seq))
                           ELSE <<Head(seq)>> \o RemoveBad(Tail(seq))

AB == INSTANCE AB WITH AtoB <- RemoveBad(AtoB2),
                       BtoA <- RemoveBad(BtoA2)

THEOREM Spec => AB!Spec
=============================================================================
