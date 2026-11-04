---------------- MODULE PSb1_Seat ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Users
(*--algorithm Seat
variables bookings = {}, told = [u \in Users |-> "waiting"];
define
    OneBooking == Cardinality(bookings) <= 1
    Honest == \A u \in Users : told[u] = "confirmed" => u \in bookings
end define;
process User \in Users
variables free = FALSE, inserted = FALSE;
begin
Check:   \* SELECT 1 FROM bookings WHERE seat = '14C'
    free := (bookings = {});
Insert:  \* INSERT INTO bookings (seat, user_id) VALUES ('14C', ...)
    if free then
        bookings := bookings \cup {self};
        inserted := TRUE;
    end if;
Reply:   \* the page the user sees
    told[self] := IF inserted THEN "confirmed" ELSE "taken";
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "4c5ca9cc" /\ chksum(tla) = "79d99d0f")
VARIABLES pc, bookings, told

(* define statement *)
OneBooking == Cardinality(bookings) <= 1
Honest == \A u \in Users : told[u] = "confirmed" => u \in bookings

VARIABLES free, inserted

vars == << pc, bookings, told, free, inserted >>

ProcSet == (Users)

Init == (* Global variables *)
        /\ bookings = {}
        /\ told = [u \in Users |-> "waiting"]
        (* Process User *)
        /\ free = [self \in Users |-> FALSE]
        /\ inserted = [self \in Users |-> FALSE]
        /\ pc = [self \in ProcSet |-> "Check"]

Check(self) == /\ pc[self] = "Check"
               /\ free' = [free EXCEPT ![self] = (bookings = {})]
               /\ pc' = [pc EXCEPT ![self] = "Insert"]
               /\ UNCHANGED << bookings, told, inserted >>

Insert(self) == /\ pc[self] = "Insert"
                /\ IF free[self]
                      THEN /\ bookings' = (bookings \cup {self})
                           /\ inserted' = [inserted EXCEPT ![self] = TRUE]
                      ELSE /\ TRUE
                           /\ UNCHANGED << bookings, inserted >>
                /\ pc' = [pc EXCEPT ![self] = "Reply"]
                /\ UNCHANGED << told, free >>

Reply(self) == /\ pc[self] = "Reply"
               /\ told' = [told EXCEPT ![self] = IF inserted[self] THEN "confirmed" ELSE "taken"]
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED << bookings, free, inserted >>

User(self) == Check(self) \/ Insert(self) \/ Reply(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Users: User(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
==================================================
