import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
g=lambda t:(t,"good");b=lambda t:(t,"bad")
quorum=lanes([("A",[g("v2"),None,None]),("B",["v1",b("asked: v1"),b("asked: v1")]),("C",[g("v2"),None,None]),
 ("D",[g("v2"),None,g("asked: v2")]),("E",["v1",b("asked: v1"),b("asked: v1")]),("result",[None,b("max = 1"),g("max = 2")])],
 "Five replicas after the acknowledged write: A, C and D hold version 2, B and E version 1. A read of B and E returns 1. A read of B, D and E includes D and returns 2.",
 cols=["after Ack","read {B, E}","read {B, D, E}"],cell=130,labelw=60)
dcs=regions([(10,30,330,175,"Two DCs: 3 + 2","muted"),(24,62,180,86,"DC A (lost)","bad"),(216,62,110,86,"DC B"),
 (350,30,330,175,"Three DCs: 2 + 2 + 1","muted"),(362,62,112,86,"DC A (lost)","bad"),(484,62,112,86,"DC B"),(606,62,64,86,"DC C")],
 "Two layouts of five members. Left: DC A holds n1, n2, n3 and DC B holds n4, n5; losing DC A leaves two members, short of a quorum of three. Right: DCs of two, two and one members; losing DC A leaves three, a quorum.",
 width=690,height=215,
 notes=[(64,112,"n1"),(114,112,"n2"),(164,112,"n3"),(248,112,"n4"),(294,112,"n5"),
  (175,180,"2 left: no quorum","bad"),(400,112,"n1"),(440,112,"n2"),(522,112,"n3"),(562,112,"n4"),(638,112,"n5"),
  (515,180,"3 left: {n3, n4, n5}","good")])
election=sequence(["s1","s2","s3"],[("note","s1","timeout: term 1, votes for s1"),("note","s1","restart: forgets the vote","bad"),
 ("note","s2","timeout: term 1, votes for s2"),("s1","s2","vote, term 1"),("note","s2","leader of term 1: {s1, s2}","good"),
 ("s3","s1","vote, term 1",{"tone":"bad"}),("note","s1","leader of term 1: {s1, s3}","bad")],
 "TLC's trace. s1 times out into term 1 and votes for itself, then restarts and forgets that vote. s2 times out into term 1, s1 votes for s2, and s2 wins with s1 and s2. s3 votes for s1, and s1 wins with its old self-vote and s3's vote.",step=40)
compare=lanes([("2PC, TM down",["3 prepared",b("TM: gone"),b("never")]),("Paxos, a3 down",["3 prepared",g("a1, a2"),g("Commit")]),
 ("Paxos, a1 only",["3 prepared",b("a1 alone"),b("never")]),("Paxos, 1 acceptor",["3 prepared",b("tm: gone"),b("never")])],
 "Four runs. Two-phase commit with the TM crashed: the votes' only memory is gone, no decision. Paxos Commit with a3 crashed: a1 and a2 hold the votes and Commit is sent. With only a1 up, or with a single acceptor that is down, nothing is ever decided.",
 cols=["RMs","who holds the votes","decision"],cell=170,labelw=140)
FIGS={"quorum":(quorum,"The R = 2 read in TLC's trace asks only B and E, the two replicas the write never reached. Any read of three must include A, C or D."),
"dcs":(dcs,"Losing the large DC of a 3 + 2 layout leaves no quorum. In 2 + 2 + 1 every DC holds at most two members, so any single loss leaves three."),
"election":(election,"The two majorities, {s1, s2} and {s1, s3}, overlap in s1, as they must. s1 voted in both because the restart erased its first vote."),
"compare":(compare,"A decision needs a majority of the vote-holders alive. In two-phase commit that majority is one process, the TM.")}
