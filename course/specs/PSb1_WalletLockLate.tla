---------------- MODULE PSb1_WalletLockLate ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Clients
(*--algorithm WalletLockLate
variables balance = 100, holder = "none";
define
    AllDone == \A c \in Clients : pc[c] = "Done"
    NoLostUpdate == AllDone => balance = 100 + 10 * Cardinality(Clients)
end define;
process Refund \in Clients
variable local = 0;
begin
Select:  \* plain SELECT first ...
    local := balance;
Lock:    \* ... then SELECT ... FOR UPDATE, ignoring the new value
    await holder = "none";
    holder := self;
Update:
    balance := local + 10;
Commit:
    holder := "none";
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "29e31423" /\ chksum(tla) = "bbf5c9c0")
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
                /\ local' = [local EXCEPT ![self] = balance]
                /\ pc' = [pc EXCEPT ![self] = "Lock"]
                /\ UNCHANGED << balance, holder >>

Lock(self) == /\ pc[self] = "Lock"
              /\ holder = "none"
              /\ holder' = self
              /\ pc' = [pc EXCEPT ![self] = "Update"]
              /\ UNCHANGED << balance, local >>

Update(self) == /\ pc[self] = "Update"
                /\ balance' = local[self] + 10
                /\ pc' = [pc EXCEPT ![self] = "Commit"]
                /\ UNCHANGED << holder, local >>

Commit(self) == /\ pc[self] = "Commit"
                /\ holder' = "none"
                /\ pc' = [pc EXCEPT ![self] = "Done"]
                /\ UNCHANGED << balance, local >>

Refund(self) == Select(self) \/ Lock(self) \/ Update(self) \/ Commit(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Clients: Refund(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
============================================================
