------------------------------ MODULE PSl5_Cron ------------------------------
CONSTANT Node                   \* servers that each run the same crontab
VARIABLES pc,                   \* pc[n][j]: where node n is with job j tonight
          owner                 \* owner[j]: the node in the jobs table, or "none"

Jobs == {"backup", "report"}

TypeOK == /\ pc \in [Node -> [Jobs -> {"idle", "seen", "ran", "skipped"}]]
          /\ \A j \in Jobs : owner[j] = "none" \/ owner[j] \in Node

Init == /\ pc = [n \in Node |-> [j \in Jobs |-> "idle"]]
        /\ owner = [j \in Jobs |-> "none"]

\* pc with node n's entry for job j set to v
Set(n, j, v) == [pc EXCEPT ![n] = [pc[n] EXCEPT ![j] = v]]

\* The report reads the backup, so it may start only after a backup ran.
Ready(j) == j = "report" => \E n \in Node : pc[n]["backup"] = "ran"

\* SELECT owner FROM jobs WHERE name = j  -- and see "none"
Check(n, j) == /\ pc[n][j] = "idle"
               /\ owner[j] = "none"
               /\ Ready(j)
               /\ pc' = Set(n, j, "seen")
               /\ owner' = owner

\* UPDATE jobs SET owner = n WHERE name = j; then run the job
Run(n, j) == /\ pc[n][j] = "seen"
             /\ owner' = [owner EXCEPT ![j] = n]
             /\ pc' = Set(n, j, "ran")

\* Someone else has it.
Skip(n, j) == /\ pc[n][j] = "idle"
              /\ owner[j] # "none"
              /\ pc' = Set(n, j, "skipped")
              /\ owner' = owner

Next == \E n \in Node : \E j \in Jobs : Check(n, j) \/ Run(n, j) \/ Skip(n, j)

AtMostOnce == \A j \in Jobs : \A n, m \in Node :
                (pc[n][j] = "ran" /\ pc[m][j] = "ran") => n = m
=============================================================================
