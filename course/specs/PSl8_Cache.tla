----------------------------- MODULE PSl8_Cache -----------------------------
\* The same store with a cache in front of it. cache[k] is "miss" or a copy.
CONSTANTS Key, Val
VARIABLES store, out, cache
vars == <<store, out, cache>>
Init == /\ store \in [Key -> Val]
        /\ out = "none"
        /\ cache = [k \in Key |-> "miss"]
\* Write-through: the database and the cache change in one step.
Put(k, v) == /\ store' = [store EXCEPT ![k] = v]
             /\ cache' = [cache EXCEPT ![k] = v]
             /\ out' = out
\* The bug: write to the database and forget the cached copy.
PutNoInvalidate(k, v) == /\ store' = [store EXCEPT ![k] = v]
                         /\ UNCHANGED <<cache, out>>
Fill(k)  == /\ cache[k] = "miss"
            /\ cache' = [cache EXCEPT ![k] = store[k]]
            /\ UNCHANGED <<store, out>>
Evict(k) == /\ cache[k] # "miss"
            /\ cache' = [cache EXCEPT ![k] = "miss"]
            /\ UNCHANGED <<store, out>>
Get(k) == /\ out' = IF cache[k] = "miss" THEN store[k] ELSE cache[k]
          /\ UNCHANGED <<store, cache>>
Next == \E k \in Key : \/ Get(k) \/ Fill(k) \/ Evict(k)
                       \/ \E v \in Val : Put(k, v)
BugNext == \E k \in Key : \/ Get(k) \/ Fill(k) \/ Evict(k)
                          \/ \E v \in Val : PutNoInvalidate(k, v)
Spec == Init /\ [][Next]_vars
BugSpec == Init /\ [][BugNext]_vars

KV == INSTANCE PSl8_KV
KVSpec == KV!KVSpec
THEOREM Spec => KVSpec
=============================================================================
