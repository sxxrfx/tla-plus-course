import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
_bad={"tone":"bad"}
tick=graph({"rr":(80,90,"Reserve, Reserve\n1 left, {}"),"da":(320,40,"Done, Reserve\n0 left, {A}"),"db":(320,140,"Reserve, Done\n0 left, {B}"),
 "fa":(570,40,"Done, Done\n0 left, {A}","good"),"fb":(570,140,"Done, Done\n0 left, {B}","good")},
 [("rr","da","A reserves"),("rr","db","B reserves"),("da","fa","B: if false"),("db","fb","A: if false")],
 "The 5 reachable states of TicketPC. Each node shows both program counters, the tickets left and who is booked.")
flow=graph({"c":(60,70,"Check"),"t":(280,70,"Take"),"d":(500,70,"Done")},
 [("c","t","remaining > 0"),("t","d","update both"),("c","d","else",{"bend":-50})],
 "The values one buyer's program counter can take after splitting the label: Check goes to Take when tickets remain and otherwise to Done; Take goes to Done.",height=95)
L=lambda a,b:a+", "+b
lost=graph({
 "rr":(55,170,"Read, Read\ncount 0"),
 "wr":(200,110,"Write, Read\ncount 0"),"rw":(200,230,"Read, Write\ncount 0"),
 "dr":(345,50,"Done, Read\ncount 1"),"ww":(345,170,"Write, Write\ncount 0"),"rd":(345,290,"Read, Done\ncount 1"),
 "d1":(495,30,"Done, Write\nB saw 1"),"d0":(495,125,"Done, Write\nB saw 0"),"w0":(495,215,"Write, Done\nA saw 0"),"w1":(495,310,"Write, Done\nA saw 1"),
 "g1":(640,30,"Done, Done\ncount 2","good"),"bad":(640,170,"Done, Done\ncount 1","bad"),"g2":(640,310,"Done, Done\ncount 2","good"),
},[("rr","wr","A"),("rr","rw","B"),("wr","dr","A"),("wr","ww","B"),("rw","ww","A"),("rw","rd","B"),
 ("dr","d1","B"),("ww","d0","A",_bad),("ww","w0","B",_bad),("rd","w1","A"),
 ("d1","g1","B"),("d0","bad","B",_bad),("w0","bad","A",_bad),("w1","g2","A")],
 "All 13 reachable states of the lost update model. Paths where one worker finishes before the other reads end at count 2. Paths through the state where both have read count 0 end at count 1.")
trace=lanes([("pc[A]",["Read","Read","Write","Done","Done"]),("pc[B]",["Read","Write","Write","Write","Done"]),
 ("local[A]",["0","0","0","0","0"]),("local[B]",["0","0","0","0","0"]),("count",["0","0","0","1",("1","bad")])],
 "TLC's trace of the lost update: B reads, A reads, A writes 1, B writes 1.",cols=["Init","Read B","Read A","Write A","Write B"],cell=74)
FIGS={"tick":(tick,"TicketPC has 5 reachable states. Each node shows both pc values, then stock and bookings. On the right-hand edges the second buyer’s <code>if</code> is false: only its pc moves."),
"flow":(flow,"One buyer’s control flow after the split. These are the values of <code>pc[self]</code>, and each arrow is one translated action. Between Check and Take, the other buyer can run."),
"lost":(lost,"The 13 reachable states of the lost update model. Nodes show the two pc values; edges name the worker that stepped. The red edges leave the one state where both workers hold a read of 0."),
"trace":(trace,"TLC’s trace. Two increments completed and count is 1.")}
# Markers live per SVG: hidden lessons would otherwise hold the only #dg-a that url() resolves to, and arrowheads vanish.
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-pluscal-{k}\"").replace("#dg-a)",f"#dg-a-pluscal-{k})"),v[1]) for k,v in FIGS.items()}
