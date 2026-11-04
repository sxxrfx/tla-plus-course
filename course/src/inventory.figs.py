import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
_bad={"tone":"bad"}
split=graph({
 "ii":(60,135,"idle, idle\n1 left"),
 "ci":(205,80,"checked, idle\n1 left"),"ic":(205,190,"idle, checked\n1 left"),
 "di":(355,30,"done, idle\n0 left"),"cc":(355,135,"checked, checked\n1 left"),"id":(355,240,"idle, done\n0 left"),
 "dc":(505,80,"done, checked\n0 left"),"cd":(505,190,"checked, done\n0 left"),
 "dd":(650,135,"done, done\n-1 left","bad"),
},[("ii","ci","A"),("ii","ic","B"),("ci","di","A"),("ci","cc","B",{"lx":14,"ly":-10}),("ic","cc","A",{"lx":14,"ly":10}),("ic","id","B"),
  ("cc","dc","A",{"tone":"bad","lx":-14,"ly":-10}),("cc","cd","B",{"tone":"bad","lx":-14,"ly":10}),("dc","dd","B",_bad),("cd","dd","A",_bad)],
 "All 9 reachable states of the split model. Each node shows buyer A's stage, buyer B's stage and the tickets remaining. Once both buyers have checked, every path ends at minus one ticket.")
atomic=graph({"s":(70,65,"1 left\nbooked {}"),"a":(320,30,"0 left\nbooked {A}","good"),"b":(320,100,"0 left\nbooked {B}","good")},
 [("s","a","Reserve(A)"),("s","b","Reserve(B)")],"The 3 reachable states of the atomic model. One buyer reserves and the other is then disabled.")
hold=lanes([("remaining",["1","0","0","1","1","0"]),("held",["{}","{A}","{A}","{}","{}",("{B}","bad")]),
 ("paying",["{}","{}","{A}","{A}","{}","{}"]),("confirmed",["{}","{}","{}","{}","{A}",("{A}","bad")])],
 "TLC's trace for the hold bug: A reserves, starts paying and expires, the late payment confirms A, and then B reserves the same ticket.",
 cols=["Init","Reserve A","Pay starts","Expire A","Late pay A","Reserve B"],cell=92)
FIGS={"split":(split,"The split model, drawn from its 9 reachable states. Each node reads: A’s stage, B’s stage, tickets left. An edge is one step by the buyer named on it. The red edges start at the state where both buyers hold a stale check."),
"atomic":(atomic,"The atomic model has 3 reachable states. After either reservation the other buyer’s guard is false, so there is no path to a double sale."),
"hold":(hold,"TLC’s 5-step trace for the hold bug. In the last column, B holds the ticket and A is confirmed for it.")}
# Markers live per SVG: hidden lessons would otherwise hold the only #dg-a that url() resolves to, and arrowheads vanish.
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-inventory-{k}\"").replace("#dg-a)",f"#dg-a-inventory-{k})"),v[1]) for k,v in FIGS.items()}
