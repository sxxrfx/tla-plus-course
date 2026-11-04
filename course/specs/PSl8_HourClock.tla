--------------------------- MODULE PSl8_HourClock ---------------------------
\* The "current hour" tile on an ops dashboard: a 24-hour clock.
EXTENDS Integers
VARIABLE hr
HInit == hr \in 0..23
HNext == hr' = IF hr = 23 THEN 0 ELSE hr + 1
HSpec == HInit /\ [][HNext]_hr
=============================================================================
