---- MODULE HideTest ----
VARIABLE v
Hidden == \EE h : (h = 0 /\ [][h' = h /\ v' = v]_<<h,v>>)
Init == v = 0
Next == v' = v
=========================
