---------------- MODULE TicketPCSplit ----------------
EXTENDS Integers, FiniteSets
CONSTANT Buyers
(*--algorithm Ticket
variables remaining = 1, booked = {};
define
    Safe == Cardinality(booked) <= 1
end define;
process Buyer \in Buyers
begin
Check:
    if remaining > 0 then
Take:
        remaining := remaining - 1;
        booked := booked \cup {self};
    end if;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "7a56571d" /\ chksum(tla) = "2868ea8d")
VARIABLES pc, remaining, booked

(* define statement *)
Safe == Cardinality(booked) <= 1


vars == << pc, remaining, booked >>

ProcSet == (Buyers)

Init == (* Global variables *)
        /\ remaining = 1
        /\ booked = {}
        /\ pc = [self \in ProcSet |-> "Check"]

Check(self) == /\ pc[self] = "Check"
               /\ IF remaining > 0
                     THEN /\ pc' = [pc EXCEPT ![self] = "Take"]
                     ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED << remaining, booked >>

Take(self) == /\ pc[self] = "Take"
              /\ remaining' = remaining - 1
              /\ booked' = (booked \cup {self})
              /\ pc' = [pc EXCEPT ![self] = "Done"]

Buyer(self) == Check(self) \/ Take(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Buyers: Buyer(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
=================================================
