---------------- MODULE CacheVersion ----------------
EXTENDS Naturals
VARIABLES cacheVersion, pending
vars == <<cacheVersion, pending>>
Init == cacheVersion = 3 /\ pending = {4, 5}
Accept(v) == /\ v \in pending
             /\ v >= cacheVersion
             /\ cacheVersion' = v
             /\ pending' = pending \ {v}
Reject(v) == /\ v \in pending
             /\ v < cacheVersion
             /\ pending' = pending \ {v}
             /\ UNCHANGED cacheVersion
Next == \E v \in pending: Accept(v) \/ Reject(v)
Spec == Init /\ [][Next]_vars
Monotonic == [][cacheVersion' >= cacheVersion]_vars
=====================================================
