---------------- MODULE PSfinal_Scheduler ----------------
EXTENDS Naturals
CONSTANTS Workers, Jobs, Design, MaxExpiries, MaxCrashes
ASSUME Design \in {"LeaseOnly", "DedupOnly", "Fenced"}
VARIABLES lease,     \* lease[j]: the worker holding j's lease, or "none"
          issued,    \* issued[j]: the last fencing token issued for j
          wpc,       \* wpc[w]: "idle", "run" or "wrote" (volatile)
          wjob,      \* wjob[w]: the job w is running
          wtok,      \* wtok[w]: the token w received with its lease
          output,    \* storage: output[j] = token of the run that wrote it
          fence,     \* storage: fence[j] = highest token accepted for j
          done,      \* storage: jobs committed as finished
          doneTok,   \* storage: doneTok[j] = token of the committing run
          invoices,  \* outbox rows: invoices[j] = invoices queued for j
          expiries,  \* lease expiries so far (the holder is still alive)
          crashes    \* worker crashes so far
vars == <<lease, issued, wpc, wjob, wtok, output, fence, done, doneTok,
          invoices, expiries, crashes>>

MaxTok == 1 + MaxExpiries + MaxCrashes  \* enough for every run allowed

Init == /\ lease = [j \in Jobs |-> "none"]
        /\ issued = [j \in Jobs |-> 0]
        /\ wpc = [w \in Workers |-> "idle"]
        /\ wjob = [w \in Workers |-> CHOOSE j \in Jobs : TRUE]
        /\ wtok = [w \in Workers |-> 0]
        /\ output = [j \in Jobs |-> 0]
        /\ fence = [j \in Jobs |-> 0]
        /\ done = {}
        /\ doneTok = [j \in Jobs |-> 0]
        /\ invoices = [j \in Jobs |-> 0]
        /\ expiries = 0
        /\ crashes = 0

Storage == <<output, fence, done, doneTok, invoices>>

\* The scheduler leases an unfinished job to an idle worker, with a token.
Acquire(w, j) == /\ wpc[w] = "idle" /\ lease[j] = "none" /\ j \notin done
                 /\ issued[j] < MaxTok
                 /\ lease' = [lease EXCEPT ![j] = w]
                 /\ issued' = [issued EXCEPT ![j] = @ + 1]
                 /\ wpc' = [wpc EXCEPT ![w] = "run"]
                 /\ wjob' = [wjob EXCEPT ![w] = j]
                 /\ wtok' = [wtok EXCEPT ![w] = issued[j] + 1]
                 /\ UNCHANGED <<Storage, expiries, crashes>>

\* The worker stops; it gives the lease back if it still holds it.
Stop(w) == /\ wpc' = [wpc EXCEPT ![w] = "idle"]
           /\ lease' = IF lease[wjob[w]] = w
                          THEN [lease EXCEPT ![wjob[w]] = "none"] ELSE lease

\* The worker writes the job's output to storage.
Write(w) == LET j == wjob[w] IN
    /\ wpc[w] = "run"
    /\ IF Design = "Fenced" /\ (j \in done \/ wtok[w] < fence[j])
          THEN /\ Stop(w)                      \* storage refused
               /\ UNCHANGED <<output, fence>>
          ELSE /\ output' = [output EXCEPT ![j] = wtok[w]]
               /\ fence' = [fence EXCEPT ![j] = IF wtok[w] > @ THEN wtok[w] ELSE @]
               /\ wpc' = [wpc EXCEPT ![w] = "wrote"]
               /\ UNCHANGED lease
    /\ UNCHANGED <<issued, wjob, wtok, done, doneTok, invoices, expiries, crashes>>

\* One storage transaction marks the job done and queues the invoice.
Commit(w) == LET j == wjob[w] IN
    /\ wpc[w] = "wrote"
    /\ Stop(w)
    /\ IF \/ Design # "LeaseOnly" /\ j \in done
          \/ Design = "Fenced" /\ wtok[w] # fence[j]
          THEN UNCHANGED <<done, doneTok, invoices>>   \* refused
          ELSE /\ done' = done \cup {j}
               /\ doneTok' = [doneTok EXCEPT ![j] = wtok[w]]
               /\ invoices' = [invoices EXCEPT ![j] = @ + 1]
    /\ UNCHANGED <<issued, wjob, wtok, output, fence, expiries, crashes>>

\* The lease runs out while its holder is alive but paused.
Expire(j) == /\ lease[j] # "none" /\ expiries < MaxExpiries
             /\ lease' = [lease EXCEPT ![j] = "none"]
             /\ expiries' = expiries + 1
             /\ UNCHANGED <<issued, wpc, wjob, wtok, Storage, crashes>>

\* A worker crashes; its lease stays until Reap.
Crash(w) == /\ wpc[w] # "idle" /\ crashes < MaxCrashes
            /\ wpc' = [wpc EXCEPT ![w] = "idle"]
            /\ crashes' = crashes + 1
            /\ UNCHANGED <<lease, issued, wjob, wtok, Storage, expiries>>

\* The lease of a worker that is no longer running the job runs out.
Reap(j) == /\ lease[j] # "none"
           /\ LET w == lease[j] IN wpc[w] = "idle" \/ wjob[w] # j
           /\ lease' = [lease EXCEPT ![j] = "none"]
           /\ UNCHANGED <<issued, wpc, wjob, wtok, Storage, expiries, crashes>>

Next == \/ \E w \in Workers, j \in Jobs : Acquire(w, j)
        \/ \E w \in Workers : Write(w) \/ Commit(w) \/ Crash(w)
        \/ \E j \in Jobs : Expire(j) \/ Reap(j)
Spec == Init /\ [][Next]_vars
FairSpec == /\ Spec
            /\ \A j \in Jobs : WF_vars(\E w \in Workers : Acquire(w, j))
                               /\ WF_vars(Reap(j))
            /\ \A w \in Workers : WF_vars(Write(w)) /\ WF_vars(Commit(w))

OneInvoice == \A j \in Jobs : invoices[j] <= 1
OutputOfCommitter == \A j \in done : output[j] = doneTok[j]
Contract == INSTANCE PSfinal_Jobs WITH invoiced <- invoices
Refines == Contract!Spec
===========================================================
