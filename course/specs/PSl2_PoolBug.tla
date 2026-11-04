----------------- MODULE PSl2_PoolBug -----------------
EXTENDS Integers
VARIABLES idle, busy

Max == 3

Init == /\ idle = 0
        /\ busy = 0

Open    == /\ idle + busy < Max
           /\ idle' = idle + 1
           /\ busy' = busy

Acquire == /\ busy < Max
           /\ idle' = idle - 1
           /\ busy' = busy + 1

Release == /\ busy > 0
           /\ busy' = busy - 1
           /\ idle' = idle + 1

Evict   == /\ idle > 0
           /\ idle' = idle - 1
           /\ busy' = busy

Next == Open \/ Acquire \/ Release \/ Evict

PoolOK == /\ idle \in 0..Max
          /\ busy \in 0..Max
          /\ idle + busy \in 0..Max
=======================================================
