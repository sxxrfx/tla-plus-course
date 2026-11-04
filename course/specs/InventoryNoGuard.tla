---------------- MODULE InventoryNoGuard ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Buyers
VARIABLES remaining, booked
vars == <<remaining, booked>>
Init == /\ remaining = 1
        /\ booked = {}
Reserve(b) ==
    /\ remaining > 0
    /\ remaining' = remaining - 1
    /\ booked' = booked \cup {b}
Next == \E b \in Buyers: Reserve(b)
Spec == Init /\ [][Next]_vars
TypeOK == /\ remaining \in 0..1
          /\ booked \in SUBSET Buyers
Conservation == remaining + Cardinality(booked) = 1
NoOverselling == Cardinality(booked) <= 1
==================================================
