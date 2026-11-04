---------------- MODULE PSb2_WalletProof ----------------
EXTENDS PSb1_WalletLock, TLAPS
ASSUME ClientsOK == IsFiniteSet(Clients) /\ "none" \notin Clients

Money == Nat
Paid == {c \in Clients : pc[c] \in {"Commit", "Done"}}
TypeOK == /\ balance \in Money
          /\ local \in [Clients -> Money]
          /\ holder \in Clients \cup {"none"}
          /\ pc \in [Clients -> {"Select", "Update", "Commit", "Done"}]
LockHeld  == \A c \in Clients : (pc[c] \in {"Update", "Commit"}) <=> (holder = c)
FreshRead == \A c \in Clients : pc[c] = "Update" => local[c] = balance
Ledger    == balance = 100 + 10 * Cardinality(Paid)
Inv == TypeOK /\ LockHeld /\ FreshRead /\ Ledger

LEMMA CardEmpty == Cardinality({}) = 0
    PROOF OMITTED
LEMMA CardSubset == \A S, T : IsFiniteSet(T) /\ S \subseteq T => IsFiniteSet(S)
    PROOF OMITTED
LEMMA CardAdd == \A S, x : IsFiniteSet(S) /\ x \notin S =>
    Cardinality(S \cup {x}) = Cardinality(S) + 1
    PROOF OMITTED

THEOREM Safety == Spec => []NoLostUpdate
<1>1. Init => Inv
    BY ClientsOK, CardEmpty DEF Init, ProcSet, Inv, TypeOK, Money,
       LockHeld, FreshRead, Ledger, Paid
<1>2. Inv /\ [Next]_vars => Inv'
    <2> SUFFICES ASSUME Inv, [Next]_vars PROVE Inv'
        OBVIOUS
    <2>1. ASSUME NEW self \in Clients, Select(self) PROVE Inv'
        \* holder goes from "none" to self, and local[self] gets balance.
        BY <2>1, ClientsOK DEF Select, Inv, TypeOK, Money, LockHeld,
           FreshRead, Ledger, Paid
    <2>2. ASSUME NEW self \in Clients, Update(self) PROVE Inv'
        \* FreshRead gives balance' = balance + 10, and self joins Paid.
        <3>1. self \notin Paid /\ Paid' = Paid \cup {self}
            BY <2>2 DEF Update, Inv, TypeOK, Paid
        <3>2. IsFiniteSet(Paid)
            BY ClientsOK, CardSubset DEF Paid
        <3>3. Cardinality(Paid') = Cardinality(Paid) + 1
            BY <3>1, <3>2, CardAdd
        <3>4. QED
            BY <2>2, <3>3 DEF Update, Inv, TypeOK, Money, LockHeld,
               FreshRead, Ledger
    <2>3. ASSUME NEW self \in Clients, Commit(self) PROVE Inv'
        \* holder returns to "none"; Commit and Done are both in Paid.
        BY <2>3, ClientsOK DEF Commit, Inv, TypeOK, LockHeld, FreshRead,
           Ledger, Paid
    <2>4. CASE Terminating \/ UNCHANGED vars
        BY <2>4 DEF Terminating, vars, Inv, TypeOK, LockHeld, FreshRead,
           Ledger, Paid
    <2>5. QED
        BY <2>1, <2>2, <2>3, <2>4 DEF Next, Refund
<1>3. Inv => NoLostUpdate
    \* When all are Done, Paid = Clients.
    BY DEF Inv, Ledger, Paid, NoLostUpdate, AllDone
<1>4. QED
    BY <1>1, <1>2, <1>3, PTL DEF Spec

\* For TLC only: a finite stand-in for Money, and the weaker candidates.
MoneyModel == {0, 100, 110, 120}
NoFresh == TypeOK /\ LockHeld /\ Ledger
NoLock  == TypeOK /\ FreshRead /\ Ledger
MoneyModel3 == {0, 100, 110, 120, 130}
=========================================================
