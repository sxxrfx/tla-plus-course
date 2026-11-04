---------------- MODULE CartReach ----------------
EXTENDS Integers
VARIABLES items, termsAccepted, inStock, ordered

Init == /\ items = 2
        /\ termsAccepted \in {TRUE, FALSE}
        /\ inStock \in {TRUE, FALSE}
        /\ ordered = FALSE

Eligible == /\ items > 0
            /\ termsAccepted

CanCheckout == /\ Eligible
               /\ inStock

Checkout == /\ CanCheckout
            /\ ~ordered
            /\ ordered' = TRUE
            /\ items' = items
            /\ termsAccepted' = termsAccepted
            /\ inStock' = inStock

Next == Checkout

OrderOK == ordered => termsAccepted
NeverOrdered == ~ordered
=============================================
