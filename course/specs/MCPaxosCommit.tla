---- MODULE MCPaxosCommit ----
EXTENDS PaxosCommit, TLC
CONSTANTS a1, a2, a3, r1, r2
Acceptors == {a1, a2, a3}
RMs == {r1, r2}
Majorities == {{a1, a2}, {a1, a3}, {a2, a3}}
Sym == Permutations(Acceptors) \cup Permutations(RMs)
====
