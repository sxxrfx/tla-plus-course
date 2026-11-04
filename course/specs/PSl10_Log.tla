---------------- MODULE PSl10_Log ----------------
EXTENDS Sequences
CONSTANT Vals
VARIABLE log
Init == log = <<>>
Next == \E v \in Vals : log' = Append(log, v)
Spec == Init /\ [][Next]_log
==================================================
