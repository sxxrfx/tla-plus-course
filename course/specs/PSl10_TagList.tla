---------------- MODULE PSl10_TagList ----------------
CONSTANT Tags
VARIABLES pending, confirmed, server, msgs
vars == <<pending, confirmed, server, msgs>>
Msgs == [type : {"add", "ok", "rejected"}, tag : Tags]
TypeOK == /\ pending \subseteq Tags
          /\ confirmed \subseteq Tags
          /\ server \subseteq Tags
          /\ msgs \subseteq Msgs
Init == /\ pending = {}      \* shown greyed out, waiting for the server
        /\ confirmed = {}    \* shown normally
        /\ server = {}       \* the server's stored tags
        /\ msgs = {}
Sent(t) == \E m \in msgs : m.tag = t
\* The user types a tag; it appears at once, marked pending.
UserAdd(t) == /\ ~Sent(t)
              /\ pending' = pending \cup {t}
              /\ msgs' = msgs \cup {[type |-> "add", tag |-> t]}
              /\ UNCHANGED <<confirmed, server>>
Answered(t) == \E m \in msgs : m.tag = t /\ m.type \in {"ok", "rejected"}
ServerAccept(t) == /\ [type |-> "add", tag |-> t] \in msgs
                   /\ ~Answered(t)
                   /\ server' = server \cup {t}
                   /\ msgs' = msgs \cup {[type |-> "ok", tag |-> t]}
                   /\ UNCHANGED <<pending, confirmed>>
ServerReject(t) == /\ [type |-> "add", tag |-> t] \in msgs
                   /\ ~Answered(t)
                   /\ msgs' = msgs \cup {[type |-> "rejected", tag |-> t]}
                   /\ UNCHANGED <<pending, confirmed, server>>
ClientOk(t) == /\ [type |-> "ok", tag |-> t] \in msgs
               /\ t \in pending
               /\ pending' = pending \ {t}
               /\ confirmed' = confirmed \cup {t}
               /\ UNCHANGED <<server, msgs>>
ClientRollback(t) == /\ [type |-> "rejected", tag |-> t] \in msgs
                     /\ t \in pending
                     /\ pending' = pending \ {t}
                     /\ UNCHANGED <<confirmed, server, msgs>>
Next == \E t \in Tags : \/ UserAdd(t)
                        \/ ServerAccept(t) \/ ServerReject(t)
                        \/ ClientOk(t) \/ ClientRollback(t)
Spec == Init /\ [][Next]_vars
Fairness == \A t \in Tags :
              /\ WF_vars(ServerAccept(t) \/ ServerReject(t))
              /\ WF_vars(ClientOk(t) \/ ClientRollback(t))
FairSpec == Spec /\ Fairness

Shown == pending \cup confirmed
ByShown     == INSTANCE PSl10_TagSet WITH tags <- Shown
ByConfirmed == INSTANCE PSl10_TagSet WITH tags <- confirmed
ByServer    == INSTANCE PSl10_TagSet WITH tags <- server
ShownRefines     == ByShown!Spec
ConfirmedRefines == ByConfirmed!Spec
ServerRefines    == ByServer!Spec
ConfirmedOnServer == confirmed \subseteq server
Settles == \A t \in Tags : (t \in pending) ~> (t \notin pending)
Converges == <>[](Shown = server)
======================================================
