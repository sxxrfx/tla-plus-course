---------------- MODULE Once ----------------
EXTENDS Naturals
CONSTANT Requests
VARIABLES seen, effects
vars == <<seen,effects>>
Init == /\ seen = {}
        /\ effects = [r \in Requests |-> 0]
Apply(r) ==
    /\ r \notin seen
    /\ seen' = seen \cup {r}
    /\ effects' = [effects EXCEPT ![r] = @ + 1]
Next == \E r \in Requests: Apply(r)
Spec == Init /\ [][Next]_vars
TypeOK == /\ seen \subseteq Requests
          /\ effects \in [Requests -> 0..1]
Consistent == \A r \in Requests:
    (r \in seen) <=> (effects[r] = 1)
=============================================
