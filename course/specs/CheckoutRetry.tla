------------------------------ MODULE CheckoutRetry ---------------------------
EXTENDS Integers
CONSTANTS Attempt,          \* the attempts the client may send for request r7
          KeyField          \* the message field the server deduplicates on
VARIABLES
  msgs,                     \* every attempt ever sent; never shrinks
  applied,                  \* what the server has recorded as already done
  orders,                   \* orders the server created
  replied,                  \* the server has sent a reply
  client                    \* "waiting" or "knows"
vars == <<msgs, applied, orders, replied, client>>

CInit == /\ msgs = {} /\ applied = {} /\ orders = 0
         /\ replied = FALSE /\ client = "waiting"

\* First try, or a retry after a timeout. Nothing forces a reply to come first.
Send(a) == /\ client = "waiting"
           /\ [req |-> "r7", try |-> a] \notin msgs
           /\ msgs' = msgs \cup {[req |-> "r7", try |-> a]}
           /\ UNCHANGED <<applied, orders, replied, client>>

\* The client learns the result only if it reads a reply.
Hear == /\ replied
        /\ client' = "knows"
        /\ UNCHANGED <<msgs, applied, orders, replied>>

\* Creates an order unless this message's key is recorded. Delivery leaves m
\* in msgs, so m can be delivered again; one never delivered has been lost.
Deliver ==
  \E m \in msgs :
    /\ m[KeyField] \notin applied
    /\ orders < 2
    /\ orders' = orders + 1
    /\ applied' = applied \cup {m[KeyField]}
    /\ replied' = TRUE
    /\ UNCHANGED <<msgs, client>>

\* A repeat of work already done: just send the reply again.
Repeat ==
  \E m \in msgs :
    /\ m[KeyField] \in applied
    /\ replied' = TRUE
    /\ UNCHANGED <<msgs, applied, orders, client>>

CNext == \/ \E a \in Attempt : Send(a)
         \/ Deliver \/ Repeat \/ Hear

OneOrder == orders <= 1
KnowsTruth == client = "knows" => orders >= 1
=============================================================================
