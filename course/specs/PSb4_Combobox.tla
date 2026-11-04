---------------- MODULE PSb4_Combobox ----------------
EXTENDS Naturals
CONSTANT Mode
ASSUME Mode \in {"Plain", "Abort", "RequestId"}
Requests == 1..2
Query == [r \in Requests |-> IF r = 1 THEN "al" ELSE "ali"]
VARIABLES latest,   \* id of the request for the text now in the input
          inflight, \* requests still on the network (abortable)
          queued,   \* responses received; their callbacks have not run
          list      \* the listbox: [tag |-> "closed"], [tag |-> "loading"]
                    \* or [tag |-> "open", query |-> the query it shows]
vars == <<latest, inflight, queued, list>>

Init == /\ latest = 0
        /\ inflight = {}
        /\ queued = {}
        /\ list = [tag |-> "closed"]

\* The user types a character: a new request starts. In Abort mode
\* the component aborts every request still on the network.
Type == /\ latest < 2
        /\ latest' = latest + 1
        /\ inflight' = IF Mode = "Abort" THEN {latest + 1}
                       ELSE inflight \cup {latest + 1}
        /\ list' = [tag |-> "loading"]
        /\ UNCHANGED queued

\* The response body has been read; the callback is queued.
Arrive(r) == /\ r \in inflight
             /\ inflight' = inflight \ {r}
             /\ queued' = queued \cup {r}
             /\ UNCHANGED <<latest, list>>

\* The callback runs and (perhaps) renders the options.
Render(r) == /\ r \in queued
             /\ queued' = queued \ {r}
             /\ list' = IF Mode = "RequestId" /\ r # latest
                           THEN list
                           ELSE [tag |-> "open", query |-> Query[r]]
             /\ UNCHANGED <<latest, inflight>>

Next == Type \/ \E r \in Requests : Arrive(r) \/ Render(r)
Spec == Init /\ [][Next]_vars

\* An open listbox shows options for the text in the input.
MatchesInput == list.tag = "open" => list.query = Query[latest]
======================================================
