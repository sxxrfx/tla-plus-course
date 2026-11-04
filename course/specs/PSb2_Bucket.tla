---------------- MODULE PSb2_Bucket ----------------
EXTENDS Naturals
CONSTANTS Cap, MaxRefills
VARIABLES tokens, refills
bvars == <<tokens, refills>>
Init == tokens = Cap /\ refills = 0
Take == /\ tokens > 0
        /\ tokens' = tokens - 1
        /\ UNCHANGED refills
Refill == /\ tokens < Cap
          /\ refills < MaxRefills       \* bounds the model
          /\ tokens' = tokens + 1
          /\ refills' = refills + 1
Empty == tokens = 0
Next == Take \/ Refill
Spec == Init /\ [][Next]_bvars
====================================================
