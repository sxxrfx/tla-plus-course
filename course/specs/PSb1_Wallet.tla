---------------- MODULE PSb1_Wallet ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Clients
(*--algorithm Wallet
variables balance = 100;
define
    AllDone == \A c \in Clients : pc[c] = "Done"
    NoLostUpdate == AllDone => balance = 100 + 10 * Cardinality(Clients)
end define;
process Refund \in Clients
variable local = 0;
begin
Select:  \* SELECT balance FROM accounts WHERE id = 1
    local := balance;
Update:  \* UPDATE accounts SET balance = $1 WHERE id = 1, with $1 = local + 10
    balance := local + 10;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "19d07fc2" /\ chksum(tla) = "9f52a1b0")
VARIABLES pc, balance

(* define statement *)
AllDone == \A c \in Clients : pc[c] = "Done"
NoLostUpdate == AllDone => balance = 100 + 10 * Cardinality(Clients)

VARIABLE local

vars == << pc, balance, local >>

ProcSet == (Clients)

Init == (* Global variables *)
        /\ balance = 100
        (* Process Refund *)
        /\ local = [self \in Clients |-> 0]
        /\ pc = [self \in ProcSet |-> "Select"]

Select(self) == /\ pc[self] = "Select"
                /\ local' = [local EXCEPT ![self] = balance]
                /\ pc' = [pc EXCEPT ![self] = "Update"]
                /\ UNCHANGED balance

Update(self) == /\ pc[self] = "Update"
                /\ balance' = local[self] + 10
                /\ pc' = [pc EXCEPT ![self] = "Done"]
                /\ local' = local

Refund(self) == Select(self) \/ Update(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Clients: Refund(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====================================================
