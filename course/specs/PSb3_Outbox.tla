---------------- MODULE PSb3_Outbox ----------------
EXTENDS Naturals
CONSTANTS Orders, Mode, Dedup, MaxCrashes
ASSUME Mode \in {"DualWrite", "Outbox"} /\ Dedup \in BOOLEAN
VARIABLES orders,     \* order service DB: committed orders
          outbox,     \* order service DB: outbox rows not yet relayed
          handler,    \* handler[o]: "new", "publish" or "done" (volatile)
          relay,      \* the relay's in-memory work: "idle" or an order
          broker,     \* orders whose event the broker holds
          processed,  \* shipping DB: orders recorded as handled
          labels,     \* labels[o]: shipping labels printed for o
          crashes     \* crashes so far
vars == <<orders, outbox, handler, relay, broker,
          processed, labels, crashes>>

Init == /\ orders = {}
        /\ outbox = {}
        /\ handler = [o \in Orders |-> "new"]
        /\ relay = "idle"
        /\ broker = {}
        /\ processed = {}
        /\ labels = [o \in Orders |-> 0]
        /\ crashes = 0

\* The checkout handler commits the order. In Outbox mode the same
\* transaction inserts the outbox row.
Place(o) == /\ handler[o] = "new"
            /\ orders' = orders \cup {o}
            /\ IF Mode = "Outbox"
                  THEN outbox' = outbox \cup {o} /\ handler' = [handler EXCEPT ![o] = "done"]
                  ELSE UNCHANGED outbox /\ handler' = [handler EXCEPT ![o] = "publish"]
            /\ UNCHANGED <<relay, broker, processed, labels, crashes>>

\* DualWrite: after the commit, the handler publishes to the broker.
Publish(o) == /\ handler[o] = "publish"
              /\ broker' = broker \cup {o}
              /\ handler' = [handler EXCEPT ![o] = "done"]
              /\ UNCHANGED <<orders, outbox, relay, processed, labels, crashes>>

\* Outbox: a relay publishes a row, then deletes it in a second step.
RelayPublish(o) == /\ relay = "idle" /\ o \in outbox
                   /\ broker' = broker \cup {o}
                   /\ relay' = o
                   /\ UNCHANGED <<orders, outbox, handler, processed, labels, crashes>>
RelayDelete == /\ relay # "idle"
               /\ outbox' = outbox \ {relay}
               /\ relay' = "idle"
               /\ UNCHANGED <<orders, handler, broker, processed, labels, crashes>>

\* A process crash loses in-memory state; databases and broker survive.
Crash == /\ crashes < MaxCrashes
         /\ crashes' = crashes + 1
         /\ \/ \E o \in Orders : /\ handler[o] = "publish"
                                 /\ handler' = [handler EXCEPT ![o] = "done"]
                                 /\ UNCHANGED relay
            \/ /\ relay # "idle"
               /\ relay' = "idle"
               /\ UNCHANGED handler
         /\ UNCHANGED <<orders, outbox, broker, processed, labels>>

\* The broker delivers at least once: an event stays available, so the
\* consumer can receive it again. With Dedup, printing the label and
\* recording the order happen in one shipping-DB transaction.
Consume(o) == /\ o \in broker
              /\ Dedup => o \notin processed
              /\ labels[o] < 2
              /\ labels' = [labels EXCEPT ![o] = @ + 1]
              /\ processed' = processed \cup {o}
              /\ UNCHANGED <<orders, outbox, handler, relay, broker, crashes>>

Next == \/ \E o \in Orders : Place(o) \/ Publish(o) \/ RelayPublish(o) \/ Consume(o)
        \/ RelayDelete \/ Crash
Spec == Init /\ [][Next]_vars
Fairness == /\ \A o \in Orders : WF_vars(Publish(o)) /\ WF_vars(RelayPublish(o))
                                 /\ WF_vars(Consume(o))
            /\ WF_vars(RelayDelete)
FairSpec == Spec /\ Fairness

OneLabel == \A o \in Orders : labels[o] <= 1
NoLostEvent == \A o \in orders :
    o \in outbox \/ o \in broker \/ handler[o] = "publish"
Shipped == \A o \in Orders : (o \in orders) ~> (labels[o] >= 1)
====================================================
