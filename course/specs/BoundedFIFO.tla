---------------- MODULE BoundedFIFO ----------------
EXTENDS Naturals, Sequences
CONSTANTS Values, Capacity
ASSUME Capacity \in Nat /\ Capacity > 0
VARIABLE q
vars == <<q>>
Init == q = <<>>
Enqueue(v) == /\ Len(q) < Capacity
              /\ q' = Append(q,v)
Dequeue == /\ Len(q) > 0
           /\ q' = Tail(q)
Next == (\E v \in Values: Enqueue(v)) \/ Dequeue
Spec == Init /\ [][Next]_vars
TypeOK == /\ q \in Seq(Values)
          /\ Len(q) <= Capacity
===================================================
