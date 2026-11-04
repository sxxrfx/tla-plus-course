---------------- MODULE Worker ----------------
EXTENDS Naturals
CONSTANTS Workers, Mode
ASSUME Mode \in {"EffectFirst", "IdFirst", "Atomic", "CheckThenCommit"}
VARIABLES effects, seen,   \* durable: survive a crash
          pc,              \* volatile: lost in a crash
          replied          \* the client has been told "done"
vars == <<effects, seen, pc, replied>>

Init == /\ effects = 0
        /\ seen = FALSE
        /\ pc = [w \in Workers |-> "idle"]
        /\ replied = FALSE

Go(w, where) == pc' = [pc EXCEPT ![w] = where]

\* A delivery reads the durable ID, then starts the chosen design.
Begin(w) ==
    /\ pc[w] = "idle"
    /\ UNCHANGED replied
    /\ IF seen
       THEN Go(w, "reply") /\ UNCHANGED <<effects, seen>>
       ELSE CASE Mode = "EffectFirst" ->
                   effects' = effects + 1 /\ UNCHANGED seen /\ Go(w, "record")
              [] Mode = "IdFirst" ->
                   seen' = TRUE /\ UNCHANGED effects /\ Go(w, "charge")
              [] Mode = "Atomic" ->
                   effects' = effects + 1 /\ seen' = TRUE /\ Go(w, "reply")
              [] Mode = "CheckThenCommit" ->
                   UNCHANGED <<effects, seen>> /\ Go(w, "commit")

Record(w) == /\ pc[w] = "record" /\ seen' = TRUE
             /\ UNCHANGED <<effects, replied>> /\ Go(w, "reply")
Charge(w) == /\ pc[w] = "charge" /\ effects' = effects + 1
             /\ UNCHANGED <<seen, replied>> /\ Go(w, "reply")
Commit(w) == /\ pc[w] = "commit"
             /\ effects' = effects + 1 /\ seen' = TRUE
             /\ UNCHANGED replied /\ Go(w, "reply")
Reply(w)  == /\ pc[w] = "reply" /\ replied' = TRUE
             /\ UNCHANGED <<effects, seen>> /\ Go(w, "idle")
Crash(w)  == /\ pc[w] # "idle"
             /\ UNCHANGED <<effects, seen, replied>> /\ Go(w, "idle")

Next == \E w \in Workers:
    Begin(w) \/ Record(w) \/ Charge(w) \/ Commit(w) \/ Reply(w) \/ Crash(w)
Spec == Init /\ [][Next]_vars

AtMostOnce  == effects <= 1
ReplyHonest == replied => effects >= 1
Bound       == effects <= 2     \* search limit for the buggy designs

Contract == INSTANCE Once WITH Requests <- {"r"},
                seen <- IF seen THEN {"r"} ELSE {},
                effects <- [r \in {"r"} |-> effects]
Refines == Contract!Spec
================================================
