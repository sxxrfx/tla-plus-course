---------------- MODULE PSfinal_RaftLog ----------------
EXTENDS Naturals, Sequences
CONSTANTS Servers, MaxTerm, MaxLen, PrevCheck, OneLeaderPerTerm
ASSUME PrevCheck \in BOOLEAN /\ OneLeaderPerTerm \in BOOLEAN
Terms == 1..MaxTerm
VARIABLES term,     \* term[s]: the latest term server s knows
          leaders,  \* leaders[t]: servers elected leader in term t
          log       \* log[s]: the term of each entry, in index order
vars == <<term, leaders, log>>

Init == /\ term = [s \in Servers |-> 0]
        /\ leaders = [t \in Terms |-> {}]
        /\ log = [s \in Servers |-> <<>>]

\* Elections are abstracted: s wins term t, a term newer than its own.
Elect(s, t) == /\ t > term[s]
               /\ OneLeaderPerTerm => leaders[t] = {}
               /\ leaders' = [leaders EXCEPT ![t] = @ \cup {s}]
               /\ term' = [term EXCEPT ![s] = t]
               /\ UNCHANGED log

IsLeader(s) == term[s] > 0 /\ s \in leaders[term[s]]

\* A leader appends a client command, tagged with its term, to its own log.
ClientRequest(s) == /\ IsLeader(s)
                    /\ Len(log[s]) < MaxLen
                    /\ log' = [log EXCEPT ![s] = Append(@, term[s])]
                    /\ UNCHANGED <<term, leaders>>

\* Leader l sends f entry i+1, with prevLogIndex i and prevLogTerm log[l][i].
\* f accepts if l's term is not older than f's and (with PrevCheck) f's
\* entry i has that term. f keeps entries 1..i, then takes entry i+1.
AppendEntries(l, f, i) ==
    /\ l # f /\ IsLeader(l)
    /\ term[l] >= term[f]
    /\ i < Len(log[l]) /\ i <= Len(log[f])
    /\ PrevCheck => IF i = 0 THEN TRUE ELSE log[f][i] = log[l][i]
    /\ log' = [log EXCEPT ![f] = [j \in 1..(i + 1) |->
                   IF j <= i THEN log[f][j] ELSE log[l][i + 1]]]
    /\ term' = [term EXCEPT ![f] = term[l]]
    /\ UNCHANGED leaders

Next == \/ \E s \in Servers, t \in Terms : Elect(s, t)
        \/ \E s \in Servers : ClientRequest(s)
        \/ \E l, f \in Servers, i \in 0..(MaxLen - 1) : AppendEntries(l, f, i)
Spec == Init /\ [][Next]_vars

\* Log Matching: same index and term => identical logs up to that index.
LogMatching ==
    \A s, u \in Servers : \A i \in 1..MaxLen :
        (i <= Len(log[s]) /\ i <= Len(log[u]) /\ log[s][i] = log[u][i])
            => \A j \in 1..i : log[s][j] = log[u][j]
=========================================================
