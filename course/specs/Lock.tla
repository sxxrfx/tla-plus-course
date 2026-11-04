---------------- MODULE Lock ----------------
EXTENDS Naturals, FiniteSets
CONSTANTS Processes, NoOwner
ASSUME NoOwner \notin Processes
VARIABLES owner, pc
vars == <<owner, pc>>
Init == /\ owner = NoOwner
        /\ pc = [p \in Processes |-> "outside"]
Request(p) ==
    /\ pc[p] = "outside"
    /\ pc' = [pc EXCEPT ![p] = "waiting"]
    /\ UNCHANGED owner
Acquire(p) ==
    /\ owner = NoOwner
    /\ pc[p] = "waiting"
    /\ owner' = p
    /\ pc' = [pc EXCEPT ![p] = "critical"]
Release(p) ==
    /\ owner = p
    /\ owner' = NoOwner
    /\ pc' = [pc EXCEPT ![p] = "outside"]
Next == \E p \in Processes: Request(p) \/ Acquire(p) \/ Release(p)
Spec == Init /\ [][Next]_vars
MutualExclusion ==
    Cardinality({p \in Processes : pc[p] = "critical"}) <= 1
OwnerAgrees == \A p \in Processes: pc[p] = "critical" => owner = p
\* Three fairness assumptions, weakest first.
ReleaseFair == \A p \in Processes: WF_vars(Release(p))
AggregateWF == ReleaseFair
    /\ WF_vars(\E p \in Processes: Acquire(p))
PerProcessWF == ReleaseFair
    /\ \A p \in Processes: WF_vars(Acquire(p))
PerProcessSF == ReleaseFair
    /\ \A p \in Processes: SF_vars(Acquire(p))
SpecAggregate == Spec /\ AggregateWF
SpecWF == Spec /\ PerProcessWF
SpecSF == Spec /\ PerProcessSF
NoStarvation ==
    \A p \in Processes: (pc[p] = "waiting") ~> (pc[p] = "critical")
=============================================
