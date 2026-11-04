---------------- MODULE PSfinal_GCounter ----------------
EXTENDS Naturals
CONSTANTS Replicas, MaxLikes
VARIABLE c   \* c[r][s]: what replica r knows of the likes taken at s
vars == c

RECURSIVE SumOver(_, _)
SumOver(f, S) == IF S = {} THEN 0
                 ELSE LET x == CHOOSE x \in S : TRUE
                      IN  f[x] + SumOver(f, S \ {x})
Value(r) == SumOver(c[r], Replicas)        \* what replica r displays
Total == SumOver([s \in Replicas |-> c[s][s]], Replicas)

Init == c = [r \in Replicas |-> [s \in Replicas |-> 0]]

\* A like arrives at replica r; it counts it in its own entry.
Like(r) == /\ Total < MaxLikes
           /\ c' = [c EXCEPT ![r][r] = @ + 1]

\* Replica r receives s's state and takes the entrywise maximum.
Merge(r, s) == c' = [c EXCEPT ![r] = [x \in Replicas |->
                         IF c[s][x] > c[r][x] THEN c[s][x] ELSE c[r][x]]]

Next == \E r, s \in Replicas : Like(r) \/ Merge(r, s)
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ \A r, s \in Replicas : WF_vars(Merge(r, s))

NeverOverCount == \A r \in Replicas : Value(r) <= Total
OwnEntryLargest == \A r, s \in Replicas : c[s][r] <= c[r][r]
Converges == <>[](\A r \in Replicas : Value(r) = Total)

Contract == INSTANCE PSfinal_Counter WITH count <- Total
Refines == Contract!Spec
==========================================================
