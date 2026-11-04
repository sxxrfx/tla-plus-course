---------------- MODULE PSb4_UndoToast ----------------
EXTENDS Naturals
CONSTANTS Design, CanFail
ASSUME /\ Design \in {"Deferred", "UndoWhileSending", "Immediate", "ImmediateSeq"}
       /\ CanFail \in BOOLEAN
Immediate == Design \in {"Immediate", "ImmediateSeq"}
VARIABLES server,   \* does the email exist on the server?
          shown,    \* is it shown in the inbox list?
          toast,    \* "none", "undo" or "error"
          sent,     \* Deferred designs: has the timer sent the DELETE?
          seq,      \* number of the client's latest request
          net,      \* requests in flight: [seq, op]
          resp,     \* responses in flight: [seq, op, ok]
          applied,  \* ImmediateSeq: highest request seq the server applied
          clicks    \* user actions so far (bounds the model)
vars == <<server, shown, toast, sent, seq, net, resp, applied, clicks>>

Init == /\ server = TRUE /\ shown = TRUE /\ toast = "none"
        /\ sent = FALSE /\ seq = 0 /\ net = {} /\ resp = {}
        /\ applied = 0 /\ clicks = 0

Send(op) == /\ seq' = seq + 1
            /\ net' = net \cup {[seq |-> seq + 1, op |-> op]}

\* The user deletes the email: it disappears at once, with an Undo toast.
Delete == /\ clicks = 0 /\ shown /\ toast = "none"
          /\ shown' = FALSE /\ toast' = "undo" /\ clicks' = 1
          /\ IF Immediate THEN Send("delete") ELSE UNCHANGED <<seq, net>>
          /\ UNCHANGED <<server, sent, resp, applied>>

\* The user clicks Undo.
Undo == /\ clicks = 1 /\ toast = "undo"
        /\ shown' = TRUE /\ toast' = "none" /\ clicks' = 2
        /\ IF Immediate THEN Send("restore") ELSE UNCHANGED <<seq, net>>
        /\ UNCHANGED <<server, sent, resp, applied>>

\* The toast's timer fires. Deferred designs send the DELETE now;
\* UndoWhileSending keeps showing Undo until the response arrives.
Timeout == /\ toast = "undo" /\ ~sent
           /\ IF Immediate
                 THEN /\ toast' = "none"
                      /\ UNCHANGED <<sent, seq, net>>
                 ELSE /\ sent' = TRUE /\ Send("delete")
                      /\ toast' = IF Design = "UndoWhileSending" THEN "undo"
                                  ELSE "none"
           /\ UNCHANGED <<server, shown, resp, applied, clicks>>

\* The server handles a request: it succeeds or fails without effect.
\* ImmediateSeq skips (but acknowledges) a request older than one applied.
Serve(m) == /\ m \in net
            /\ net' = net \ {m}
            /\ \/ /\ IF Design = "ImmediateSeq" /\ m.seq < applied
                        THEN UNCHANGED <<server, applied>>
                        ELSE /\ server' = (m.op = "restore")
                             /\ applied' = m.seq
                  /\ resp' = resp \cup {[seq |-> m.seq, op |-> m.op, ok |-> TRUE]}
               \/ /\ CanFail
                  /\ UNCHANGED <<server, applied>>
                  /\ resp' = resp \cup {[seq |-> m.seq, op |-> m.op, ok |-> FALSE]}
            /\ UNCHANGED <<shown, toast, sent, seq, clicks>>

\* The client handles a response. A failure of its latest request rolls
\* back the optimistic change and shows an error toast; others are ignored.
Receive(m) == /\ m \in resp
              /\ resp' = resp \ {m}
              /\ IF ~m.ok /\ m.seq = seq
                    THEN /\ shown' = (m.op = "delete")
                         /\ toast' = "error"
                    ELSE /\ UNCHANGED shown
                         /\ toast' = IF toast = "undo" /\ sent THEN "none" ELSE toast
              /\ UNCHANGED <<server, sent, seq, net, applied, clicks>>

Dismiss == /\ toast = "error" /\ toast' = "none"
           /\ UNCHANGED <<server, shown, sent, seq, net, resp, applied, clicks>>

Msgs == [seq : 1..2, op : {"delete", "restore"}]
Next == \/ Delete \/ Undo \/ Timeout \/ Dismiss
        \/ \E m \in Msgs : Serve(m)
        \/ \E m \in [seq : 1..2, op : {"delete", "restore"}, ok : BOOLEAN] : Receive(m)
Spec == Init /\ [][Next]_vars
FairSpec == /\ Spec
            /\ WF_vars(Timeout) /\ WF_vars(Dismiss)
            /\ \A m \in Msgs : WF_vars(Serve(m))
            /\ \A m \in [seq : 1..2, op : {"delete", "restore"}, ok : BOOLEAN] :
                   WF_vars(Receive(m))

Quiet == net = {} /\ resp = {} /\ toast # "undo"
AgreeWhenQuiet == Quiet => shown = server
Converges == <>[](shown = server)
=======================================================
