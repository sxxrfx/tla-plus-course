------------------------------ MODULE PSl6_StockFixed ------------------------------
EXTENDS Integers
CONSTANT RM              \* the warehouses; the order needs one unit from each
Stock0 == 1              \* units each warehouse has on the shelf at the start
VARIABLES rmState, tmState, tmPrepared, msgs,
          stock          \* stock[w]: units on the shelf at w, not reserved
vars == <<rmState, tmState, tmPrepared, msgs, stock>>

Messages == [type : {"Prepared"}, rm : RM] \cup [type : {"Commit", "Abort"}]

TypeOK ==
  /\ rmState \in [RM -> {"working", "prepared", "committed", "aborted"}]
  /\ tmState \in {"init", "done"}
  /\ tmPrepared \subseteq RM
  /\ msgs \subseteq Messages
  /\ stock \in [RM -> 0..Stock0]

Init ==
  /\ rmState = [r \in RM |-> "working"]
  /\ tmState = "init"
  /\ tmPrepared = {}
  /\ msgs = {}
  /\ stock = [r \in RM |-> Stock0]
-----------------------------------------------------------------------------
TMRcvPrepared(r) ==
  /\ tmState = "init"
  /\ [type |-> "Prepared", rm |-> r] \in msgs
  /\ tmPrepared' = tmPrepared \cup {r}
  /\ UNCHANGED <<rmState, tmState, msgs, stock>>

TMCommit ==
  /\ tmState = "init"
  /\ tmPrepared = RM
  /\ tmState' = "done"
  /\ msgs' = msgs \cup {[type |-> "Commit"]}
  /\ UNCHANGED <<rmState, tmPrepared, stock>>

TMAbort ==
  /\ tmState = "init"
  /\ tmState' = "done"
  /\ msgs' = msgs \cup {[type |-> "Abort"]}
  /\ UNCHANGED <<rmState, tmPrepared, stock>>

\* Prepare = reserve: take a unit off the shelf and hold it for this order.
RMPrepare(r) ==
  /\ rmState[r] = "working"
  /\ stock[r] > 0
  /\ rmState' = [rmState EXCEPT ![r] = "prepared"]
  /\ stock' = [stock EXCEPT ![r] = stock[r] - 1]
  /\ msgs' = msgs \cup {[type |-> "Prepared", rm |-> r]}
  /\ UNCHANGED <<tmState, tmPrepared>>

RMChooseToAbort(r) ==
  /\ rmState[r] = "working"
  /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs, stock>>

\* Commit = ship the held unit. The shelf count doesn't change.
RMRcvCommitMsg(r) ==
  /\ [type |-> "Commit"] \in msgs
  /\ rmState' = [rmState EXCEPT ![r] = "committed"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs, stock>>

\* Abort = cancel the reservation and put the unit back on the shelf.
RMRcvAbortMsg(r) ==
  /\ [type |-> "Abort"] \in msgs
  /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
  /\ stock' = IF rmState[r] = "prepared"
                THEN [stock EXCEPT ![r] = stock[r] + 1]
                ELSE stock
  /\ UNCHANGED <<tmState, tmPrepared, msgs>>
-----------------------------------------------------------------------------
Next ==
  \/ TMCommit \/ TMAbort
  \/ \E r \in RM : TMRcvPrepared(r) \/ RMPrepare(r) \/ RMChooseToAbort(r)
                     \/ RMRcvCommitMsg(r) \/ RMRcvAbortMsg(r)
-----------------------------------------------------------------------------
INSTANCE TCommit

Held(w) == IF rmState[w] \in {"prepared", "committed"} THEN 1 ELSE 0

\* Every unit is on the shelf, or held or shipped for this order.
Conservation == \A w \in RM : stock[w] + Held(w) = Stock0
=============================================================================
