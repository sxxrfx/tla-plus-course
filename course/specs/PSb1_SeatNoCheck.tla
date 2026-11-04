---------------- MODULE PSb1_SeatNoCheck ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Users
(*--algorithm SeatNoCheck
variables bookings = {}, told = [u \in Users |-> "waiting"];
define
    OneBooking == Cardinality(bookings) <= 1
    Honest == \A u \in Users : told[u] = "confirmed" => u \in bookings
end define;
process User \in Users
variables inserted = FALSE;
begin
Insert:  \* INSERT ... ; the unique constraint rejects a second row
    if bookings = {} then
        bookings := bookings \cup {self};
        inserted := TRUE;
    end if;
Reply:
    told[self] := IF inserted THEN "confirmed" ELSE "taken";
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "81053184" /\ chksum(tla) = "f2edf142")
VARIABLES pc, bookings, told

(* define statement *)
OneBooking == Cardinality(bookings) <= 1
Honest == \A u \in Users : told[u] = "confirmed" => u \in bookings

VARIABLE inserted

vars == << pc, bookings, told, inserted >>

ProcSet == (Users)

Init == (* Global variables *)
        /\ bookings = {}
        /\ told = [u \in Users |-> "waiting"]
        (* Process User *)
        /\ inserted = [self \in Users |-> FALSE]
        /\ pc = [self \in ProcSet |-> "Insert"]

Insert(self) == /\ pc[self] = "Insert"
                /\ IF bookings = {}
                      THEN /\ bookings' = (bookings \cup {self})
                           /\ inserted' = [inserted EXCEPT ![self] = TRUE]
                      ELSE /\ TRUE
                           /\ UNCHANGED << bookings, inserted >>
                /\ pc' = [pc EXCEPT ![self] = "Reply"]
                /\ told' = told

Reply(self) == /\ pc[self] = "Reply"
               /\ told' = [told EXCEPT ![self] = IF inserted[self] THEN "confirmed" ELSE "taken"]
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED << bookings, inserted >>

User(self) == Insert(self) \/ Reply(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Users: User(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
=========================================================
