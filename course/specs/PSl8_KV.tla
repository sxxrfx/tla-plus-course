------------------------------ MODULE PSl8_KV -------------------------------
\* What clients of the key-value store may observe. out is the value the
\* most recent Get returned ("none" before the first Get).
CONSTANTS Key, Val
VARIABLES store, out
KVInit == /\ store \in [Key -> Val]
          /\ out = "none"
Put(k, v) == /\ store' = [store EXCEPT ![k] = v]
             /\ out' = out
Get(k) == /\ out' = store[k]
          /\ store' = store
KVNext == \E k \in Key : Get(k) \/ \E v \in Val : Put(k, v)
KVSpec == KVInit /\ [][KVNext]_<<store, out>>
=============================================================================
