----------------------------- MODULE PSl5_FailoverFixed -----------------------------
EXTENDS Integers

Replicas == {"db1", "db2", "db3"}

\* Replay lag in seconds, as last reported.
lag == [r \in Replicas |-> IF r = "db1" THEN 0
                           ELSE IF r = "db2" THEN 4
                           ELSE 90]

VARIABLE status

Init == status = [r \in Replicas |-> IF r = "db3" THEN "catchup"
                                     ELSE "streaming"]

\* db1 crashes. Its last reported lag stays in the table.
Next == status' = [status EXCEPT !["db1"] = "down"]

Candidate(r) == /\ status[r] = "streaming"
                /\ \A s \in Replicas : status[s] = "streaming" => lag[r] =< lag[s]

SomeCandidate == \E r \in Replicas : Candidate(r)
=============================================================================
