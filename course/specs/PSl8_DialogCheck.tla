------------------------- MODULE PSl8_DialogCheck ---------------------------
\* Not shown to learners: replays each listed behavior (then stutters
\* forever) so TLC can evaluate the formulas of PSl8_Dialog on it.
EXTENDS Integers, PSl8_Dialog
CONSTANT Which
VARIABLE i
B == CASE Which = 1 -> <<"closed", "open", "submitting", "closed">>
       [] Which = 2 -> <<"closed", "open", "submitting", "open">>
       [] Which = 3 -> <<"open", "submitting", "error", "closed">>
       [] Which = 4 -> <<"closed", "closed", "closed", "closed">>
RInit == i = 1 /\ dialog = B[1]
RNext == i < 4 /\ i' = i + 1 /\ dialog' = B[i + 1]
RSpec == RInit /\ [][RNext]_<<i, dialog>>
=============================================================================
