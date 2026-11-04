--------------------------- MODULE PSl5_CronClaim ---------------------------
CONSTANT Node                   \* servers that each run the same crontab
VARIABLES pc,                   \* pc[n][j]: where node n is with job j tonight
          owner                 \* owner[j]: the node in the jobs table, or "none"

Jobs == {"backup", "report"}

TypeOK == /\ pc \in [Node -> [Jobs -> {"idle", "ran", "skipped"}]]
          /\ \A j \in Jobs : owner[j] = "none" \/ owner[j] \in Node

Init == /\ pc = [n \in Node |-> [j \in Jobs |-> "idle"]]
        /\ owner = [j \in Jobs |-> "none"]

Set(n, j, v) == [pc EXCEPT ![n] = [pc[n] EXCEPT ![j] = v]]

Ready(j) == j = "report" => \E n \in Node : pc[n]["backup"] = "ran"

\* UPDATE jobs SET owner = n WHERE name = j AND owner IS NULL
\* One statement: the check and the write are one step.
Claim(n, j) == /\ pc[n][j] = "idle"
               /\ owner[j] = "none"
               /\ Ready(j)
               /\ owner' = [owner EXCEPT ![j] = n]
               /\ pc' = Set(n, j, "ran")

Skip(n, j) == /\ pc[n][j] = "idle"
              /\ owner[j] # "none"
              /\ pc' = Set(n, j, "skipped")
              /\ owner' = owner

Next == \E n \in Node : \E j \in Jobs : Claim(n, j) \/ Skip(n, j)

AtMostOnce == \A j \in Jobs : \A n, m \in Node :
                (pc[n][j] = "ran" /\ pc[m][j] = "ran") => n = m

NotAllRan == ~(\A j \in Jobs : \E n \in Node : pc[n][j] = "ran")

AllFinished == \A n \in Node : \A j \in Jobs : pc[n][j] \in {"ran", "skipped"}

\* An intended stop: every node is done for the night. Nothing changes.
Finished == /\ AllFinished
            /\ pc' = pc
            /\ owner' = owner

NextOrDone == Next \/ Finished
=============================================================================
