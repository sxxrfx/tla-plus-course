---------------- MODULE PSfinal_NaiveCounter ----------------
EXTENDS Naturals
CONSTANTS Replicas, MaxLikes, MergeRule
ASSUME MergeRule \in {"Max", "Add"}
VARIABLES n,      \* n[r]: the single number replica r stores
          likes   \* history: likes actually taken, anywhere
vars == <<n, likes>>
Init == n = [r \in Replicas |-> 0] /\ likes = 0
Like(r) == /\ likes < MaxLikes
           /\ n' = [n EXCEPT ![r] = @ + 1]
           /\ likes' = likes + 1
Merge(r, s) == /\ r # s
               /\ n' = [n EXCEPT ![r] = IF MergeRule = "Max"
                          THEN (IF n[s] > n[r] THEN n[s] ELSE n[r])
                          ELSE n[r] + n[s]]
               /\ UNCHANGED likes
Next == \E r, s \in Replicas : Like(r) \/ Merge(r, s)
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ \A r, s \in Replicas : WF_vars(Merge(r, s))
Bounded == \A r \in Replicas : n[r] <= MaxLikes + 1   \* a CONSTRAINT for "Add"
NeverOverCount == \A r \in Replicas : n[r] <= likes
Converges == <>[](\A r \in Replicas : n[r] = likes)
=============================================================
