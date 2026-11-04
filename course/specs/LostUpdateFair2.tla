---------------- MODULE LostUpdateFair2 ----------------
EXTENDS Naturals
CONSTANT Workers
(*--algorithm LostUpdate
variables count = 0;
define
    AllDone == \A w \in Workers: pc[w] = "Done"
    NoLostUpdate == AllDone => count = 2
    Terminates == <>AllDone
end define;
fair process Worker \in Workers
variable local = 0;
begin
Read:
    local := count;
Write:
    count := local + 1;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "1a8bee09" /\ chksum(tla) = "839630d0")
VARIABLES pc, count

(* define statement *)
AllDone == \A w \in Workers: pc[w] = "Done"
NoLostUpdate == AllDone => count = 2
Terminates == <>AllDone

VARIABLE local

vars == << pc, count, local >>

ProcSet == (Workers)

Init == (* Global variables *)
        /\ count = 0
        (* Process Worker *)
        /\ local = [self \in Workers |-> 0]
        /\ pc = [self \in ProcSet |-> "Read"]

Read(self) == /\ pc[self] = "Read"
              /\ local' = [local EXCEPT ![self] = count]
              /\ pc' = [pc EXCEPT ![self] = "Write"]
              /\ count' = count

Write(self) == /\ pc[self] = "Write"
               /\ count' = local[self] + 1
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ local' = local

Worker(self) == Read(self) \/ Write(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Workers: Worker(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Workers : WF_vars(Worker(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
===================================================
