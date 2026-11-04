---------------- MODULE InventoryProof ----------------
EXTENDS Inventory, TLAPS
Inv == /\ TypeOK
       /\ IsFiniteSet(booked)
       /\ Conservation
LEMMA CardEmpty == IsFiniteSet({}) /\ Cardinality({}) = 0
    PROOF OMITTED
LEMMA CardNat == \A S : IsFiniteSet(S) => Cardinality(S) \in Nat
    PROOF OMITTED
LEMMA CardAdd == \A S, x : IsFiniteSet(S) /\ x \notin S =>
    /\ IsFiniteSet(S \cup {x})
    /\ Cardinality(S \cup {x}) = Cardinality(S) + 1
    PROOF OMITTED
THEOREM Safety == Spec => []NoOverselling
<1>1. Init => Inv
    BY CardEmpty DEF Init, Inv, TypeOK, Conservation
<1>2. Inv /\ [Next]_vars => Inv'
    <2> SUFFICES ASSUME Inv, [Next]_vars PROVE Inv'
        OBVIOUS
    <2>1. ASSUME NEW b \in Buyers, Reserve(b) PROVE Inv'
        BY <2>1, CardAdd, CardNat
        DEF Reserve, Inv, TypeOK, Conservation
    <2>2. CASE UNCHANGED vars
        BY <2>2 DEF vars, Inv, TypeOK, Conservation
    <2>3. QED
        BY <2>1, <2>2 DEF Next
<1>3. Inv => NoOverselling
    BY CardNat DEF Inv, TypeOK, Conservation, NoOverselling
<1>4. QED
    BY <1>1, <1>2, <1>3, PTL DEF Spec
=======================================================
