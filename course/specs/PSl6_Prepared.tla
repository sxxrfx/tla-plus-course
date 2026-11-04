---------------------------- MODULE PSl6_Prepared ----------------------------
CONSTANTS RM,            \* the Postgres databases in the transaction
          DBA            \* the DBA's rule: "never", "blind", or "checklog"
VARIABLES
  rmState,               \* rmState[r] is the state of r's transaction
  tmState,               \* the app server: "init", "done", or "down"
  tmPrepared,            \* the databases the app server knows are prepared
  msgs,                  \* every message ever sent
  report                 \* a session on "payments" blocked on a row lock
vars == <<rmState, tmState, tmPrepared, msgs, report>>

Messages == [type : {"Prepared"}, rm : RM] \cup [type : {"Commit", "Abort"}]

TypeOK ==
  /\ rmState \in [RM -> {"working", "prepared", "committed", "aborted"}]
  /\ tmState \in {"init", "done", "down"}
  /\ tmPrepared \subseteq RM
  /\ msgs \subseteq Messages
  /\ report \in {"waiting", "done"}

Init ==
  /\ rmState = [r \in RM |-> "working"]
  /\ tmState = "init"
  /\ tmPrepared = {}
  /\ msgs = {}
  /\ report = "waiting"
-----------------------------------------------------------------------------
TMRcvPrepared(r) ==
  /\ tmState = "init"
  /\ [type |-> "Prepared", rm |-> r] \in msgs
  /\ tmPrepared' = tmPrepared \cup {r}
  /\ UNCHANGED <<rmState, tmState, msgs, report>>

TMCommit ==                                  \* COMMIT PREPARED on each database
  /\ tmState = "init"
  /\ tmPrepared = RM
  /\ tmState' = "done"
  /\ msgs' = msgs \cup {[type |-> "Commit"]}
  /\ UNCHANGED <<rmState, tmPrepared, report>>

TMAbort ==                                   \* ROLLBACK PREPARED on each database
  /\ tmState = "init"
  /\ tmState' = "done"
  /\ msgs' = msgs \cup {[type |-> "Abort"]}
  /\ UNCHANGED <<rmState, tmPrepared, report>>

TMCrash ==                                   \* the app server dies and stays down
  /\ tmState # "down"
  /\ tmState' = "down"
  /\ UNCHANGED <<rmState, tmPrepared, msgs, report>>

RMPrepare(r) ==                \* the app server's PREPARE TRANSACTION succeeds
  /\ tmState = "init"
  /\ rmState[r] = "working"
  /\ rmState' = [rmState EXCEPT ![r] = "prepared"]
  /\ msgs' = msgs \cup {[type |-> "Prepared", rm |-> r]}
  /\ UNCHANGED <<tmState, tmPrepared, report>>

RMChooseToAbort(r) ==          \* an error, or the app server's session is lost
  /\ rmState[r] = "working"
  /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs, report>>

RMRcvCommitMsg(r) ==
  /\ [type |-> "Commit"] \in msgs
  /\ rmState' = [rmState EXCEPT ![r] = "committed"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs, report>>

RMRcvAbortMsg(r) ==
  /\ [type |-> "Abort"] \in msgs
  /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs, report>>

\* The report's UPDATE waits for the row lock until the transaction ends.
ReportRuns ==
  /\ report = "waiting"
  /\ rmState["payments"] \in {"committed", "aborted"}
  /\ report' = "done"
  /\ UNCHANGED <<rmState, tmState, tmPrepared, msgs>>

\* ROLLBACK PREPARED by hand while the app server is down. "blind": anything
\* still prepared. "checklog": only if the app server's log has no Commit.
DBARollback(r) ==
  /\ \/ DBA = "blind"
     \/ DBA = "checklog" /\ [type |-> "Commit"] \notin msgs
  /\ tmState = "down"
  /\ rmState[r] = "prepared"
  /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
  /\ UNCHANGED <<tmState, tmPrepared, msgs, report>>

\* An intended stop: every transaction has ended and the report has run.
Finished ==
  /\ \A r \in RM : rmState[r] \in {"committed", "aborted"}
  /\ report = "done"
  /\ UNCHANGED vars
-----------------------------------------------------------------------------
Next ==
  \/ TMCommit \/ TMAbort \/ TMCrash \/ ReportRuns \/ Finished
  \/ \E r \in RM : \/ TMRcvPrepared(r) \/ RMPrepare(r) \/ RMChooseToAbort(r)
                   \/ RMRcvCommitMsg(r) \/ RMRcvAbortMsg(r) \/ DBARollback(r)
-----------------------------------------------------------------------------
INSTANCE TCommit
=============================================================================
