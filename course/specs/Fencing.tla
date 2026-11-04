---------------- MODULE Fencing ----------------
EXTENDS Naturals
CONSTANTS MaxToken, Fenced
ASSUME Fenced \in BOOLEAN
VARIABLES issued,        \* highest token the authority has granted
          fence,         \* token of the last write the resource accepted
          staleAccepted  \* history: did it accept a superseded token?
vars == <<issued, fence, staleAccepted>>

Init == /\ issued = 0
        /\ fence = 0
        /\ staleAccepted = FALSE

Grant == /\ issued < MaxToken
         /\ issued' = issued + 1
         /\ UNCHANGED <<fence, staleAccepted>>

\* Any token ever granted can still try to write: its holder may have
\* paused, or its message may have been delayed.
AcceptWrite(t) ==
    /\ t \in 1..issued
    /\ Fenced => t >= fence
    /\ fence' = t
    /\ staleAccepted' = (staleAccepted \/ t < issued)
    /\ UNCHANGED issued

Next == Grant \/ \E t \in 1..MaxToken: AcceptWrite(t)
Spec == Init /\ [][Next]_vars

TypeOK == /\ issued \in 0..MaxToken
          /\ fence \in 0..MaxToken
          /\ staleAccepted \in BOOLEAN
FenceNeverRegresses == [][fence' >= fence]_fence
RevokedAtGrant == ~staleAccepted
================================================
