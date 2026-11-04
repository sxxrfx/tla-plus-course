---------------- MODULE PSl10_LSMBug ----------------
EXTENDS Naturals, Sequences
CONSTANTS Keys, Vals, NoVal, MaxTables
VARIABLES mem, tables
vars == <<mem, tables>>
Empty == [k \in Keys |-> NoVal]
Init == /\ mem = Empty
        /\ tables = <<>>              \* tables[1] is the oldest
Put(k, v) == /\ mem' = [mem EXCEPT ![k] = v]
             /\ UNCHANGED tables
Flush == /\ mem # Empty
         /\ Len(tables) < MaxTables
         /\ tables' = Append(tables, mem)
         /\ mem' = Empty
Merge(older, newer) ==
    [k \in Keys |-> IF newer[k] # NoVal THEN newer[k] ELSE older[k]]
Compact == /\ Len(tables) >= 2
           /\ tables' = <<Merge(tables[2], tables[1])>> \o Tail(Tail(tables))
           /\ UNCHANGED mem
Next == \/ \E k \in Keys, v \in Vals : Put(k, v)
        \/ Flush
        \/ Compact
Spec == Init /\ [][Next]_vars

RECURSIVE Find(_, _)
Find(k, i) == IF i = 0 THEN NoVal
              ELSE IF tables[i][k] # NoVal THEN tables[i][k]
              ELSE Find(k, i - 1)
Get(k) == IF mem[k] # NoVal THEN mem[k] ELSE Find(k, Len(tables))

KV == INSTANCE PSl10_KV WITH store <- [k \in Keys |-> Get(k)]
THEOREM Spec => KV!Spec
KVSpec == KV!Spec
==================================================
