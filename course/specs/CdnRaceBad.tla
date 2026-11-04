---------------- MODULE CdnRaceBad ----------------
EXTENDS Naturals
CONSTANT MaxVersion
VARIABLES origin, cached, inflight, floor
vars == <<origin, cached, inflight, floor>>
Init == /\ origin = 1
        /\ cached = 1          \* 0 means no cached copy
        /\ inflight = {}
        /\ floor = 0           \* invalidated through this version
Fetch == /\ origin \notin inflight
         /\ inflight' = inflight \cup {origin}
         /\ UNCHANGED <<origin, cached, floor>>
Publish == /\ origin < MaxVersion
           /\ origin' = origin + 1
           /\ UNCHANGED <<cached, inflight, floor>>
Invalidate == /\ floor < origin - 1
              /\ floor' = origin - 1
              /\ cached' = IF cached <= floor' THEN 0 ELSE cached
              /\ UNCHANGED <<origin, inflight>>
Fill(v) == /\ v \in inflight
           /\ cached' = v
           /\ inflight' = inflight \ {v}
           /\ UNCHANGED <<origin, floor>>
Discard(v) == /\ v \in inflight
              /\ v <= floor
              /\ inflight' = inflight \ {v}
              /\ UNCHANGED <<origin, cached, floor>>
Next == Fetch \/ Publish \/ Invalidate
        \/ \E v \in inflight: Fill(v) \/ Discard(v)
Spec == Init /\ [][Next]_vars
NotResurrected == cached = 0 \/ cached > floor
Fresh == cached = 0 \/ cached = origin
================================================
