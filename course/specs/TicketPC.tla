---------------- MODULE TicketPC ----------------
EXTENDS Integers, FiniteSets
CONSTANT Buyers
(*--algorithm Ticket
variables remaining = 1, booked = {};
define
    Safe == Cardinality(booked) <= 1
end define;
process Buyer \in Buyers
begin
Reserve:
    if remaining > 0 then
        remaining := remaining - 1;
        booked := booked \cup {self};
    end if;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "fd22394b" /\ chksum(tla) = "4843a1cb")
VARIABLES pc, remaining, booked

(* define statement *)
Safe == Cardinality(booked) <= 1


vars == << pc, remaining, booked >>

ProcSet == (Buyers)

Init == (* Global variables *)
        /\ remaining = 1
        /\ booked = {}
        /\ pc = [self \in ProcSet |-> "Reserve"]

Reserve(self) == /\ pc[self] = "Reserve"
                 /\ IF remaining > 0
                       THEN /\ remaining' = remaining - 1
                            /\ booked' = (booked \cup {self})
                       ELSE /\ TRUE
                            /\ UNCHANGED << remaining, booked >>
                 /\ pc' = [pc EXCEPT ![self] = "Done"]

Buyer(self) == Reserve(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Buyers: Buyer(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
=================================================
