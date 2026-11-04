---------------- MODULE PSb1_RedisLockCrash ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Workers
(*--algorithm RedisLockCrash
variables balance = 100, lock = "none", committed = 0;
define
    NoLostUpdate == balance = 100 + 10 * committed
    Holding == {w \in Workers : pc[w] \in {"Read", "Write", "Release"}}
    MutualExclusion == Cardinality(Holding) <= 1
end define;
fair process Worker \in Workers
variable local = 0;
begin
Acquire:  \* SET wallet:7:lock <worker id> NX
    await lock = "none";
    lock := self;
Read:
    local := balance;
Write:
    balance := local + 10;
    committed := committed + 1;   \* bookkeeping for the check only
Release:  \* DEL wallet:7:lock, unless the worker crashes first
    either lock := "none";
    or     skip;      \* crashed: the key stays set
    end either;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "46fec66d" /\ chksum(tla) = "34a14661")
VARIABLES pc, balance, lock, committed

(* define statement *)
NoLostUpdate == balance = 100 + 10 * committed
Holding == {w \in Workers : pc[w] \in {"Read", "Write", "Release"}}
MutualExclusion == Cardinality(Holding) <= 1

VARIABLE local

vars == << pc, balance, lock, committed, local >>

ProcSet == (Workers)

Init == (* Global variables *)
        /\ balance = 100
        /\ lock = "none"
        /\ committed = 0
        (* Process Worker *)
        /\ local = [self \in Workers |-> 0]
        /\ pc = [self \in ProcSet |-> "Acquire"]

Acquire(self) == /\ pc[self] = "Acquire"
                 /\ lock = "none"
                 /\ lock' = self
                 /\ pc' = [pc EXCEPT ![self] = "Read"]
                 /\ UNCHANGED << balance, committed, local >>

Read(self) == /\ pc[self] = "Read"
              /\ local' = [local EXCEPT ![self] = balance]
              /\ pc' = [pc EXCEPT ![self] = "Write"]
              /\ UNCHANGED << balance, lock, committed >>

Write(self) == /\ pc[self] = "Write"
               /\ balance' = local[self] + 10
               /\ committed' = committed + 1
               /\ pc' = [pc EXCEPT ![self] = "Release"]
               /\ UNCHANGED << lock, local >>

Release(self) == /\ pc[self] = "Release"
                 /\ \/ /\ lock' = "none"
                    \/ /\ TRUE
                       /\ lock' = lock
                 /\ pc' = [pc EXCEPT ![self] = "Done"]
                 /\ UNCHANGED << balance, committed, local >>

Worker(self) == Acquire(self) \/ Read(self) \/ Write(self) \/ Release(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Workers: Worker(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Workers : WF_vars(Worker(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
=======================================================
