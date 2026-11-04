---- MODULE PSl5_FailoverExprs ----
EXTENDS Integers, TLC, FiniteSets
Replicas == {"db1", "db2", "db3"}
lag == [r \in Replicas |-> IF r = "db1" THEN 0 ELSE IF r = "db2" THEN 4 ELSE 90]
status == [r \in Replicas |-> IF r = "db3" THEN "catchup" ELSE "streaming"]
ASSUME PrintT(<<"E1", \A r \in Replicas : status[r] = "streaming" => lag[r] =< 5>>)
ASSUME PrintT(<<"E2", \E r \in Replicas : \A s \in Replicas : lag[r] =< lag[s]>>)
ASSUME PrintT(<<"E3", \A s \in Replicas : \E r \in Replicas : lag[r] < lag[s]>>)
ASSUME PrintT(<<"E4", \A r \in Replicas : lag[r] =< 5>>)
ASSUME PrintT(<<"E5", \A r \in {} : lag[r] > 100>>)
ASSUME PrintT(<<"E6", Cardinality([Replicas -> {"streaming", "catchup", "down"}])>>)
ASSUME PrintT(<<"E7", [status EXCEPT !["db3"] = "streaming"] = [r \in Replicas |-> "streaming"]>>)
ASSUME PrintT(<<"E8", DOMAIN lag = Replicas>>)
ASSUME PrintT(<<"E9", Cardinality([Replicas -> {"streaming", "down"}])>>)
====
