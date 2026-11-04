import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
g=lambda t:(t,"good");b=lambda t:(t,"bad")
two=lanes([("in transit",["{ }","{P1}","{ }","{C}","{ }",b("r2: none")]),("ever sent",["{ }","{P1}","{P1}","{P1,C}","{P1,C}",g("r2: C")])],
 "Value of msgs after each step in two models. If receiving removes messages, r2 has nothing to read after r1 consumes the Commit. If msgs is everything ever sent, Commit stays available to r2.",
 cols=["start","r1 sends","TM reads","TM sends C","r1 reads C","r2 reads?"],cell=88,labelw=86)
dup=lanes([("set",["{ }","{ }",g("{r1}"),g("{r1}"),g("no commit")]),("count",["0","0","1",b("2"),b("commits")])],
 "The TM reading r1's Prepared message twice. With a set, tmPrepared stays {r1} and the TM cannot commit. With a count it reaches 2 and the TM commits.",
 cols=["start","r1 sends","TM reads","reads again","TM then"],cell=96,labelw=60)
checkout=sequence(["Client","Server"],[("Client","Server","r7, attempt e1"),("note","Server","creates order: applied = {r7}","good"),("Server","Client","reply",{"lost":True,"tone":"bad"}),("note","Client","timeout: result unknown"),
 ("Client","Server","r7, attempt e2",{"dash":True}),("note","Server","r7 already applied: no new order","good"),("Server","Client","reply")],
 "The client sends r7 as attempt e1, the server creates an order, and the reply is lost. The client times out and retries as e2. The server sees r7 already applied, creates no new order, and replies.",gap=340,step=40)
FIGS={"two":(two,"P1 is r1's Prepared message and C is the Commit record. Reading from the top model removes; reading from the bottom one doesn't."),
"dup":(dup,"The same duplicate read under two TM designs. A set absorbs it. A count turns it into a false vote."),
"checkout":(checkout,"A lost reply leaves the client unsure. The retry is safe only because the server recognizes the logical request.")}
