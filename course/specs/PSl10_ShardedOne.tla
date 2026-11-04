---------------- MODULE PSl10_ShardedOne ----------------
EXTENDS Naturals
CONSTANTS Shards, MaxPerShard, Home
VARIABLE shard
Init == shard = [s \in Shards |-> 0]
Inc(s) == /\ shard[s] < MaxPerShard
          /\ shard' = [shard EXCEPT ![s] = shard[s] + 1]
Next == \E s \in Shards : Inc(s)
Spec == Init /\ [][Next]_shard

RECURSIVE SumOver(_, _)
SumOver(f, S) == IF S = {} THEN 0
                 ELSE LET s == CHOOSE x \in S : TRUE
                      IN  f[s] + SumOver(f, S \ {s})
Total == SumOver(shard, Shards)

C == INSTANCE PSl10_Counter WITH count <- shard[Home]
THEOREM Spec => C!Spec
CounterSpec == C!Spec
======================================================
