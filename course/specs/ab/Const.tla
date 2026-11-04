-------------------------------- MODULE Const -------------------------------
EXTENDS Integers, Sequences, TLC
Remove(i, seq) ==
  [j \in 1..(Len(seq) - 1) |-> IF j < i THEN seq[j] ELSE seq[j + 1]]
RECURSIVE RemoveX(_)
RemoveX(seq) == IF seq = <<>>
                  THEN <<>>
                  ELSE IF Head(seq) = "X"
                         THEN RemoveX(Tail(seq))
                         ELSE <<Head(seq)>> \o RemoveX(Tail(seq))
ASSUME PrintT(Remove(3, <<1, 2, 3, 4>>))
ASSUME PrintT((1..3) \X {"a", "b"})
ASSUME PrintT(RemoveX(<<"Tom", "X", "Dick", "Harry", "X">>))
ASSUME PrintT([i \in 1..4 |-> i^2])
ASSUME PrintT(Tail(<<"Fred", "Mary", "Ted">>))
ASSUME PrintT(Head(<<"Fred", "Mary", "Ted">>))
ASSUME PrintT(Append(<<3, 2, 1>>, "a"))
ASSUME PrintT(<<3, 2, 1>> \o <<"a", "b">>)
ASSUME PrintT(Len(<<3, 2, 1>>))
ASSUME PrintT(1..0)
ASSUME \A P, Q \in BOOLEAN : (P => Q) = ((IF P THEN Q ELSE TRUE) /\ ((~Q) => (~P)))
VARIABLE unused
Init == unused = 0
Next == UNCHANGED unused
=============================================================================
