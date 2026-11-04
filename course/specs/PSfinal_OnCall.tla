---------------- MODULE PSfinal_OnCall ----------------
EXTENDS Naturals, FiniteSets
CONSTANTS Doctors, Isolation
ASSUME Isolation \in {"Snapshot", "Serializable"}
(*--algorithm OnCall
variables onCall = [d \in Doctors |-> TRUE],  \* committed rows
          version = [d \in Doctors |-> 0];     \* committed row versions
define
    AtLeastOneOnCall == \E d \in Doctors : onCall[d]
end define;
process Tx \in Doctors
variables snap = [d \in Doctors |-> TRUE],     \* this transaction's snapshot
          snapVersion = [d \in Doctors |-> 0];
begin
Begin:
    snap := onCall;
    snapVersion := version;
Check:
    if Cardinality({d \in Doctors : snap[d]}) >= 2 then
Commit:
        if Isolation = "Serializable" /\ version # snapVersion then
            skip;   \* abort: a row it read has changed since its snapshot
        else
            onCall[self] := FALSE;
            version[self] := version[self] + 1;
        end if;
    end if;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "9213e8d7" /\ chksum(tla) = "c0852bd6")
VARIABLES pc, onCall, version

(* define statement *)
AtLeastOneOnCall == \E d \in Doctors : onCall[d]

VARIABLES snap, snapVersion

vars == << pc, onCall, version, snap, snapVersion >>

ProcSet == (Doctors)

Init == (* Global variables *)
        /\ onCall = [d \in Doctors |-> TRUE]
        /\ version = [d \in Doctors |-> 0]
        (* Process Tx *)
        /\ snap = [self \in Doctors |-> [d \in Doctors |-> TRUE]]
        /\ snapVersion = [self \in Doctors |-> [d \in Doctors |-> 0]]
        /\ pc = [self \in ProcSet |-> "Begin"]

Begin(self) == /\ pc[self] = "Begin"
               /\ snap' = [snap EXCEPT ![self] = onCall]
               /\ snapVersion' = [snapVersion EXCEPT ![self] = version]
               /\ pc' = [pc EXCEPT ![self] = "Check"]
               /\ UNCHANGED << onCall, version >>

Check(self) == /\ pc[self] = "Check"
               /\ IF Cardinality({d \in Doctors : snap[self][d]}) >= 2
                     THEN /\ pc' = [pc EXCEPT ![self] = "Commit"]
                     ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED << onCall, version, snap, snapVersion >>

Commit(self) == /\ pc[self] = "Commit"
                /\ IF Isolation = "Serializable" /\ version # snapVersion[self]
                      THEN /\ TRUE
                           /\ UNCHANGED << onCall, version >>
                      ELSE /\ onCall' = [onCall EXCEPT ![self] = FALSE]
                           /\ version' = [version EXCEPT ![self] = version[self] + 1]
                /\ pc' = [pc EXCEPT ![self] = "Done"]
                /\ UNCHANGED << snap, snapVersion >>

Tx(self) == Begin(self) \/ Check(self) \/ Commit(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Doctors: Tx(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
=======================================================
