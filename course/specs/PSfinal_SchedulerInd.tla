---------------- MODULE PSfinal_SchedulerInd ----------------
EXTENDS PSfinal_Scheduler
\* Fairness without Reap: a crashed worker's lease never runs out.
NoReapSpec == /\ Spec
              /\ \A j \in Jobs : WF_vars(\E w \in Workers : Acquire(w, j))
              /\ \A w \in Workers : WF_vars(Write(w)) /\ WF_vars(Commit(w))

TypeOK == /\ lease \in [Jobs -> Workers \cup {"none"}]
          /\ issued \in [Jobs -> 0..MaxTok]
          /\ wpc \in [Workers -> {"idle", "run", "wrote"}]
          /\ wjob \in [Workers -> Jobs]
          /\ wtok \in [Workers -> 0..MaxTok]
          /\ fence \in [Jobs -> 0..MaxTok]
          /\ output \in [Jobs -> 0..MaxTok]
          /\ done \in SUBSET Jobs
          /\ doneTok \in [Jobs -> 0..MaxTok]
          /\ invoices \in [Jobs -> 0..2]
          /\ expiries \in 0..MaxExpiries
          /\ crashes \in 0..MaxCrashes
\* A first guess: the two safety properties themselves.
Guess == TypeOK /\ OneInvoice /\ OutputOfCommitter
\* The candidate inductive invariant (for Design = "Fenced").
Inv == /\ TypeOK
       /\ \A j \in Jobs : output[j] = fence[j]
       /\ \A j \in done : doneTok[j] = fence[j]
       /\ \A j \in Jobs : invoices[j] = IF j \in done THEN 1 ELSE 0
=============================================================
