------------------ MODULE PSl3_WorkersFixed ------------------
EXTENDS Integers
VARIABLES running, permits

MaxJobs == 2

Init == /\ running = 0
        /\ permits = MaxJobs

Start  == /\ permits > 0
          /\ permits' = permits - 1
          /\ running' = running + 1

Finish == /\ running > 0
          /\ running' = running - 1
          /\ permits' = permits + 1

Fail   == /\ running > 0
          /\ running' = running - 1
          /\ permits' = permits + 1

Next == Start \/ Finish \/ Fail

AtMostTwo == running =< MaxJobs
PermitsOK == permits + running = MaxJobs
=========================================================
