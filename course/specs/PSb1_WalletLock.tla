---------------- MODULE PSb1_WalletLock ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Clients
(*--algorithm WalletLock
variables balance = 100, holder = "none";
define
    AllDone == \A c \in Clients : pc[c] = "Done"
    NoLostUpdate == AllDone => balance = 100 + 10 * Cardinality(Clients)
end define;
process Refund \in Clients
variable local = 0;
begin
Select:  \* SELECT balance FROM accounts WHERE id = 1 FOR UPDATE
    await holder = "none";
    holder := self;
    local := balance;
Update:  \* UPDATE accounts SET balance = $1 WHERE id = 1
    balance := local + 10;
Commit:  \* COMMIT releases the row lock
    holder := "none";
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "87b9c644" /\ chksum(tla) = "51f928c7")
VARIABLES pc, balance, holder

(* define statement *)
AllDone == \A c \in Clients : pc[c] = "Done"
NoLostUpdate == AllDone => balance = 100 + 10 * Cardinality(Clients)

VARIABLE local

vars == << pc, balance, holder, local >>

ProcSet == (Clients)

Init == (* Global variables *)
        /\ balance = 100
        /\ holder = "none"
        (* Process Refund *)
        /\ local = [self \in Clients |-> 0]
        /\ pc = [self \in ProcSet |-> "Select"]

Select(self) == /\ pc[self] = "Select"
                /\ holder = "none"
                /\ holder' = self
                /\ local' = [local EXCEPT ![self] = balance]
                /\ pc' = [pc EXCEPT ![self] = "Update"]
                /\ UNCHANGED balance

Update(self) == /\ pc[self] = "Update"
                /\ balance' = local[self] + 10
                /\ pc' = [pc EXCEPT ![self] = "Commit"]
                /\ UNCHANGED << holder, local >>

Commit(self) == /\ pc[self] = "Commit"
                /\ holder' = "none"
                /\ pc' = [pc EXCEPT ![self] = "Done"]
                /\ UNCHANGED << balance, local >>

Refund(self) == Select(self) \/ Update(self) \/ Commit(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Clients: Refund(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
========================================================
