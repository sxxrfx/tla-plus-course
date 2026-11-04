---------------- MODULE InventorySplit ----------------
EXTENDS Integers, FiniteSets
CONSTANT Buyers
VARIABLES remaining, booked, pc
vars == <<remaining, booked, pc>>
Init == /\ remaining = 1
        /\ booked = {}
        /\ pc = [b \in Buyers |-> "idle"]
Check(b) ==
    /\ pc[b] = "idle"
    /\ remaining > 0
    /\ pc' = [pc EXCEPT ![b] = "checked"]
    /\ UNCHANGED <<remaining, booked>>
Reserve(b) ==
    /\ pc[b] = "checked"
    /\ remaining' = remaining - 1
    /\ booked' = booked \cup {b}
    /\ pc' = [pc EXCEPT ![b] = "done"]
Next == \E b \in Buyers: Check(b) \/ Reserve(b)
Spec == Init /\ [][Next]_vars
NoOverselling == Cardinality(booked) <= 1
=======================================================
