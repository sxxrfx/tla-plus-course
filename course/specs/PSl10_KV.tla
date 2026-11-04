---------------- MODULE PSl10_KV ----------------
CONSTANTS Keys, Vals, NoVal
VARIABLE store
Init == store = [k \in Keys |-> NoVal]
Put(k, v) == store' = [store EXCEPT ![k] = v]
Next == \E k \in Keys, v \in Vals : Put(k, v)
Spec == Init /\ [][Next]_store
=================================================
