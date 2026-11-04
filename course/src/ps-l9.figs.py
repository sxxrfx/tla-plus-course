import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
g=lambda t:(t,"good");b=lambda t:(t,"bad");a=lambda t:(t,"accent")
jobs=lanes([("queue",["<<j3, j2>>","<<j3, j2>>","<<j3, j2>>","<<j3, j2>>"]),("done",["{j1}","{j1}","{j1}","{j1}"]),("beat",["0","1","0","1"]),
 ("Process",[g("enabled"),g("enabled"),g("enabled"),g("enabled")]),("step taken",["Heartbeat","Heartbeat","Heartbeat","Heartbeat"])],
 "TLC's loop under FairNext: the queue holds j3 and j2, done holds j1, and beat alternates between 0 and 1 by Heartbeat steps. Process is enabled in every state of the loop and never taken.",
 cols=["state 5","state 6","state 5","state 6"],cell=110,labelw=90)
rw=lanes([("readers",["{q2}","{q1, q2}","{q1}","{q1, q2}","{q2}"]),("writer",["waiting","waiting","waiting","waiting","waiting"]),
 ("WriteAcquire",[b("disabled"),b("disabled"),b("disabled"),b("disabled"),b("disabled")]),("step into it",["q2 acquires","q1 acquires","q2 releases","q2 acquires","q1 releases"])],
 "TLC's loop under SFSpec with two queries: readers goes {q2}, {q1, q2}, {q1}, {q1, q2}, then back to {q2}. It is never empty, so WriteAcquire is disabled in every state, while each query releases infinitely often.",
 cols=["state 3","state 4","state 5","state 6","back to 3"],cell=110,labelw=100)
reorder=sequence(["sensor A","gateway B"],[("gateway B","sensor A","ack: bit 1"),
 ("note","sensor A","sends <<d1, 1>>: delayed"),("note","sensor A","ack matches: new value <<d1, 0>>"),
 ("sensor A","gateway B","<<d1, 0>>",{"tone":"good"}),("note","gateway B","bit 0 differs: BVar = <<d1, 0>>","good"),
 ("sensor A","gateway B","old <<d1, 1>>, out of order",{"tone":"bad","dash":True}),("note","gateway B","bit 1 differs: BVar = <<d1, 1>>","bad")],
 "TLC's trace with Reorder TRUE. The gateway acknowledges bit 1. The sensor sends d1 with bit 1, which stays in the channel, then receives the ack and picks d1 with bit 0, which it sends. The gateway receives the newer message first and accepts it, then receives the old copy with bit 1 and accepts it as new.",gap=330,step=42)
loss=lanes([("Abort for hotel",[g("in net"),g("in net"),b("lost"),"none",g("in net")]),("RMRcvAbort(hotel)",["enabled","enabled",b("disabled"),b("disabled"),"enabled"]),
 ("hotel",["prepared","prepared","prepared","prepared","prepared"]),("step into it",["TMResend","Lose, resend","Lose","TMResend(car)","TMResend"])],
 "One lap of TLC's loop under WFSpec. An Abort for hotel is in the network from state 7 to state 12, is lost in state 13, is absent in state 14, and is sent again on the way back to state 7. Hotel stays prepared throughout; its receive action is enabled, then disabled, around the loop.",
 cols=["state 7","8 to 12","state 13","state 14","back to 7"],cell=112,labelw=136)
FIGS={"jobs":(jobs,"Every step is a Next step, so WF_vars(Next) is satisfied, but the worker never processes j3."),
"rw":(rw,"The two queries overlap, so the table is never free. Neither weak nor strong fairness says anything about an action that is never enabled."),
"reorder":(reorder,"With one bit, a stale copy of the previous value looks exactly like the next new value."),
"loss":(loss,"Hotel's receive action keeps flickering: enabled by each resend, disabled by each loss. Weak fairness lets it wait forever; strong fairness doesn't.")}
