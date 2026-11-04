------------------------------ MODULE PSl5_Rollout ------------------------------
CONSTANT Pod             \* the Deployment's replicas
VARIABLE pod             \* pod[p] is the state of replica p

TypeOK == pod \in [Pod -> {"v1", "stopping", "starting", "v2"}]

Init == pod = [p \in Pod |-> "v1"]

Serving(p) == pod[p] \in {"v1", "v2"}

\* The controller replaces one old pod. The guard is its availability rule.
Stop(p) == /\ pod[p] = "v1"
           /\ \A q \in Pod : pod[q] /= "stopping"
           /\ pod' = [pod EXCEPT ![p] = "stopping"]

\* The old container has exited; the new one is scheduled.
Start(p) == /\ pod[p] = "stopping"
            /\ pod' = [pod EXCEPT ![p] = "starting"]

\* The new container passes its readiness probe.
Ready(p) == /\ pod[p] = "starting"
            /\ pod' = [pod EXCEPT ![p] = "v2"]

Next == \E p \in Pod : Stop(p) \/ Start(p) \/ Ready(p)

AtMostOneDown == \A p, q \in Pod : (~Serving(p) /\ ~Serving(q)) => p = q
NotRolledOut == ~(\A p \in Pod : pod[p] = "v2")
=============================================================================
