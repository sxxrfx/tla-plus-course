---------------- MODULE Session ----------------
CONSTANT Split
ASSUME Split \in BOOLEAN
VARIABLES sessionEpoch, profile, pc,
          acceptedEpoch, epochAtAcceptance
vars == <<sessionEpoch, profile, pc, acceptedEpoch, epochAtAcceptance>>

Req == [epoch |-> 12, value |-> "new"]   \* the delayed upload

Init == /\ sessionEpoch = 12
        /\ profile = "old"
        /\ pc = "sent"
        /\ acceptedEpoch = 0
        /\ epochAtAcceptance = 0

Revoke == /\ sessionEpoch = 12
          /\ sessionEpoch' = 13
          /\ UNCHANGED <<profile, pc, acceptedEpoch, epochAtAcceptance>>

Install == /\ profile' = Req.value
           /\ acceptedEpoch' = Req.epoch
           /\ epochAtAcceptance' = sessionEpoch
           /\ pc' = "done"
           /\ UNCHANGED sessionEpoch

\* One step: compare and write inside the same boundary.
Accept == /\ ~Split /\ pc = "sent"
          /\ IF Req.epoch = sessionEpoch
             THEN Install
             ELSE /\ pc' = "rejected"
                  /\ UNCHANGED <<sessionEpoch, profile,
                                 acceptedEpoch, epochAtAcceptance>>

\* Two steps: the check's result can outlive the authority it saw.
Check == /\ Split /\ pc = "sent"
         /\ pc' = IF Req.epoch = sessionEpoch THEN "checked" ELSE "rejected"
         /\ UNCHANGED <<sessionEpoch, profile,
                        acceptedEpoch, epochAtAcceptance>>
Write == /\ pc = "checked" /\ Install

Next == Revoke \/ Accept \/ Check \/ Write
Spec == Init /\ [][Next]_vars
AcceptedWithCurrentAuthority == acceptedEpoch = epochAtAcceptance
================================================
