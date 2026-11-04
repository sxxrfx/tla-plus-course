---------------- MODULE AtomicIncrement ----------------
EXTENDS Naturals
CONSTANT Workers
(*--algorithm LostUpdate
variables count = 0;
define
    AllDone == \A w \in Workers: pc[w] = "Done"
    NoLostUpdate == AllDone => count = 2
end define;
process Worker \in Workers
begin
Increment:
    count := count + 1;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "f7cb63f0" /\ chksum(tla) = "e35f7dbb")
VARIABLES pc, count

(* define statement *)
AllDone == \A w \in Workers: pc[w] = "Done"
NoLostUpdate == AllDone => count = 2


vars == << pc, count >>

ProcSet == (Workers)

Init == (* Global variables *)
        /\ count = 0
        /\ pc = [self \in ProcSet |-> "Increment"]

Increment(self) == /\ pc[self] = "Increment"
                   /\ count' = count + 1
                   /\ pc' = [pc EXCEPT ![self] = "Done"]

Worker(self) == Increment(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Workers: Worker(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
===================================================
