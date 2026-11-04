---------------- MODULE AppState ----------------
EXTENDS Naturals
VARIABLES latest, pending, ui
vars == <<latest,pending,ui>>
Requests == 1..2
Query == [r \in Requests |->
             IF r = 1 THEN "cats" ELSE "dogs"]
UIStates ==
    [tag : {"idle"}]
    \cup [tag : {"loading"}, request : Requests]
    \cup [tag : {"ready"}, request : Requests,
          value : {"cats", "dogs"}]

Init == /\ latest = 0
        /\ pending = {}
        /\ ui = [tag |-> "idle"]
Start ==
    /\ latest < 2
    /\ LET r == latest + 1 IN
           /\ latest' = r
           /\ pending' = pending \cup {r}
           /\ ui' = [tag |-> "loading", request |-> r]
Deliver(r) ==
    /\ r \in pending
    /\ pending' = pending \ {r}
    /\ UNCHANGED latest
    /\ ui' = IF r = latest
              THEN [tag |-> "ready", request |-> r,
                    value |-> Query[r]]
              ELSE ui
Next == Start \/ (\E r \in Requests: Deliver(r))
Spec == Init /\ [][Next]_vars
FairSpec == Spec /\ (\A r \in Requests: WF_vars(Deliver(r)))

TypeOK == /\ latest \in 0..2
          /\ pending \subseteq 1..latest
          /\ ui \in UIStates
CurrentView ==
    IF ui.tag = "ready"
    THEN /\ ui.request = latest
         /\ ui.value = Query[latest]
    ELSE TRUE
Settles == (ui.tag = "loading") ~> (ui.tag = "ready")
=================================================
