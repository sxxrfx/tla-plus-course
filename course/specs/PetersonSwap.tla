---------------- MODULE PetersonSwap ----------------
EXTENDS Integers
(*--algorithm Peterson
variables flag = [p \in {0, 1} |-> FALSE], turn = 0;
define
    MutualExclusion == ~(pc[0] = "cs" /\ pc[1] = "cs")
    NoStarvation == \A p \in {0, 1}: (pc[p] = "wait") ~> (pc[p] = "cs")
end define;
fair process P \in {0, 1}
begin
ncs:  while TRUE do
sett:   turn := 1 - self;
setf:   flag[self] := TRUE;
wait:   await ~flag[1 - self] \/ turn = self;
cs:     skip;
exit:   flag[self] := FALSE;
      end while;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "87ae54c" /\ chksum(tla) = "2f6baea1")
VARIABLES pc, flag, turn

(* define statement *)
MutualExclusion == ~(pc[0] = "cs" /\ pc[1] = "cs")
NoStarvation == \A p \in {0, 1}: (pc[p] = "wait") ~> (pc[p] = "cs")


vars == << pc, flag, turn >>

ProcSet == ({0, 1})

Init == (* Global variables *)
        /\ flag = [p \in {0, 1} |-> FALSE]
        /\ turn = 0
        /\ pc = [self \in ProcSet |-> "ncs"]

ncs(self) == /\ pc[self] = "ncs"
             /\ pc' = [pc EXCEPT ![self] = "sett"]
             /\ UNCHANGED << flag, turn >>

sett(self) == /\ pc[self] = "sett"
              /\ turn' = 1 - self
              /\ pc' = [pc EXCEPT ![self] = "setf"]
              /\ flag' = flag

setf(self) == /\ pc[self] = "setf"
              /\ flag' = [flag EXCEPT ![self] = TRUE]
              /\ pc' = [pc EXCEPT ![self] = "wait"]
              /\ turn' = turn

wait(self) == /\ pc[self] = "wait"
              /\ ~flag[1 - self] \/ turn = self
              /\ pc' = [pc EXCEPT ![self] = "cs"]
              /\ UNCHANGED << flag, turn >>

cs(self) == /\ pc[self] = "cs"
            /\ TRUE
            /\ pc' = [pc EXCEPT ![self] = "exit"]
            /\ UNCHANGED << flag, turn >>

exit(self) == /\ pc[self] = "exit"
              /\ flag' = [flag EXCEPT ![self] = FALSE]
              /\ pc' = [pc EXCEPT ![self] = "ncs"]
              /\ turn' = turn

P(self) == ncs(self) \/ sett(self) \/ setf(self) \/ wait(self) \/ cs(self)
              \/ exit(self)

Next == (\E self \in {0, 1}: P(self))

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {0, 1} : WF_vars(P(self))

\* END TRANSLATION 
=================================================
