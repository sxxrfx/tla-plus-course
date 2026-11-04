--------------------------- MODULE PSl7_Election ----------------------------
\* Leader election in the style of Raft, with votes as messages. Logs are
\* left out. A server that times out moves to a higher term, votes for
\* itself and asks for votes; it is leader of a term once a majority voted
\* for it in that term. Restart models a crash and reboot.
EXTENDS Integers
CONSTANTS Server, Majority, Term
ASSUME \A MS1, MS2 \in Majority : MS1 \cap MS2 # {}
None == "none"
VARIABLES term,      \* term[s]: the highest term s has seen
          votedFor,  \* votedFor[s]: whom s voted for in term[s], or None
          msgs,      \* every message ever sent
          leaders    \* every [srv, term] pair that has won an election
vars == <<term, votedFor, msgs, leaders>>

Init == /\ term = [s \in Server |-> 0]
        /\ votedFor = [s \in Server |-> None]
        /\ msgs = {}
        /\ leaders = {}

Timeout(s, t) ==
  /\ t > term[s]
  /\ term' = [term EXCEPT ![s] = t]
  /\ votedFor' = [votedFor EXCEPT ![s] = s]
  /\ msgs' = msgs \cup {[type |-> "request", term |-> t, from |-> s],
                        [type |-> "vote", term |-> t, from |-> s, to |-> s]}
  /\ UNCHANGED leaders

\* s grants its vote for term m.term at most once, unless it forgot.
Grant(s) ==
  \E m \in msgs :
    /\ m.type = "request"
    /\ \/ m.term > term[s]
       \/ m.term = term[s] /\ votedFor[s] \in {None, m.from}
    /\ term' = [term EXCEPT ![s] = m.term]
    /\ votedFor' = [votedFor EXCEPT ![s] = m.from]
    /\ msgs' = msgs \cup {[type |-> "vote", term |-> m.term, from |-> s, to |-> m.from]}
    /\ UNCHANGED leaders

BecomeLeader(s) ==
  /\ \E MS \in Majority :
       \A v \in MS : [type |-> "vote", term |-> term[s], from |-> v, to |-> s] \in msgs
  /\ leaders' = leaders \cup {[srv |-> s, term |-> term[s]]}
  /\ UNCHANGED <<term, votedFor, msgs>>

\* The process restarts. term is on disk; votedFor was kept only in memory.
Restart(s) ==
  /\ votedFor' = [votedFor EXCEPT ![s] = None]
  /\ UNCHANGED <<term, msgs, leaders>>

Next == \E s \in Server : \/ \E t \in Term : Timeout(s, t)
                          \/ Grant(s) \/ BecomeLeader(s) \/ Restart(s)
\* Both fields on disk: a restart then changes nothing in this model.
NextDurable == \E s \in Server : \/ \E t \in Term : Timeout(s, t)
                                 \/ Grant(s) \/ BecomeLeader(s)

OneLeaderPerTerm == \A l1, l2 \in leaders : l1.term = l2.term => l1.srv = l2.srv
=============================================================================
