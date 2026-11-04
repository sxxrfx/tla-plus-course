---- MODULE CaseGap ----
EXTENDS Naturals
VARIABLE v
F(x) == CASE x > 5 -> "big"
Init == v = F(1)
Next == v' = v
========================
