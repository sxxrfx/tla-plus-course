---------------- MODULE UploadJobsBad ----------------
EXTENDS Naturals, Sequences
CONSTANT Jobs
VARIABLES accepted, waiting, active, done
vars == <<accepted, waiting, active, done>>
Init == accepted = {} /\ waiting = <<>> /\ active = {} /\ done = {}
Accept(j) == /\ j \notin accepted
             /\ accepted' = accepted \cup {j}
             /\ waiting' = Append(waiting, j)
             /\ UNCHANGED <<active, done>>
Claim == /\ Len(waiting) > 0
         /\ active' = active \cup {Head(waiting)}
         /\ waiting' = Tail(waiting)
         /\ UNCHANGED <<accepted, done>>
Finish(j) == /\ j \in active
             /\ active' = active \ {j}
             /\ done' = done \cup {j}
             /\ UNCHANGED <<accepted, waiting>>
CrashAfterRemove == /\ Len(waiting) > 0
                    /\ waiting' = Tail(waiting)
                    /\ UNCHANGED <<accepted, active, done>>
Next == (\E j \in Jobs: Accept(j) \/ Finish(j)) \/ Claim
        \/ CrashAfterRemove
Spec == Init /\ [][Next]_vars
Waiting == {waiting[i] : i \in 1..Len(waiting)}
ExactlyOnePlace ==
    /\ Waiting \cup active \cup done = accepted
    /\ Waiting \cap active = {}
    /\ Waiting \cap done = {}
    /\ active \cap done = {}
===================================================
