---------------- MODULE PSb4_Replica ----------------
EXTENDS Naturals
CONSTANTS Replicas, MaxLsn, Routing
ASSUME Routing \in {"AnyReplica", "WriteLsn", "SessionLsn"}
VARIABLES primary,  \* the primary's current WAL position (LSN)
          replay,   \* replay[r]: the LSN replica r has replayed
          token,    \* the LSN the session carries in its cookie
          wrote,    \* the LSN of the session's last write
          seen,     \* the highest LSN the session has read so far
          last,     \* the LSN the most recent read returned
          need,     \* ... the value of wrote at that read
          before    \* ... the value of seen just before that read
vars == <<primary, replay, token, wrote, seen, last, need, before>>

Max(a, b) == IF a >= b THEN a ELSE b

Init == /\ primary = 0
        /\ replay = [r \in Replicas |-> 0]
        /\ token = 0 /\ wrote = 0 /\ seen = 0
        /\ last = 0 /\ need = 0 /\ before = 0

\* The session commits a write on the primary.
MyWrite == /\ primary < MaxLsn
           /\ primary' = primary + 1
           /\ wrote' = primary + 1
           /\ token' = IF Routing = "AnyReplica" THEN token ELSE primary + 1
           /\ UNCHANGED <<replay, seen, last, need, before>>
\* Another session commits a write.
OtherWrite == /\ primary < MaxLsn
              /\ primary' = primary + 1
              /\ UNCHANGED <<replay, token, wrote, seen, last, need, before>>
\* Asynchronous streaming: replica r replays one more WAL record.
Replay(r) == /\ replay[r] < primary
             /\ replay' = [replay EXCEPT ![r] = @ + 1]
             /\ UNCHANGED <<primary, token, wrote, seen, last, need, before>>
\* The session reads from replica r. Except in AnyReplica, the router
\* uses a replica only if it has replayed up to the session's token.
Read(r) == /\ Routing # "AnyReplica" => replay[r] >= token
           /\ last' = replay[r]
           /\ need' = wrote
           /\ before' = seen
           /\ seen' = Max(seen, replay[r])
           /\ token' = IF Routing = "SessionLsn" THEN Max(token, replay[r])
                       ELSE token
           /\ UNCHANGED <<primary, replay, wrote>>

Next == MyWrite \/ OtherWrite \/ \E r \in Replicas : Replay(r) \/ Read(r)
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ \A r \in Replicas : WF_vars(Replay(r))

ReadYourWrites == last >= need     \* the read saw the session's own write
MonotonicReads == last >= before   \* the read did not go back in time
\* Some replica is (again and again) able to serve the session.
Servable == []<>(\E r \in Replicas : replay[r] >= token)
=====================================================
