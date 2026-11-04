---------------------------- MODULE PSl9_JobQueue ---------------------------
\* A background-job queue with one worker. Each job is submitted once.
\* While running, the worker also sends heartbeats to the scheduler.
EXTENDS Integers, Sequences
CONSTANT Job
VARIABLES queue, submitted, done, beat
vars == <<queue, submitted, done, beat>>
Init == /\ queue = <<>>
        /\ submitted = {}
        /\ done = {}
        /\ beat = 0
Submit(j) == /\ j \notin submitted
             /\ submitted' = submitted \cup {j}
             /\ queue' = Append(queue, j)
             /\ UNCHANGED <<done, beat>>
Process == /\ queue # <<>>
           /\ done' = done \cup {Head(queue)}
           /\ queue' = Tail(queue)
           /\ UNCHANGED <<submitted, beat>>
Heartbeat == /\ beat' = 1 - beat
             /\ UNCHANGED <<queue, submitted, done>>
Next == Process \/ Heartbeat \/ \E j \in Job : Submit(j)
Spec == Init /\ [][Next]_vars
FairNext == Spec /\ WF_vars(Next)
FairWorker == Spec /\ WF_vars(Process)

EveryJobProcessed == \A j \in Job : (j \in submitted) ~> (j \in done)
=============================================================================
