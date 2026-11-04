---------------- MODULE FIFOOrderBad ----------------
EXTENDS Naturals, Sequences
CONSTANTS Values, Capacity, MaxSends
VARIABLES q, sent, received
vars == <<q, sent, received>>
Init == q = <<>> /\ sent = <<>> /\ received = <<>>
Enqueue(v) == /\ Len(q) < Capacity
              /\ Len(sent) < MaxSends
              /\ q' = Append(q,v)
              /\ sent' = Append(sent,v)
              /\ UNCHANGED received
Dequeue == /\ Len(q) > 0
           /\ received' = Append(received, q[Len(q)])
           /\ q' = SubSeq(q, 1, Len(q)-1)
           /\ UNCHANGED sent
Next == (\E v \in Values: Enqueue(v)) \/ Dequeue
Spec == Init /\ [][Next]_vars
TypeOK == /\ q \in Seq(Values)
          /\ Len(q) <= Capacity
InOrder == received \o q = sent
===================================================
