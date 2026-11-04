---- MODULE SetOps ----
EXTENDS Integers, FiniteSets
VARIABLE x
Init == x = 0
Next == x' = x
ASSUME SUBSET {"a", "b"} = {{}, {"a"}, {"b"}, {"a", "b"}}
ASSUME Cardinality(SUBSET {"a1", "a2", "a3"}) = 8
ASSUME {1, 2} \subseteq {1, 2, 3}
ASSUME {"a1", "a2"} \cap {"a2", "a3"} = {"a2"}
ASSUME {"a1", "a2"} \cup {"a2", "a3"} = {"a1", "a2", "a3"}
ASSUME (10..20) \ (1..14) = 15..20
ASSUME {0, 1} \ {0} = {1}
ASSUME {n \in 1..6 : n > 4} = {5, 6}
ASSUME {n^2 : n \in 1..3} = {1, 4, 9}
Acceptor == {"a1", "a2", "a3"}
Majority == {Q \in SUBSET Acceptor : Cardinality(Q) = 2}
ASSUME Majority = {{"a1", "a2"}, {"a1", "a3"}, {"a2", "a3"}}
ASSUME \A MS1, MS2 \in Majority : MS1 \cap MS2 # {}
ASSUME Majority \subseteq SUBSET Acceptor
Five == {"A","B","C","D","E"}
Sized(k) == {Q \in SUBSET Five : Cardinality(Q) = k}
ASSUME \A r \in Sized(3), w \in Sized(3) : r \cap w # {}
ASSUME \E r \in Sized(2), w \in Sized(3) : r \cap w = {}
====
