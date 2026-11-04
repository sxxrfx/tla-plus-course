---------------------------- MODULE PSl9_RWLock -----------------------------
\* A table lock: queries take it shared, a schema migration takes it
\* exclusive. writer is "idle", "waiting" or "writing".
CONSTANT Reader
VARIABLES readers, writer
vars == <<readers, writer>>
Init == readers = {} /\ writer = "idle"

ReadAcquire(r) == /\ r \notin readers
                  /\ writer # "writing"
                  /\ readers' = readers \cup {r}
                  /\ writer' = writer
\* The fix: a waiting writer also blocks new readers.
ReadAcquireQueued(r) == writer = "idle" /\ ReadAcquire(r)
ReadRelease(r) == /\ r \in readers
                  /\ readers' = readers \ {r}
                  /\ writer' = writer
Request      == writer = "idle"    /\ writer' = "waiting" /\ readers' = readers
WriteAcquire == /\ writer = "waiting"
                /\ readers = {}
                /\ writer' = "writing"
                /\ readers' = readers
WriteRelease == writer = "writing" /\ writer' = "idle"    /\ readers' = readers

Next   == Request \/ WriteAcquire \/ WriteRelease
          \/ \E r \in Reader : ReadAcquire(r) \/ ReadRelease(r)
QNext  == Request \/ WriteAcquire \/ WriteRelease
          \/ \E r \in Reader : ReadAcquireQueued(r) \/ ReadRelease(r)

Releases == WF_vars(WriteRelease) /\ \A r \in Reader : WF_vars(ReadRelease(r))
WFSpec  == Init /\ [][Next]_vars  /\ Releases /\ WF_vars(WriteAcquire)
SFSpec  == Init /\ [][Next]_vars  /\ Releases /\ SF_vars(WriteAcquire)
QWFSpec == Init /\ [][QNext]_vars /\ Releases /\ WF_vars(WriteAcquire)

WriterProgress == (writer = "waiting") ~> (writer = "writing")
=============================================================================
