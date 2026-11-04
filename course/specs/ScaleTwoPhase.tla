---------------- MODULE ScaleTwoPhase ----------------
EXTENDS TLC
CONSTANT RM
VARIABLES rmState, tmState, tmPrepared, msgs
Messages == [type : {"Prepared"}, rm : RM] \cup [type : {"Commit", "Abort"}]
Init == /\ rmState = [r \in RM |-> "working"]
        /\ tmState = "init"
        /\ tmPrepared = {}
        /\ msgs = {}
TMRcvPrepared(r) == /\ tmState = "init"
                    /\ [type |-> "Prepared", rm |-> r] \in msgs
                    /\ tmPrepared' = tmPrepared \cup {r}
                    /\ UNCHANGED <<rmState, tmState, msgs>>
TMCommit == /\ tmState = "init"
            /\ tmPrepared = RM
            /\ tmState' = "committed"
            /\ msgs' = msgs \cup {[type |-> "Commit"]}
            /\ UNCHANGED <<rmState, tmPrepared>>
TMAbort == /\ tmState = "init"
           /\ tmState' = "aborted"
           /\ msgs' = msgs \cup {[type |-> "Abort"]}
           /\ UNCHANGED <<rmState, tmPrepared>>
RMPrepare(r) == /\ rmState[r] = "working"
                /\ rmState' = [rmState EXCEPT ![r] = "prepared"]
                /\ msgs' = msgs \cup {[type |-> "Prepared", rm |-> r]}
                /\ UNCHANGED <<tmState, tmPrepared>>
RMChooseToAbort(r) == /\ rmState[r] = "working"
                      /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
                      /\ UNCHANGED <<tmState, tmPrepared, msgs>>
RMRcvCommitMsg(r) == /\ [type |-> "Commit"] \in msgs
                     /\ rmState' = [rmState EXCEPT ![r] = "committed"]
                     /\ UNCHANGED <<tmState, tmPrepared, msgs>>
RMRcvAbortMsg(r) == /\ [type |-> "Abort"] \in msgs
                    /\ rmState' = [rmState EXCEPT ![r] = "aborted"]
                    /\ UNCHANGED <<tmState, tmPrepared, msgs>>
Next == \/ TMCommit \/ TMAbort
        \/ \E r \in RM: TMRcvPrepared(r) \/ RMPrepare(r) \/ RMChooseToAbort(r)
                        \/ RMRcvCommitMsg(r) \/ RMRcvAbortMsg(r)
Consistent == \A r1, r2 \in RM: ~(rmState[r1] = "aborted" /\ rmState[r2] = "committed")
Perms == Permutations(RM)
======================================================
