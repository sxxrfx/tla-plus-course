---------------- MODULE Cache ----------------
EXTENDS Naturals
CONSTANT Fence
ASSUME Fence \in BOOLEAN
VARIABLES sourceVersion, cacheVersion, valid, loading, fillVersion
vars == <<sourceVersion, cacheVersion, valid, loading, fillVersion>>

Init == /\ sourceVersion = 0
        /\ cacheVersion = 0
        /\ valid = FALSE
        /\ loading = FALSE
        /\ fillVersion = 0

BeginFill ==
    /\ ~loading /\ ~valid
    /\ loading' = TRUE
    /\ fillVersion' = sourceVersion
    /\ UNCHANGED <<sourceVersion, cacheVersion, valid>>

WriteAndInvalidate ==
    /\ sourceVersion < 2
    /\ sourceVersion' = sourceVersion + 1
    /\ valid' = FALSE
    /\ UNCHANGED <<cacheVersion, loading, fillVersion>>

FinishFill ==
    /\ loading
    /\ loading' = FALSE
    /\ IF ~Fence \/ fillVersion = sourceVersion
          THEN /\ cacheVersion' = fillVersion
               /\ valid' = TRUE
          ELSE UNCHANGED <<cacheVersion, valid>>
    /\ UNCHANGED <<sourceVersion, fillVersion>>

Next == BeginFill \/ WriteAndInvalidate \/ FinishFill
Spec == Init /\ [][Next]_vars

TypeOK == /\ sourceVersion \in 0..2
          /\ cacheVersion \in 0..2
          /\ fillVersion \in 0..2
          /\ valid \in BOOLEAN
          /\ loading \in BOOLEAN
FreshWhenValid == valid => cacheVersion = sourceVersion
================================================
