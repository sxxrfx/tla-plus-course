---------------- MODULE TicketHold ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Buyers
VARIABLES remaining, held, confirmed, paying
vars == <<remaining, held, confirmed, paying>>
Init == /\ remaining = 1
        /\ held = {}
        /\ confirmed = {}
        /\ paying = {}
Reserve(b) ==
    /\ remaining > 0
    /\ b \notin confirmed
    /\ remaining' = remaining - 1
    /\ held' = held \cup {b}
    /\ UNCHANGED <<confirmed, paying>>
StartPayment(b) ==
    /\ b \in held
    /\ paying' = paying \cup {b}
    /\ UNCHANGED <<remaining, held, confirmed>>
Cancel(b) ==          \* also models expiry of the hold
    /\ b \in held
    /\ held' = held \ {b}
    /\ remaining' = remaining + 1
    /\ UNCHANGED <<confirmed, paying>>
LatePayment(b) ==
    /\ b \in paying
    /\ b \in held     \* delete this line to get the bug
    /\ confirmed' = confirmed \cup {b}
    /\ held' = held \ {b}
    /\ paying' = paying \ {b}
    /\ UNCHANGED remaining
Next == \E b \in Buyers:
    Reserve(b) \/ StartPayment(b) \/ Cancel(b) \/ LatePayment(b)
Spec == Init /\ [][Next]_vars
OnePromise == Cardinality(held \cup confirmed) <= 1
====================================================
