---------------------------- MODULE PSl8_Dialog -----------------------------
\* A design-system confirm dialog whose Confirm button runs an async request.
VARIABLE dialog
Status == {"closed", "open", "submitting", "error"}
Init == dialog = "closed"
Open    == dialog = "closed"     /\ dialog' = "open"
Cancel  == dialog \in {"open", "error"} /\ dialog' = "closed"
Confirm == dialog = "open"       /\ dialog' = "submitting"
Succeed == dialog = "submitting" /\ dialog' = "closed"
Fail    == dialog = "submitting" /\ dialog' = "error"
Retry   == dialog = "error"      /\ dialog' = "submitting"
Next == Open \/ Cancel \/ Confirm \/ Succeed \/ Fail \/ Retry
Spec == Init /\ [][Next]_dialog

TypeOK == dialog \in Status
AlwaysTypeOK == []TypeOK
\* While a request is in flight the form never reappears.
NoReopenWhileBusy == [][dialog = "submitting" => dialog' # "open"]_dialog
\* An error is shown only right after a request.
ErrorOnlyAfterSubmit == [][dialog' = "error" => dialog = "submitting"]_dialog
\* Once closed, the dialog stays closed (a wrong claim, for comparison).
ClosedIsFinal == [][dialog = "closed" => dialog' = "closed"]_dialog
=============================================================================
