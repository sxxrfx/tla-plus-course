---- MODULE SetFacts ----
\* Every formula shown in the sets lesson, checked as an assumption.
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == x' = x
RMs == {"r1", "r2", "r3"}
sqr == [i \in 1..42 |-> i^2]
ASSUME sqr[3] = 9 /\ DOMAIN sqr = 1..42
ASSUME {"r1", "r2", "r1"} = {"r2", "r1"}
ASSUME "r2" \in RMs /\ "r9" \notin RMs
ASSUME 1..3 = {1, 2, 3}
st == [r \in RMs |-> "working"]
st2 == [st EXCEPT !["r2"] = "prepared"]
ASSUME st["r1"] = "working" /\ st2["r2"] = "prepared" /\ st2["r1"] = "working" /\ st2["r3"] = "working"
ASSUME st2 = [s \in RMs |-> IF s = "r2" THEN "prepared" ELSE st[s]]
\* a set of functions
F == [{"r1", "r2"} -> {"a", "b"}]
ASSUME F = { [r \in {"r1","r2"} |-> "a"], [r \in {"r1","r2"} |-> "b"],
             [r \in {"r1","r2"} |-> IF r = "r1" THEN "a" ELSE "b"],
             [r \in {"r1","r2"} |-> IF r = "r1" THEN "b" ELSE "a"] }
\* quantifiers
ASSUME (\E r \in RMs : st2[r] = "prepared") = TRUE
ASSUME (\A r \in RMs : st2[r] = "prepared") = FALSE
ASSUME (\A r \in {} : FALSE) = TRUE
ASSUME (\E r \in {} : TRUE) = FALSE
ASSUME (\E xyz \in RMs : st2[xyz] = "prepared") = (\E r \in RMs : st2[r] = "prepared")
\* quantifier order: the warehouse example
Items == {"book", "mug"}
Warehouses == {"East", "West"}
CanShip == [w \in Warehouses |-> IF w = "East" THEN {"book"} ELSE {"mug"}]
ASSUME \A i \in Items : \E w \in Warehouses : i \in CanShip[w]
ASSUME ~ \E w \in Warehouses : \A i \in Items : i \in CanShip[w]
\* group chat read positions
Members == {"Ada", "Ben"}
lastRead == [p \in Members |-> 0]
lastRead2 == [lastRead EXCEPT !["Ada"] = 2]
ASSUME lastRead2["Ada"] = 2 /\ lastRead2["Ben"] = 0
ASSUME lastRead2 \in [Members -> 0..3]
ASSUME (\A p \in Members : lastRead2[p] <= 3) = TRUE
====
