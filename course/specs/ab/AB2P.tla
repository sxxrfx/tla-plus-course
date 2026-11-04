-------------------------------- MODULE AB2P --------------------------------
\* This course's own version of the lecture's idea; the module you download
\* from the course page may be written differently.
EXTENDS AB2

VARIABLES AtoBgood, BtoAgood

varsP == <<vars, AtoBgood, BtoAgood>>

InitP == /\ Init
         /\ AtoBgood = <<>>
         /\ BtoAgood = <<>>

SndA(g) == /\ ASnd
           /\ AtoBgood' = Append(AtoBgood, g)
           /\ UNCHANGED BtoAgood

SndB(g) == /\ BSnd
           /\ BtoAgood' = Append(BtoAgood, g)
           /\ UNCHANGED AtoBgood

ASndP == \E g \in BOOLEAN : SndA(g)
BSndP == \E g \in BOOLEAN : SndB(g)

ARcvP == /\ ARcv
         /\ BtoAgood' = Tail(BtoAgood)
         /\ UNCHANGED AtoBgood

BRcvP == /\ BRcv
         /\ AtoBgood' = Tail(AtoBgood)
         /\ UNCHANGED BtoAgood

CorruptP == /\ \/ /\ \E i \in 1..Len(AtoB2) :
                       /\ ~ AtoBgood[i]
                       /\ AtoB2' = [AtoB2 EXCEPT ![i] = Bad]
                  /\ BtoA2' = BtoA2
               \/ /\ \E i \in 1..Len(BtoA2) :
                       /\ ~ BtoAgood[i]
                       /\ BtoA2' = [BtoA2 EXCEPT ![i] = Bad]
                  /\ AtoB2' = AtoB2
            /\ UNCHANGED <<AVar, BVar, AtoBgood, BtoAgood>>

NextP == ASndP \/ BSndP \/ ARcvP \/ BRcvP \/ CorruptP

SpecP == InitP /\ [][NextP]_varsP

FairSpecP == SpecP /\ WF_varsP(ARcvP) /\ WF_varsP(BRcvP)
                   /\ WF_varsP(SndA(TRUE)) /\ WF_varsP(SndB(TRUE))

THEOREM SpecP => Spec
THEOREM FairSpecP => ABS!FairSpec
=============================================================================
