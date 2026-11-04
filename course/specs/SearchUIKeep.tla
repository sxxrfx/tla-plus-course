---------------- MODULE SearchUIKeep ----------------
EXTENDS Naturals
CONSTANTS MaxGen, NoSelection
VARIABLES generation, inflight, shownGen, results, selected
vars == <<generation, inflight, shownGen, results, selected>>
Rows(g) == {<<g, 1>>, <<g, 2>>}
Init == /\ generation = 0
        /\ inflight = {}
        /\ shownGen = 0
        /\ results = {}
        /\ selected = NoSelection
Input ==
    /\ generation < MaxGen
    /\ LET g == generation + 1 IN
         /\ generation' = g
         /\ inflight' = inflight \cup {[gen |-> g, rows |-> Rows(g)]}
    /\ UNCHANGED <<shownGen, results, selected>>
ShowResponse(r) ==
    /\ r \in inflight
    /\ r.gen = generation
    /\ shownGen' = r.gen
    /\ results' = r.rows
    /\ UNCHANGED selected
    /\ inflight' = inflight \ {r}
    /\ UNCHANGED generation
DropStale(r) ==
    /\ r \in inflight
    /\ r.gen # generation
    /\ inflight' = inflight \ {r}
    /\ UNCHANGED <<generation, shownGen, results, selected>>
Select(row) ==
    /\ row \in results
    /\ selected' = row
    /\ UNCHANGED <<generation, inflight, shownGen, results>>
Next == \/ Input
        \/ \E r \in inflight: ShowResponse(r) \/ DropStale(r)
        \/ \E row \in results: Select(row)
Spec == Init /\ [][Next]_vars
Status == CASE shownGen = 0 -> "empty"
            [] shownGen = generation -> "ready"
            [] shownGen < generation -> "loading"
SelectionValid == selected = NoSelection \/ selected \in results
SettlesOnLatest ==
    inflight = {} /\ generation > 0 => shownGen = generation
StatusKnown == Status \in {"empty", "ready", "loading"}
=================================================
