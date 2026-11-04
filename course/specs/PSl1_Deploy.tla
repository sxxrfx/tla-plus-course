---------------- MODULE PSl1_Deploy ----------------
\* Verification model for ps-l1 problem 4: two deploys, each test -> read live -> write if newer.
EXTENDS Integers
VARIABLES live, pcA, pcB, rA, rB

Init == live = 40 /\ pcA = "test" /\ pcB = "test" /\ rA = 0 /\ rB = 0

ATest  == pcA = "test"  /\ pcA' = "read"  /\ UNCHANGED <<live, pcB, rA, rB>>
ARead  == pcA = "read"  /\ pcA' = "write" /\ rA' = live /\ UNCHANGED <<live, pcB, rB>>
AWrite == pcA = "write" /\ pcA' = "done"  /\ live' = (IF 41 > rA THEN 41 ELSE live) /\ UNCHANGED <<pcB, rA, rB>>
BTest  == pcB = "test"  /\ pcB' = "read"  /\ UNCHANGED <<live, pcA, rA, rB>>
BRead  == pcB = "read"  /\ pcB' = "write" /\ rB' = live /\ UNCHANGED <<live, pcA, rA>>
BWrite == pcB = "write" /\ pcB' = "done"  /\ live' = (IF 42 > rB THEN 42 ELSE live) /\ UNCHANGED <<pcA, rA, rB>>

Next == ATest \/ ARead \/ AWrite \/ BTest \/ BRead \/ BWrite

NewestWins == (pcA = "done" /\ pcB = "done") => live = 42
=====================================================
