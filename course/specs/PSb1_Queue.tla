---------------- MODULE PSb1_Queue ----------------
EXTENDS Naturals, Sequences
CONSTANTS Values, Capacity
VARIABLE q
Init == q = <<>>
Enqueue(v) == /\ Len(q) < Capacity
              /\ q' = Append(q, v)
Dequeue == /\ Len(q) > 0
           /\ q' = Tail(q)
Next == (\E v \in Values : Enqueue(v)) \/ Dequeue
Spec == Init /\ [][Next]_q
===================================================
