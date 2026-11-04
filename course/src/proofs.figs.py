import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
tree=graph({"t":(340,30,"Spec => []NoOverselling","accent"),
 "a":(70,120,"<1>1\nInit => Inv"),"b":(270,120,"<1>2\nInv /\\ [Next] => Inv'"),"c":(475,120,"<1>3\nInv => Safe"),"d":(625,120,"<1>4\nQED: PTL"),
 "e":(145,220,"<2>1\nReserve(b)"),"f":(300,220,"<2>2\nstutter"),"g":(435,220,"<2>3\nQED"),
 "l1":(70,310,"CardAdd","muted"),"l2":(220,310,"remaining - 1 + 1","muted")},
 [("t","a"),("t","b"),("t","c"),("t","d"),("b","e"),("b","f"),("b","g"),("e","l1"),("e","l2")],
 "The proof tree. The theorem splits into three obligations and a temporal QED. The step case splits by action: Reserve, which uses the card-add lemma and arithmetic, and stuttering.")
good=lanes([("guard",["3","5",("5","good"),]),("no guard",["3","5",("4","bad")])],"Cache version over three arrivals. With the guard it stays at 5 when version 4 arrives late. Without it, it rolls back to 4.",cols=["Init","v5 arrives","v4 arrives"],cell=84,labelw=90)
rest=lanes([("volatile",["3","4",("3","bad")]),("durable",["3","3","3"])],"Restart trace: version 4 accepted in memory only, then a restart reloads durable version 3, rolling back the visible version.",cols=["Init","Accept(4)","Restart"],cell=84,labelw=90)
FIGS={"tree":(tree,"The structure of the proof below. Read it top down: each node is proved from its children. The two leaves at the bottom are what the <code>Reserve</code> case rests on: a lemma about finite sets, and arithmetic."),
"good":(good,"<code>cacheVersion</code> across the same arrival order. The bottom row is TLC’s counterexample after the guard is removed."),
"rest":(rest,"TLC’s counterexample to monotonicity when accepted versions are not persisted before they are shown.")}
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-prf-{k}\"").replace("#dg-a)",f"#dg-a-prf-{k})"),v[1]) for k,v in FIGS.items()}
