------------------------------ MODULE PSl4_ModalCopied ------------------------------
VARIABLES open, focus, scrollLocked

TypeOK == /\ open \in {TRUE, FALSE}
          /\ focus \in {"page", "dialog"}
          /\ scrollLocked \in {TRUE, FALSE}

Init == /\ open = FALSE
        /\ focus = "page"
        /\ scrollLocked = FALSE

OpenDialog == /\ ~open
              /\ open' = TRUE
              /\ focus' = "dialog"
              /\ scrollLocked' = TRUE

CloseButton == /\ open
               /\ open' = FALSE
               /\ focus' = "page"
               /\ scrollLocked' = FALSE

PressEscape == /\ open
               /\ open' = FALSE
               /\ focus' = "page"
               /\ scrollLocked' = scrollLocked

Next == OpenDialog \/ CloseButton \/ PressEscape

LockMatches == scrollLocked = open
FocusInside == open => focus = "dialog"
=============================================================================
