---------------- MODULE PSb3_OutboxFair ----------------
EXTENDS PSb3_Outbox
NoPublishWF == Spec /\ (\A o \in Orders : WF_vars(RelayPublish(o)) /\ WF_vars(Consume(o)))
                    /\ WF_vars(RelayDelete)
NoDeleteWF == Spec /\ (\A o \in Orders : WF_vars(Publish(o)) /\ WF_vars(RelayPublish(o))
                                      /\ WF_vars(Consume(o)))
NoConsumeWF == Spec /\ (\A o \in Orders : WF_vars(Publish(o)) /\ WF_vars(RelayPublish(o)))
                    /\ WF_vars(RelayDelete)
=========================================================
