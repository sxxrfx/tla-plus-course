---------------- MODULE PSfinal_Jobs ----------------
EXTENDS Naturals
CONSTANT Jobs
VARIABLE invoiced      \* invoiced[j]: invoices sent for job j
Init == invoiced = [j \in Jobs |-> 0]
\* The contract: each job's invoice goes out once, in one step.
Finish(j) == /\ invoiced[j] = 0
             /\ invoiced' = [invoiced EXCEPT ![j] = 1]
Next == \E j \in Jobs : Finish(j)
Spec == Init /\ [][Next]_invoiced /\ WF_invoiced(Next)
======================================================
