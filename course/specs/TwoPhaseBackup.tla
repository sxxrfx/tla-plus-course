---- MODULE TwoPhaseBackup ----
\* TwoPhase plus a backup TM that takes over and aborts when it wrongly
\* believes the primary TM has failed.
EXTENDS TwoPhase
VARIABLE backupDone
BackupInit == TPInit /\ backupDone = FALSE
BackupAbort == /\ ~backupDone
               /\ backupDone' = TRUE
               /\ msgs' = msgs \cup {[type |-> "Abort"]}
               /\ UNCHANGED <<rmState, tmState, tmPrepared>>
BackupNext == (TPNext /\ UNCHANGED backupDone) \/ BackupAbort
====
