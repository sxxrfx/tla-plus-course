---------------- MODULE PSfinal_Saga ----------------
CONSTANT Design
ASSUME Design \in {"ReleaseOnly", "Refund", "RefundTombstone"}
VARIABLES stock,  \* inventory service: "reserved" or "released"
          pay,    \* payment service: "none", "charged", "declined",
                  \*   "refunded" or "blocked" (a refund came first)
          orch,   \* orchestrator: "charge", "wait", "done", "cancelled"
          msgs    \* messages in flight
vars == <<stock, pay, orch, msgs>>

Init == /\ stock = "reserved"     \* step 1 of the saga has completed
        /\ pay = "none"
        /\ orch = "charge"
        /\ msgs = {}

\* Step 2: ask the payment service to charge the card.
SendCharge == /\ orch = "charge"
              /\ orch' = "wait"
              /\ msgs' = msgs \cup {"charge"}
              /\ UNCHANGED <<stock, pay>>

\* The payment service handles the charge request.
Reply(m) == msgs' = (msgs \ {"charge"}) \cup {m}
Charge == /\ "charge" \in msgs
          /\ \/ pay = "none" /\ pay' = "charged" /\ Reply("charged")
             \/ pay = "none" /\ pay' = "declined" /\ Reply("declined")
             \/ pay = "blocked" /\ UNCHANGED pay /\ Reply("declined")
          /\ UNCHANGED <<stock, orch>>

\* The orchestrator gets the outcome.
Charged  == /\ "charged" \in msgs
            /\ msgs' = msgs \ {"charged"}
            /\ orch' = IF orch = "wait" THEN "done" ELSE orch
            /\ UNCHANGED <<stock, pay>>
Declined == /\ "declined" \in msgs
            /\ msgs' = msgs \ {"declined"}
            /\ IF orch = "wait"
                  THEN orch' = "cancelled" /\ stock' = "released"
                  ELSE UNCHANGED <<orch, stock>>
            /\ UNCHANGED pay

\* No reply yet: the orchestrator gives up and compensates.
Timeout == /\ orch = "wait"
           /\ orch' = "cancelled"
           /\ stock' = "released"
           /\ msgs' = IF Design = "ReleaseOnly" THEN msgs
                      ELSE msgs \cup {"refund"}
           /\ UNCHANGED pay

\* The payment service handles a refund for this order.
Refund == /\ "refund" \in msgs
          /\ msgs' = msgs \ {"refund"}
          /\ pay' = CASE pay = "charged" -> "refunded"
                      [] pay = "none" /\ Design = "RefundTombstone" -> "blocked"
                      [] OTHER -> pay
          /\ UNCHANGED <<stock, orch>>

Next == SendCharge \/ Charge \/ Charged \/ Declined \/ Timeout \/ Refund
Spec == Init /\ [][Next]_vars
FairSpec == /\ Spec
            /\ WF_vars(SendCharge) /\ WF_vars(Charge) /\ WF_vars(Charged)
            /\ WF_vars(Declined) /\ WF_vars(Refund)

\* What a finished order must look like.
Settled == \/ orch = "done" /\ stock = "reserved" /\ pay = "charged"
           \/ orch = "cancelled" /\ stock = "released" /\ pay # "charged"
EventuallySettled == <>[]Settled
\* A search goal: a quiet system with a paid, cancelled order.
NoPaidCancelled == ~(orch = "cancelled" /\ pay = "charged" /\ msgs = {})
\* "Never charged while the stock is released" (true of 2PC's outcome).
NoChargedRelease == ~(pay = "charged" /\ stock = "released")
======================================================
