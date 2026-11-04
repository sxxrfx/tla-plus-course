---------------- MODULE PSb1_RedisLockLoop ----------------
CONSTANT Workers
(*--algorithm RedisLockLoop
variable lock = "none";
define
    NoStarvation == \A w \in Workers :
                      (pc[w] = "Acquire") ~> (pc[w] = "Work")
end define;
fair process Worker \in Workers
begin
Loop:
    while TRUE do
Acquire:  \* SET wallet:7:lock <worker id> NX, retried until it succeeds
        await lock = "none";
        lock := self;
Work:
        skip;               \* read and write the balance
Release:
        lock := "none";
    end while;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "3eda7e27" /\ chksum(tla) = "20e5d9be")
VARIABLES pc, lock

(* define statement *)
NoStarvation == \A w \in Workers :
                  (pc[w] = "Acquire") ~> (pc[w] = "Work")


vars == << pc, lock >>

ProcSet == (Workers)

Init == (* Global variables *)
        /\ lock = "none"
        /\ pc = [self \in ProcSet |-> "Loop"]

Loop(self) == /\ pc[self] = "Loop"
              /\ pc' = [pc EXCEPT ![self] = "Acquire"]
              /\ lock' = lock

Acquire(self) == /\ pc[self] = "Acquire"
                 /\ lock = "none"
                 /\ lock' = self
                 /\ pc' = [pc EXCEPT ![self] = "Work"]

Work(self) == /\ pc[self] = "Work"
              /\ TRUE
              /\ pc' = [pc EXCEPT ![self] = "Release"]
              /\ lock' = lock

Release(self) == /\ pc[self] = "Release"
                 /\ lock' = "none"
                 /\ pc' = [pc EXCEPT ![self] = "Loop"]

Worker(self) == Loop(self) \/ Acquire(self) \/ Work(self) \/ Release(self)

Next == (\E self \in Workers: Worker(self))

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Workers : WF_vars(Worker(self))

\* END TRANSLATION 
\* Strong fairness for each worker's Acquire, on top of fair process.
SpecSF == Spec /\ \A w \in Workers : SF_vars(Acquire(w))
===========================================================
