---------------------------- MODULE PSl8_CacheWB ----------------------------
\* Not shown: a write-back cache. Put writes only the cache; Flush copies a
\* cached value to the database later.
EXTENDS PSl8_Cache
PutBack(k, v) == /\ cache' = [cache EXCEPT ![k] = v]
                 /\ UNCHANGED <<store, out>>
Flush(k) == /\ cache[k] # "miss"
            /\ store' = [store EXCEPT ![k] = cache[k]]
            /\ UNCHANGED <<cache, out>>
WBEvict(k) == Evict(k) /\ store[k] = cache[k]
WBNext == \E k \in Key : \/ Get(k) \/ Fill(k) \/ WBEvict(k) \/ Flush(k)
                         \/ \E v \in Val : PutBack(k, v)
WBSpec == Init /\ [][WBNext]_vars
=============================================================================
