--------------- MODULE SimpleProgramIf ---------------
EXTENDS Integers
VARIABLES i, pc

Init == (i = 0) /\ (pc = "start")

Next == IF pc = "start"
          THEN (i' \in 0..1000) /\
               (pc' = "middle")
          ELSE IF pc = "middle"
                 THEN (i' = i + 1) /\
                      (pc' = "done")
                 ELSE FALSE
======================================================
