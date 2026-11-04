---------------- MODULE Chat ----------------
EXTENDS Integers
VARIABLES draft, pending, lastSent, selected

Init == /\ draft = "hello"
        /\ pending = 0
        /\ lastSent = ""
        /\ selected = "room7"

Send == /\ draft /= ""
        /\ pending' = pending + 1
        /\ lastSent' = draft
        /\ draft' = ""
        /\ selected' = selected

Next == Send
=============================================
