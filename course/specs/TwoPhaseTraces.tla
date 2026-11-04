---- MODULE TwoPhaseTraces ----
\* Invariants that are false on purpose: TLC's error trace is the run we want.
EXTENDS TwoPhase
NotAllCommitted == ~ \A r \in RM : rmState[r] = "committed"
P(r) == [type |-> "Prepared", rm |-> r]
NotAbortTrace == ~ /\ rmState["r1"] = "aborted" /\ P("r1") \in msgs
                   /\ rmState["r2"] = "aborted" /\ P("r2") \notin msgs
====
