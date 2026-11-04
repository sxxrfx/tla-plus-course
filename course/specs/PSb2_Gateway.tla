---------------- MODULE PSb2_Gateway ----------------
EXTENDS Naturals
VARIABLES reqs, served, throttled, tokens, refills
vars == <<reqs, served, throttled, tokens, refills>>
C == INSTANCE PSb2_Client WITH MaxReqs <- 4, issued <- reqs,
                               ok <- served, limited <- throttled
B == INSTANCE PSb2_Bucket WITH Cap <- 2, MaxRefills <- 1
Init == C!Init /\ B!Init
\* Shared step: the gateway forwards the request and spends a token.
Admit    == C!GotOk /\ B!Take
\* Gateway answers 429 only when the bucket is empty.
Throttle == C!Got429 /\ B!Empty /\ UNCHANGED <<tokens, refills>>
Next == \/ C!Send /\ UNCHANGED <<tokens, refills>>
        \/ Admit
        \/ Throttle
        \/ B!Refill /\ UNCHANGED <<reqs, served, throttled>>
Spec == Init /\ [][Next]_vars
\* Every admitted request spent a token.
TokensAccounted == served + tokens = 2 + refills
\* A 429 is sent only when the bucket is empty.
HonestThrottle == [][throttled' > throttled => tokens = 0]_vars
ClientContract == C!Spec
BucketContract == B!Spec
\* The naive composition: conjoin the components, each stepping its own variables.
NaiveNext == [C!Next]_<<reqs, served, throttled>> /\ [B!Next]_<<tokens, refills>>
Naive == Init /\ [][NaiveNext]_vars
=====================================================
