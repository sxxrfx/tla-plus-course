---------------- MODULE PSl1_Elevator ----------------
\* Verification model for ps-l1 problem 1 (not printed: the set has no TLA+ yet).
EXTENDS Integers
VARIABLES floor, door

Init == floor = 1 /\ door = "closed"

DoorStep == /\ floor' = floor
            /\ \/ door = "closed"  /\ door' = "opening"
               \/ door = "opening" /\ door' = "open"
               \/ door = "open"    /\ door' = "closing"
               \/ door = "closing" /\ door' = "closed"
               \/ door = "closing" /\ door' = "opening"

Move == /\ door = "closed"
        /\ door' = door
        /\ floor' \in {floor - 1, floor + 1}
        /\ floor' \in 1..3

Next == DoorStep \/ Move
=======================================================
