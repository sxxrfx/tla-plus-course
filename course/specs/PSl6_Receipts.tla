----------------------------- MODULE PSl6_Receipts -----------------------------
EXTENDS Integers
CONSTANT Mode            \* how the email worker handles a delivery:
                         \* "naive", "atomic", or "twostep"
Orders == {"o1", "o2"}   \* o1 is placed before o2
Receipt(o) == [type |-> "receipt", order |-> o]
VARIABLES
  msgs,                  \* every message ever published to the queue
  sent,                  \* sent[o]: receipt emails sent for order o
  emailed                \* orders the worker's table records as emailed
vars == <<msgs, sent, emailed>>

TypeOK == /\ msgs \subseteq [type : {"receipt"}, order : Orders]
          /\ sent \in [Orders -> 0..2]
          /\ emailed \subseteq Orders

Init == /\ msgs = {}
        /\ sent = [o \in Orders |-> 0]
        /\ emailed = {}

\* The order service publishes after each order commits, o1 first.
Publish(o) == /\ Receipt(o) \notin msgs
              /\ o = "o2" => Receipt("o1") \in msgs
              /\ msgs' = msgs \cup {Receipt(o)}
              /\ UNCHANGED <<sent, emailed>>

SendEmail(o) == sent' = [sent EXCEPT ![o] = sent[o] + 1]

\* The queue hands o's receipt message to the worker (again, possibly).
Deliver(o) ==
  /\ Receipt(o) \in msgs
  /\ sent[o] < 2                          \* keeps the model finite
  /\ \/ /\ Mode = "naive"
        /\ SendEmail(o)
        /\ UNCHANGED emailed
     \/ /\ Mode = "atomic"                \* check, send, record: one step
        /\ o \notin emailed
        /\ SendEmail(o)
        /\ emailed' = emailed \cup {o}
     \/ /\ Mode = "twostep"               \* check and send; record later
        /\ o \notin emailed
        /\ SendEmail(o)
        /\ UNCHANGED emailed
  /\ UNCHANGED msgs

\* twostep only: the worker writes "emailed" after the provider accepts.
Record(o) == /\ Mode = "twostep"
             /\ sent[o] > 0
             /\ o \notin emailed
             /\ emailed' = emailed \cup {o}
             /\ UNCHANGED <<msgs, sent>>

Next == \E o \in Orders : Publish(o) \/ Deliver(o) \/ Record(o)

OneEmail == \A o \in Orders : sent[o] =< 1
InOrder  == sent["o2"] > 0 => sent["o1"] > 0
=============================================================================
