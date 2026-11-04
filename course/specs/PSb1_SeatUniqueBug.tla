---------------- MODULE PSb1_SeatUniqueBug ----------------
EXTENDS Naturals, FiniteSets
CONSTANT Users
(*--algorithm SeatUniqueBug
variables bookings = {}, told = [u \in Users |-> "waiting"];
define
    OneBooking == Cardinality(bookings) <= 1
    Honest == \A u \in Users : told[u] = "confirmed" => u \in bookings
end define;
process User \in Users
variables free = FALSE, inserted = FALSE;
begin
Check:
    free := (bookings = {});
Insert:  \* UNIQUE (seat): the INSERT fails if a row for 14C exists
    if free then
        if bookings = {} then
            bookings := bookings \cup {self};
            inserted := TRUE;
        end if;
    end if;
Reply:
    told[self] := IF free THEN "confirmed" ELSE "taken";
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "b542f913" /\ chksum(tla) = "859146c0")
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
                      THEN /\ IF bookings = {}
                                 THEN /\ bookings' = (bookings \cup {self})
                                      /\ inserted' = [inserted EXCEPT ![self] = TRUE]
                                 ELSE /\ TRUE
                                      /\ UNCHANGED << bookings, inserted >>
                      ELSE /\ TRUE
                           /\ UNCHANGED << bookings, inserted >>
                /\ pc' = [pc EXCEPT ![self] = "Reply"]
                /\ UNCHANGED << told, free >>

Reply(self) == /\ pc[self] = "Reply"
               /\ told' = [told EXCEPT ![self] = IF free[self] THEN "confirmed" ELSE "taken"]
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
========================================================
