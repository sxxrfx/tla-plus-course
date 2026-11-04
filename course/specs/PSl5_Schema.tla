---------------------------- MODULE PSl5_Schema ----------------------------
CONSTANT Svc             \* services that produce and consume OrderPlaced events
VARIABLE st              \* st[s] is where service s is in the upgrade

TypeOK == st \in [Svc -> {"v1", "ready", "v2", "pinned"}]

Init == st = [s \in Svc |-> "v1"]

canSwitch == \A s \in Svc : st[s] \in {"ready", "v2"}

noneSwitched == \A s \in Svc : st[s] # "v2"

\* Deploy code that can read both v1 and v2 events; still emit v1.
GetReady(s) == /\ st[s] = "v1"
               /\ st' = [st EXCEPT ![s] = "ready"]

\* Start emitting v2 events.
Switch(s) == /\ st[s] = "ready"
             /\ canSwitch
             /\ st' = [st EXCEPT ![s] = "v2"]

\* Give up on v2 and stay on v1 for good.
Cancel(s) == /\ st[s] \in {"v1", "ready"}
             /\ noneSwitched
             /\ st' = [st EXCEPT ![s] = "pinned"]

Next == \E s \in Svc : GetReady(s) \/ Switch(s) \/ Cancel(s)

Agreement == \A s, t \in Svc : ~ /\ st[s] = "v2"
                                 /\ st[t] = "pinned"

ReadersReady == (\E s \in Svc : st[s] = "v2")
                  => \A t \in Svc : st[t] \in {"ready", "v2"}
=============================================================================
