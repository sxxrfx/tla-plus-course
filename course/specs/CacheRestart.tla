---------------- MODULE CacheRestart ----------------
EXTENDS Naturals
VARIABLES volatile, durable, pending
vars == <<volatile, durable, pending>>
Init == volatile = 3 /\ durable = 3 /\ pending = {4, 5}
Accept(v) == /\ v \in pending
             /\ v >= volatile
             /\ volatile' = v
             /\ pending' = pending \ {v}
             /\ UNCHANGED durable
Reject(v) == /\ v \in pending
             /\ v < volatile
             /\ pending' = pending \ {v}
             /\ UNCHANGED <<volatile, durable>>
Persist == /\ durable # volatile
           /\ durable' = volatile
           /\ UNCHANGED <<volatile, pending>>
Restart == /\ volatile # durable
           /\ volatile' = durable
           /\ UNCHANGED <<durable, pending>>
Next == Persist \/ Restart \/ \E v \in pending: Accept(v) \/ Reject(v)
Spec == Init /\ [][Next]_vars
Monotonic == [][volatile' >= volatile]_vars
=====================================================
