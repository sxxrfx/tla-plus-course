--------------------------- MODULE PSl8_Dashboard ---------------------------
\* The redesigned tile shows hours and minutes. Does it still satisfy the
\* hour-clock spec that the alerting rules were written against?
EXTENDS Integers
VARIABLES hr, min
vars == <<hr, min>>
Init == hr \in 0..23 /\ min \in 0..59
Tick == /\ min' = IF min = 59 THEN 0 ELSE min + 1
        /\ hr' = IF min = 59 THEN (IF hr = 23 THEN 0 ELSE hr + 1) ELSE hr
\* Daylight saving time starts: the local clock jumps from 01:59 to 03:00.
SpringForward == /\ hr = 1 /\ min = 59
                 /\ hr' = 3 /\ min' = 0
Spec == Init /\ [][Tick]_vars
DSTSpec == Init /\ [][Tick \/ SpringForward]_vars

H == INSTANCE PSl8_HourClock
HourSpec == H!HSpec
\* The same claim with stuttering allowed only when hr AND min are unchanged.
HourSpecNoStutter == H!HInit /\ [][H!HNext]_vars
=============================================================================
