---------------- MODULE PSb3_Lease ----------------
EXTENDS Naturals, Sequences
CONSTANTS Clients, LeaseLen, MaxTime, Fenced, CheckAndSend
ASSUME Fenced \in BOOLEAN /\ CheckAndSend \in BOOLEAN /\ LeaseLen >= 1
VARIABLES now,      \* the lock service's clock
          holder,   \* the client the service granted the lease to
          expires,  \* the time at which that lease ends
          issued,   \* the highest fencing token issued so far
          token,    \* token[c]: the token client c received
          pc,       \* pc[c]: "idle", "checked" or "sent"
          net,      \* tokens of writes still on the network
          fence,    \* the highest token storage has accepted
          log       \* tokens of the writes storage accepted, in order
vars == <<now, holder, expires, issued, token, pc, net, fence, log>>
Tokens == 1..(MaxTime + 1)  \* at most one grant per tick, plus one at time 0

Init == /\ now = 0
        /\ holder = "none"
        /\ expires = 0
        /\ issued = 0
        /\ token = [c \in Clients |-> 0]
        /\ pc = [c \in Clients |-> "idle"]
        /\ net = {}
        /\ fence = 0
        /\ log = <<>>

Tick == /\ now < MaxTime
        /\ now' = now + 1
        /\ UNCHANGED <<holder, expires, issued, token, pc, net, fence, log>>

\* The service grants a lease when there is none or it has expired.
\* (Renewal is left out: a client never takes over its own lease.)
Acquire(c) == /\ holder = "none" \/ now >= expires
              /\ holder # c
              /\ pc[c] # "checked"
              /\ holder' = c
              /\ expires' = now + LeaseLen
              /\ issued' = issued + 1
              /\ token' = [token EXCEPT ![c] = issued + 1]
              /\ pc' = [pc EXCEPT ![c] = "idle"]
              /\ UNCHANGED <<now, net, fence, log>>

\* The client checks that its lease is still valid ...
Check(c) == /\ ~CheckAndSend
            /\ pc[c] = "idle" /\ holder = c /\ now < expires
            /\ pc' = [pc EXCEPT ![c] = "checked"]
            /\ UNCHANGED <<now, holder, expires, issued, token, net, fence, log>>
\* ... and later (after a pause of any length) sends its write.
Send(c) == /\ pc[c] = "checked"
           /\ net' = net \cup {token[c]}
           /\ pc' = [pc EXCEPT ![c] = "sent"]
           /\ UNCHANGED <<now, holder, expires, issued, token, fence, log>>
\* The variant with no gap between the check and the send.
CheckSend(c) == /\ CheckAndSend
                /\ pc[c] = "idle" /\ holder = c /\ now < expires
                /\ net' = net \cup {token[c]}
                /\ pc' = [pc EXCEPT ![c] = "sent"]
                /\ UNCHANGED <<now, holder, expires, issued, token, fence, log>>

\* Storage receives a write. With fencing it refuses old tokens.
Deliver(t) == /\ t \in net
              /\ net' = net \ {t}
              /\ IF Fenced /\ t < fence
                    THEN UNCHANGED <<fence, log>>
                    ELSE /\ log' = Append(log, t)
                         /\ fence' = IF t > fence THEN t ELSE fence
              /\ UNCHANGED <<now, holder, expires, issued, token, pc>>

Next == \/ Tick
        \/ \E c \in Clients : Acquire(c) \/ Check(c) \/ Send(c) \/ CheckSend(c)
        \/ \E t \in Tokens : Deliver(t)
Spec == Init /\ [][Next]_vars

\* Storage never applies an older lease's write after a newer one.
WritesInLeaseOrder ==
    \A i, j \in 1..Len(log) : i < j => log[i] <= log[j]
====================================================
