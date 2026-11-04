-------------------------------- MODULE Prec --------------------------------
EXTENDS Integers, TLC
ASSUME PrintT(1..3 \X {"a", "b"})
VARIABLE unused
Init == unused = 0
Next == UNCHANGED unused
=============================================================================
