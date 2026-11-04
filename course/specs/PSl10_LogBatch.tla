---------------- MODULE PSl10_LogBatch ----------------
EXTENDS Naturals, Sequences
CONSTANT Vals
VARIABLE log
Init == log = <<>>
\* One step may append one or more entries; earlier entries never change.
Extend == /\ log' \in Seq(Vals)
          /\ Len(log') > Len(log)
          /\ \A i \in 1..Len(log) : log'[i] = log[i]
Spec == Init /\ [][Extend]_log
=======================================================
