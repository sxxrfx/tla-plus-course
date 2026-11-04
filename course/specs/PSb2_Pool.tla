---------------- MODULE PSb2_Pool ----------------
EXTENDS Naturals, FiniteSets, TLC
CONSTANTS Clients, Conns, Free
ASSUME Free \notin Clients
VARIABLES owner, state
vars == <<owner, state>>
Init == /\ owner = [k \in Conns |-> Free]
        /\ state = [c \in Clients |-> "idle"]
Request(c) == /\ state[c] = "idle"
              /\ state' = [state EXCEPT ![c] = "waiting"]
              /\ UNCHANGED owner
Checkout(c, k) == /\ state[c] = "waiting"
                  /\ owner[k] = Free
                  /\ owner' = [owner EXCEPT ![k] = c]
                  /\ state' = [state EXCEPT ![c] = "busy"]
Return(c, k) == /\ owner[k] = c
                /\ owner' = [owner EXCEPT ![k] = Free]
                /\ state' = [state EXCEPT ![c] = "idle"]
Timeout(c) == /\ state[c] = "waiting"     \* gave up waiting for a connection
              /\ state' = [state EXCEPT ![c] = "idle"]
              /\ UNCHANGED owner
Next == \E c \in Clients : \/ Request(c) \/ Timeout(c)
                           \/ \E k \in Conns : Checkout(c, k) \/ Return(c, k)
Spec == Init /\ [][Next]_vars
TypeOK == /\ owner \in [Conns -> Clients \cup {Free}]
          /\ state \in [Clients -> {"idle", "waiting", "busy"}]
\* A client is busy exactly when it holds one connection.
HoldsOne == \A c \in Clients :
              (state[c] = "busy") = (Cardinality({k \in Conns : owner[k] = c}) = 1)
              /\ Cardinality({k \in Conns : owner[k] = c}) <= 1
Sym == Permutations(Clients) \cup Permutations(Conns)
==================================================
