---------------- MODULE CacheSplit ----------------
EXTENDS Naturals
CONSTANTS SplitCheck, SplitInvalidate
ASSUME SplitCheck \in BOOLEAN /\ SplitInvalidate \in BOOLEAN
VARIABLES sourceVersion, cacheVersion, valid, fill, fillVersion, wrote
vars == <<sourceVersion, cacheVersion, valid, fill, fillVersion, wrote>>
\* fill: "none", "loading", or "checked". The check is always fenced here.
\* wrote: TRUE between a source write and its separate invalidation.

Init == /\ sourceVersion = 0
        /\ cacheVersion = 0
        /\ valid = FALSE
        /\ fill = "none"
        /\ fillVersion = 0
        /\ wrote = FALSE

BeginFill ==
    /\ fill = "none" /\ ~valid
    /\ fill' = "loading"
    /\ fillVersion' = sourceVersion
    /\ UNCHANGED <<sourceVersion, cacheVersion, valid, wrote>>

\* The write and its invalidation, in one step or two.
Write ==
    /\ sourceVersion < 2 /\ ~wrote
    /\ sourceVersion' = sourceVersion + 1
    /\ IF SplitInvalidate
          THEN wrote' = TRUE /\ UNCHANGED valid
          ELSE valid' = FALSE /\ UNCHANGED wrote
    /\ UNCHANGED <<cacheVersion, fill, fillVersion>>
Invalidate ==
    /\ wrote
    /\ wrote' = FALSE
    /\ valid' = FALSE
    /\ UNCHANGED <<sourceVersion, cacheVersion, fill, fillVersion>>

Publish ==
    /\ cacheVersion' = fillVersion
    /\ valid' = TRUE
    /\ fill' = "none"
    /\ UNCHANGED <<sourceVersion, fillVersion, wrote>>

\* The fence check and the publication, in one step or two.
FinishFill ==
    /\ fill = "loading" /\ ~SplitCheck
    /\ IF fillVersion = sourceVersion
          THEN Publish
          ELSE /\ fill' = "none"
               /\ UNCHANGED <<sourceVersion, cacheVersion, valid,
                              fillVersion, wrote>>
CheckFence ==
    /\ fill = "loading" /\ SplitCheck
    /\ fill' = IF fillVersion = sourceVersion THEN "checked" ELSE "none"
    /\ UNCHANGED <<sourceVersion, cacheVersion, valid, fillVersion, wrote>>
Install == fill = "checked" /\ Publish

Next == BeginFill \/ Write \/ Invalidate \/ FinishFill \/ CheckFence \/ Install
Spec == Init /\ [][Next]_vars
FreshWhenValid == valid => cacheVersion = sourceVersion
===================================================
