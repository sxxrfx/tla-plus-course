------------------------- MODULE PSl7_ElectionTerm --------------------------
\* Not shown: restart forgets term but keeps votedFor.
EXTENDS PSl7_Election
RestartT(s) == /\ term' = [term EXCEPT ![s] = 0]
               /\ UNCHANGED <<votedFor, msgs, leaders>>
NextT == \E s \in Server : \/ \E t \in Term : Timeout(s, t)
                           \/ Grant(s) \/ BecomeLeader(s) \/ RestartT(s)
=============================================================================
