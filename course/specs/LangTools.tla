---------------- MODULE LangTools ----------------
EXTENDS Naturals
Outcome(x) == CASE x = 0 -> "empty"
                [] x > 0 -> "ready"
Pick == CHOOSE x \in {"A", "B"}: TRUE
RECURSIVE Fact(_)
Fact(n) == IF n = 0 THEN 1 ELSE n * Fact(n-1)
LOCAL Helper == 41
Exported == Helper + 1
ASSUME Outcome(0) = "empty" /\ Outcome(3) = "ready"
ASSUME Pick = Pick /\ Pick \in {"A", "B"}
ASSUME Fact(4) = 24 /\ Exported = 42
VARIABLE v
Spec == v = Pick /\ [][v' = Pick]_v
Stable == v = Pick
==================================================
