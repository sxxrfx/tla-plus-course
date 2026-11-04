---------------- MODULE PSl10_ShardedRestart ----------------
EXTENDS Naturals
CONSTANTS Shards, MaxPerShard
VARIABLE shard
Init == shard = [s \in Shards |-> 0]
Inc(s) == /\ shard[s] < MaxPerShard
          /\ shard' = [shard EXCEPT ![s] = shard[s] + 1]
Restart(s) == /\ shard[s] > 0
              /\ shard' = [shard EXCEPT ![s] = 0]
Next == \E s \in Shards : Inc(s) \/ Restart(s)
Spec == Init /\ [][Next]_shard

RECURSIVE SumOver(_, _)
SumOver(f, S) == IF S = {} THEN 0
                 ELSE LET s == CHOOSE x \in S : TRUE
                      IN  f[s] + SumOver(f, S \ {s})
Total == SumOver(shard, Shards)

C == INSTANCE PSl10_Counter WITH count <- Total
THEOREM Spec => C!Spec
CounterSpec == C!Spec
======================================================
