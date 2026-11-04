------------------------------ MODULE QuickSort ------------------------------
EXTENDS Integers, FiniteSets
CONSTANTS N, Values
Idx == 0..(N-1)
VARIABLES A, U       \* the array, and the set of intervals still to sort
vars == <<A, U>>

Count(B, v) == Cardinality({i \in Idx : B[i] = v})
IsPerm(B) == \A v \in Values : Count(B, v) = Count(A, v)
Sorted == \A i, j \in Idx : i < j => A[i] =< A[j]

Init == /\ A \in [Idx -> Values]
        /\ U = {<<0, N-1>>}

\* Pick ANY interval in U. The spec does not say which one.
Partition == \E I \in U :
    LET lo == I[1]
        hi == I[2]
    IN  IF lo < hi
        THEN \E p \in lo..(hi-1), B \in [Idx -> Values] :
               /\ \A i \in Idx \ (lo..hi) : B[i] = A[i]
               /\ IsPerm(B)
               /\ \A i \in lo..p, j \in (p+1)..hi : B[i] =< B[j]
               /\ A' = B
               /\ U' = (U \ {I}) \cup {<<lo, p>>, <<p+1, hi>>}
        ELSE /\ U' = U \ {I}
             /\ UNCHANGED A

Done == U = {} /\ UNCHANGED vars
Next == Partition \/ Done
Spec == Init /\ [][Next]_vars /\ WF_vars(Partition)

SortedWhenDone == U = {} => Sorted
Terminates == <>(U = {})
==============================================================================
