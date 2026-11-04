---------------- MODULE CameraCheckout ----------------
EXTENDS Naturals, FiniteSets
CONSTANTS InitialStock, NewIdOnRetry, ConsumerDedup
ASSUME /\ InitialStock \in 1..2
       /\ NewIdOnRetry \in BOOLEAN
       /\ ConsumerDedup \in BOOLEAN
Orders == {"r42", "r43"}
VARIABLES attempts,      \* order IDs the browser has sent so far
          stockFree, stockReserved,
          charges,       \* charges[r]: effects at the payment provider
          decision,      \* decision[r]: "pending", "commit", "abort"
          outbox,        \* events durably saved with the decision
          shipments      \* shipments[r]: shipping effects, counted
vars == <<attempts, stockFree, stockReserved,
          charges, decision, outbox, shipments>>

Init == /\ attempts = {"r42"}
        /\ stockFree = InitialStock
        /\ stockReserved = {}
        /\ charges = [r \in Orders |-> 0]
        /\ decision = [r \in Orders |-> "pending"]
        /\ outbox = {}
        /\ shipments = [r \in Orders |-> 0]

\* The reply was lost. The retry may reach either region; both consult
\* the same durable records, so the region does not appear as state.
\* Resending the same ID changes nothing here: it is a stuttering step.
Retry == /\ attempts' = attempts \cup
                {IF NewIdOnRetry THEN "r43" ELSE "r42"}
         /\ attempts' # attempts
         /\ UNCHANGED <<stockFree, stockReserved, charges,
                        decision, outbox, shipments>>

Reserve(r) == /\ r \in attempts
              /\ decision[r] = "pending"
              /\ r \notin stockReserved
              /\ stockFree > 0
              /\ stockFree' = stockFree - 1
              /\ stockReserved' = stockReserved \cup {r}
              /\ UNCHANGED <<attempts, charges, decision, outbox, shipments>>

SoldOut(r) == /\ r \in attempts
              /\ decision[r] = "pending"
              /\ r \notin stockReserved
              /\ stockFree = 0
              /\ decision' = [decision EXCEPT ![r] = "abort"]
              /\ UNCHANGED <<attempts, stockFree, stockReserved,
                             charges, outbox, shipments>>

\* One durable boundary: the charge, the decision, and the outbox event.
Pay(r) == /\ r \in stockReserved
          /\ decision[r] = "pending"
          /\ charges' = [charges EXCEPT ![r] = @ + 1]
          /\ decision' = [decision EXCEPT ![r] = "commit"]
          /\ outbox' = outbox \cup {r}
          /\ UNCHANGED <<attempts, stockFree, stockReserved, shipments>>

\* The event can be delivered again until the consumer's record says stop.
Consume(r) == /\ r \in outbox
              /\ ConsumerDedup => shipments[r] = 0
              /\ shipments[r] < 2
              /\ shipments' = [shipments EXCEPT ![r] = @ + 1]
              /\ UNCHANGED <<attempts, stockFree, stockReserved,
                             charges, decision, outbox>>

Next == \/ Retry
        \/ \E r \in Orders :
              Reserve(r) \/ SoldOut(r) \/ Pay(r) \/ Consume(r)
Spec == Init /\ [][Next]_vars

TypeOK == /\ attempts \subseteq Orders
          /\ stockFree \in 0..InitialStock
          /\ stockReserved \subseteq Orders
          /\ charges \in [Orders -> 0..2]
          /\ decision \in [Orders -> {"pending", "commit", "abort"}]
          /\ outbox \subseteq Orders
          /\ shipments \in [Orders -> 0..2]
OneChargePerId == \A r \in Orders : charges[r] <= 1
OneChargePerCheckout == charges["r42"] + charges["r43"] <= 1
StockConserved == stockFree + Cardinality(stockReserved) = InitialStock
ShipOnlyCommitted == \A r \in Orders :
    shipments[r] > 0 => decision[r] = "commit"
OneShipmentPerId == \A r \in Orders : shipments[r] <= 1
=======================================================
