---------------- MODULE PSl10_RLogOneLeader ----------------
EXTENDS Naturals, Sequences, FiniteSets
CONSTANTS Vals, Followers, MaxLen
VARIABLES llog, flog, commit
vars == <<llog, flog, commit>>
Init == /\ llog = <<>>                       \* the leader's log
        /\ flog = [f \in Followers |-> <<>>]   \* each follower's log
        /\ commit = 0                         \* the leader's commit index
Request(v) == /\ Len(llog) < MaxLen
              /\ llog' = Append(llog, v)
              /\ UNCHANGED <<flog, commit>>
Replicate(f) == /\ Len(flog[f]) < Len(llog)
                /\ flog' = [flog EXCEPT ![f] =
                              Append(flog[f], llog[Len(flog[f]) + 1])]
                /\ UNCHANGED <<llog, commit>>
\* Entry n is on a majority: the leader plus at least half the followers.
OnMajority(n) == 2 * (1 + Cardinality({f \in Followers : Len(flog[f]) >= n}))
                   > 1 + Cardinality(Followers)
AdvanceCommit == /\ commit < Len(llog)
                 /\ OnMajority(commit + 1)
                 /\ commit' = commit + 1
                 /\ UNCHANGED <<llog, flog>>
Prefix(s, n) == [i \in 1..n |-> s[i]]
\* A new leader holding only the committed prefix takes over;
\* uncommitted entries are discarded everywhere.
Failover == /\ Len(llog) > commit
            /\ llog' = Prefix(llog, commit)
            /\ flog' = [f \in Followers |->
                          IF Len(flog[f]) > commit THEN Prefix(flog[f], commit)
                          ELSE flog[f]]
            /\ UNCHANGED commit
Next == \/ \E v \in Vals : Request(v)
        \/ \E f \in Followers : Replicate(f)
        \/ AdvanceCommit
Spec == Init /\ [][Next]_vars

Committed == Prefix(llog, commit)
L == INSTANCE PSl10_Log WITH log <- llog
LogSpec == L!Spec
===================================================
