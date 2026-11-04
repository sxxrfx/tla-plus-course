---------------- MODULE PSl10_ShardedFold ----------------
EXTENDS Naturals
CONSTANTS Shards, MaxPerShard
VARIABLES shard, base
vars == <<shard, base>>
Init == /\ shard = [s \in Shards |-> 0]
        /\ base = 0
Inc(s) == /\ shard[s] < MaxPerShard
          /\ shard' = [shard EXCEPT ![s] = shard[s] + 1]
          /\ UNCHANGED base
Fold(s) == /\ shard[s] > 0
           /\ base' = base + shard[s]
           /\ shard' = [shard EXCEPT ![s] = 0]
Next == \E s \in Shards : Inc(s) \/ Fold(s)
Spec == Init /\ [][Next]_vars

RECURSIVE SumOver(_, _)
SumOver(f, S) == IF S = {} THEN 0
                 ELSE LET s == CHOOSE x \in S : TRUE
                      IN  f[s] + SumOver(f, S \ {s})
Total == base + SumOver(shard, Shards)
Bound == Total <= 4

C == INSTANCE PSl10_Counter WITH count <- Total
CounterSpec == C!Spec
==========================================================
