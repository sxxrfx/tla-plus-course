---------------- MODULE RetryBudget ----------------
EXTENDS Integers
VARIABLE attempts

Init == attempts = 0

Next == /\ attempts < 3
        /\ attempts' = attempts + 1

BudgetOK == attempts \in 0..3
====================================================
