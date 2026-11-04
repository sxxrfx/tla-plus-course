import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
lost=lanes([("pc[A]",["Select","Update","Update","Done","Done"]),("pc[B]",["Select","Select","Update","Update","Done"]),
 ("local[A]",["0","100","100","100","100"]),("local[B]",["0","0","100","100","100"]),("balance",["100","100","100","110",("110","bad")])],
 "TLC's trace for the two refunds. Both clients read 100 before either writes, so both write 110 and one refund of 10 is lost.",
 cols=["Init","Select(A)","Select(B)","Update(A)","Update(B)"],labelw=100,cell=96)
seat=sequence(["Ada","Postgres","Ben"],[
 ("Ada","Postgres","SELECT 14C"),("Postgres","Ada","no row"),
 ("Ben","Postgres","SELECT 14C"),("Postgres","Ben","no row"),
 ("Ada","Postgres","INSERT 14C"),("note","Postgres","row for Ada"),
 ("Ben","Postgres","INSERT 14C"),("Postgres","Ben","unique violation",{"tone":"bad"}),
 ("note","Ben","page: confirmed","bad")],
 "Ada and Ben both read that seat 14C is free. Ada's insert succeeds. Ben's insert fails on the unique constraint, but the buggy page tells Ben his seat is confirmed.",gap=250)
ring=lanes([("buf[0]",["1","1",("3","bad"),"3"]),("buf[1]",["0","2","2","2"]),("head",["0","0","0","0"]),("tail",["1","2","2","2"]),
 ("Queued",["⟨1⟩","⟨1,2⟩",("⟨3,2⟩","bad"),"⟨3,2⟩"]),("got",["⟨⟩","⟨⟩","⟨⟩",("⟨3⟩","bad")])],
 "Selected states of the off-by-one ring buffer. With two items unread, the producer overwrites slot 0, so the mapped queue changes from 1, 2 to 3, 2, and the consumer then receives 3 first.",
 cols=["P3: publish 1","P3: publish 2","P2: write 3","C2: read"],labelw=90,cell=118)
starve=graph({"a":(110,50,"lock free\nA: Acquire  B: Loop","accent"),"b":(470,50,"lock free\nA: Acquire  B: Acquire","accent"),
 "c":(470,200,"lock = B\nA: Acquire  B: Work","muted"),"d":(110,200,"lock = B\nA: Acquire  B: Release","muted")},
 [("a","b","Loop(B)"),("b","c","Acquire(B)"),("c","d","Work(B)"),("d","a","Release(B)",{"tone":"bad"})],
 "The four-state cycle in TLC's counterexample. Worker A waits at Acquire throughout. Its Acquire is enabled in the top two states, where the lock is free, and disabled in the bottom two, where B holds it.",width=640,height=250)
FIGS={"lost":(lost,"TLC's five-state trace. The two <code>Select</code> steps both happen before either <code>Update</code>, so the second write overwrites the first with the same stale sum."),
"seat":(seat,"The trace for the buggy reply. The database keeps one row for 14C, but the page uses the stale result of the check instead of the result of the insert."),
"ring":(ring,"Four states from the off-by-one trace. The refinement check fails at the third column, when the slot is overwritten. <code>InOrder</code> fails only at the fourth, when the consumer reads it."),
"starve":(starve,"The cycle TLC reports for looping workers. A's <code>Acquire</code> is enabled in the top two states, where the lock is free, and disabled in the bottom two, so it is never continuously enabled and weak fairness never forces it.")}
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-psb1-{k}\"").replace("#dg-a)",f"#dg-a-psb1-{k})"),v[1]) for k,v in FIGS.items()}
