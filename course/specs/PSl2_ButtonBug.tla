----------------- MODULE PSl2_ButtonBug -----------------
EXTENDS Integers
VARIABLES phase, disabled, inflight

Init == /\ phase = "idle"
        /\ (disabled = TRUE \/ disabled = FALSE)
        /\ inflight = 0

Click   == /\ ~disabled
           /\ ~(phase = "success")
           /\ phase' = "loading"
           /\ inflight' = inflight + 1
           /\ disabled' = disabled

Resolve == /\ phase = "loading"
           /\ phase' = "success"
           /\ inflight' = inflight - 1
           /\ disabled' = disabled

Reject  == /\ phase = "loading"
           /\ phase' = "error"
           /\ inflight' = inflight - 1
           /\ disabled' = disabled

Reset   == /\ phase = "success"
           /\ phase' = "idle"
           /\ inflight' = inflight
           /\ disabled' = disabled

Toggle  == /\ disabled' = ~disabled
           /\ phase' = phase
           /\ inflight' = inflight

Next == Click \/ Resolve \/ Reject \/ Reset \/ Toggle

OneRequest == inflight \in 0..1
LoadingOK  == (phase = "loading") => (inflight = 1)
======================================================
