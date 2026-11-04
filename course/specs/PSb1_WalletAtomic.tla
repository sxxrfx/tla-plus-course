---------------- MODULE PSb1_WalletAtomic ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Clients
(*--algorithm WalletAtomic
variables balance = 100;
define
    AllDone == \A c \in Clients : pc[c] = "Done"
    NoLostUpdate == AllDone => balance = 100 + 10 * Cardinality(Clients)
end define;
process Refund \in Clients
begin
Update:  \* UPDATE accounts SET balance = balance + 10 WHERE id = 1
    balance := balance + 10;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "aa5beaed" /\ chksum(tla) = "6bb1e6a9")
VARIABLES pc, balance

(* define statement *)
AllDone == \A c \in Clients : pc[c] = "Done"
NoLostUpdate == AllDone => balance = 100 + 10 * Cardinality(Clients)


vars == << pc, balance >>

ProcSet == (Clients)

Init == (* Global variables *)
        /\ balance = 100
        /\ pc = [self \in ProcSet |-> "Update"]

Update(self) == /\ pc[self] = "Update"
                /\ balance' = balance + 10
                /\ pc' = [pc EXCEPT ![self] = "Done"]

Refund(self) == Update(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Clients: Refund(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
==========================================================
