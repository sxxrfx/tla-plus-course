---------------- MODULE PSb1_Ring ----------------
EXTENDS Naturals, Sequences
CONSTANTS N, K      \* N slots; the producer sends 1, 2, ..., K
(*--algorithm Ring
variables buf = [i \in 0..(N - 1) |-> 0], head = 0, tail = 0, got = <<>>;
define
    InOrder == \A i \in 1..Len(got) : got[i] = i
end define;
process Producer = "prod"
variable next = 1;
begin
P1: while next <= K do
P2:   await tail - head < N;        \* full: wait (backpressure)
      buf[tail % N] := next;        \* write the slot
P3:   tail := tail + 1;             \* publish it
      next := next + 1;
    end while;
end process;
process Consumer = "cons"
begin
C1: while Len(got) < K do
C2:   await tail > head;            \* empty: wait
      got := Append(got, buf[head % N]);
C3:   head := head + 1;             \* free the slot
    end while;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "89a767d" /\ chksum(tla) = "ae7dff3f")
VARIABLES pc, buf, head, tail, got

(* define statement *)
InOrder == \A i \in 1..Len(got) : got[i] = i

VARIABLE next

vars == << pc, buf, head, tail, got, next >>

ProcSet == {"prod"} \cup {"cons"}

Init == (* Global variables *)
        /\ buf = [i \in 0..(N - 1) |-> 0]
        /\ head = 0
        /\ tail = 0
        /\ got = <<>>
        (* Process Producer *)
        /\ next = 1
        /\ pc = [self \in ProcSet |-> CASE self = "prod" -> "P1"
                                        [] self = "cons" -> "C1"]

P1 == /\ pc["prod"] = "P1"
      /\ IF next <= K
            THEN /\ pc' = [pc EXCEPT !["prod"] = "P2"]
            ELSE /\ pc' = [pc EXCEPT !["prod"] = "Done"]
      /\ UNCHANGED << buf, head, tail, got, next >>

P2 == /\ pc["prod"] = "P2"
      /\ tail - head < N
      /\ buf' = [buf EXCEPT ![tail % N] = next]
      /\ pc' = [pc EXCEPT !["prod"] = "P3"]
      /\ UNCHANGED << head, tail, got, next >>

P3 == /\ pc["prod"] = "P3"
      /\ tail' = tail + 1
      /\ next' = next + 1
      /\ pc' = [pc EXCEPT !["prod"] = "P1"]
      /\ UNCHANGED << buf, head, got >>

Producer == P1 \/ P2 \/ P3

C1 == /\ pc["cons"] = "C1"
      /\ IF Len(got) < K
            THEN /\ pc' = [pc EXCEPT !["cons"] = "C2"]
            ELSE /\ pc' = [pc EXCEPT !["cons"] = "Done"]
      /\ UNCHANGED << buf, head, tail, got, next >>

C2 == /\ pc["cons"] = "C2"
      /\ tail > head
      /\ got' = Append(got, buf[head % N])
      /\ pc' = [pc EXCEPT !["cons"] = "C3"]
      /\ UNCHANGED << buf, head, tail, next >>

C3 == /\ pc["cons"] = "C3"
      /\ head' = head + 1
      /\ pc' = [pc EXCEPT !["cons"] = "C1"]
      /\ UNCHANGED << buf, tail, got, next >>

Consumer == C1 \/ C2 \/ C3

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == Producer \/ Consumer
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
\* Refinement: the occupied slots, oldest first, are the abstract queue.
Queued == [i \in 1..(tail - head) |-> buf[(head + i - 1) % N]]
Q == INSTANCE PSb1_Queue WITH Values <- 1..K, Capacity <- N, q <- Queued
QueueSpec == Q!Spec
==================================================
