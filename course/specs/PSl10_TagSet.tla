---------------- MODULE PSl10_TagSet ----------------
CONSTANT Tags
VARIABLE tags
Init == tags = {}
Add(t) == /\ t \notin tags
          /\ tags' = tags \cup {t}
Next == \E t \in Tags : Add(t)
Spec == Init /\ [][Next]_tags
=====================================================
