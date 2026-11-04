import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
skew=lanes([
 ("onCall[alice]",["TRUE","TRUE","TRUE","TRUE",("FALSE","accent"),"FALSE",("FALSE","bad")]),
 ("onCall[bob]",["TRUE","TRUE","TRUE","TRUE","TRUE","TRUE",("FALSE","bad")]),
 ("alice sees",[None,"2 on","2 on","2 on","2 on","2 on","2 on"]),
 ("bob sees",[None,None,None,("2 on","accent"),"2 on",("2 on","bad"),"2 on"]),
 ("pc[alice]",["Begin","Check","Commit","Commit","Done","Done","Done"]),
 ("pc[bob]",["Begin","Begin","Begin","Check","Check","Commit","Done"]),
],"TLC's snapshot-isolation trace. Alice begins and checks two on call; Bob begins, taking a snapshot with both on call; Alice commits off call; Bob's check still sees two on call in his snapshot; Bob commits, and both are off call.",
 cols=["Init","Begin(a)","Check(a)","Begin(b)","Commit(a)","Check(b)","Commit(b)"],labelw=120,cell=82)
saga=sequence(["Orders","Network","Payments"],[
 ("Orders","Network","charge order 7"),
 ("note","Orders","30 s, no reply: timeout"),
 ("note","Orders","release stock, cancel"),
 ("Orders","Payments","refund order 7"),
 ("note","Payments","no charge yet: no-op","bad"),
 ("Network","Payments","charge arrives late",{"tone":"bad"}),
 ("note","Payments","charged","bad"),
 ("Payments","Orders","charged (ignored)",{"dash":True}),
],"TLC's Refund trace: the charge request is delayed; the order service times out, releases the stock, cancels and sends a refund; the refund arrives first and does nothing; the charge then succeeds and its reply is ignored.",gap=250,step=38)
gc=lanes([
 ("c[r1]",["0,0,0",("1,0,0","accent"),"1,0,0",("1,1,0","good"),"1,1,0"]),
 ("c[r2]",["0,0,0","0,0,0",("0,1,0","accent"),"0,1,0","0,1,0"]),
 ("c[r3]",["0,0,0","0,0,0","0,0,0","0,0,0",("1,1,0","good")]),
 ("Total",["0","1","2","2","2"]),
 ("Value(r3)",["0","0","0","0","2"]),
],"A G-counter behavior stepped by hand through the module's actions. r1 and r2 each count a like in their own entry, raising Total to 2. Merges copy entrywise maxima: r1 learns r2's entry, then r3 learns both, jumping its display from 0 to 2 while Total stays 2.",
 cols=["Init","Like(r1)","Like(r2)","Merge(r1,r2)","Merge(r3,r1)"],labelw=90,cell=118)
logs=lanes([
 ("term s1,s2",["0,0","1,0","1,2","1,2","1,2","1,2",("2,2","accent")]),
 ("log[s1]",["<<>>","<<>>","<<>>","<<1>>","<<1>>","<<1>>",("<<1,2>>","bad")]),
 ("log[s2]",["<<>>","<<>>","<<>>","<<>>","<<2>>","<<2,2>>",("<<2,2>>","bad")]),
],"TLC's trace without the previous-entry check. s1 leads term 1 and appends a term-1 entry; s2 leads term 2 and appends two term-2 entries; s2 sends entry 2 to s1, which keeps its own entry 1 and ends with 1 then 2, while s2 has 2 then 2.",
 cols=["Init","Elect(s1,1)","Elect(s2,2)","Req(s1)","Req(s2)","Req(s2)","AE(s2,s1,1)"],labelw=95,cell=86)
sched=sequence(["Scheduler","w1","w2","Storage"],[
 ("Scheduler","w1","lease j1, token 1"),
 ("w1","Storage","write output (1)"),
 ("note","w1","pause: lease expires"),
 ("Scheduler","w2","lease j1, token 2"),
 ("w1","Storage","commit: done, invoice"),
 ("note","Storage","doneTok = 1"),
 ("w2","Storage","write output (2)",{"tone":"bad"}),
 ("note","Storage","output 2, doneTok 1","bad"),
],"TLC's DedupOnly trace: w1 writes with token 1 and pauses past its lease; w2 is granted token 2; w1 commits the job with token 1; w2 then overwrites the output with token 2, so the stored output no longer belongs to the committed run.",gap=180,step=38)
FIGS={"skew":(skew,"Each snapshot is frozen at <code>Begin</code>. Bob’s check runs after Alice’s commit and still counts her as on call."),
"saga":(saga,"A timeout is not a failure. The charge was still on its way, and a refund that arrives first has nothing to undo."),
"gcounter":(gc,"Only the owner raises its own entry, so merges never change <code>Total</code>: they are stuttering steps of the counter contract. The display catches up in jumps."),
"logs":(logs,"Both logs have term 2 at index 2 but different histories before it. The previous-entry check exists to refuse exactly the last step."),
"sched":(sched,"w1 committed after its lease ended, and w2, the rightful holder, then overwrote a finished job’s output. Deduplication saw nothing wrong. Fenced storage refuses the red write, because the job is already done.")}
