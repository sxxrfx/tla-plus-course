import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
sn={"a":(70,90,"pc: start\n1 state","accent"),"b":(280,90,"pc: middle\n1001 states"),"c":(490,90,"pc: done\n1001 states"),"d":(650,90,"no next\nstate","bad")}
sp=graph(sn,[("a","b","i' \\in 0..1000",{"ly":-14}),("b","c","i' = i + 1",{"ly":-14}),("c","d","",{"dash":True,"tone":"bad"})],"SimpleProgram's reachable states grouped by pc: 1 with start, 1001 with middle, 1001 with done, then no next state.",width=710,height=140)
def row(names,y,bad=None):
    return {f"{y}{i}":(70+i*118,y,f"x = {v}",("bad" if v==bad else "good")) for i,v in enumerate(names)}
g=row([0,1,2,3],36);b=row([0,1,2,3,4],120,bad=4)
cn={**g,**b}
ce=[(f"36{i}",f"36{i+1}") for i in range(3)]+[(f"120{i}",f"120{i+1}") for i in range(4)]
cg=graph(cn,ce,"Two counter graphs for Max 3. With guard x less than Max: 0, 1, 2, 3, then no next state. With guard x at most Max: 0, 1, 2, 3, 4, and 4 breaks Safe.",width=620,height=168,mono=True)
rn={"z":(70,60,"0 started"),"o":(210,60,"1 started"),"t":(350,60,"2 started"),"h":(490,60,"3 started","good"),"f":(490,160,"4 started","bad")}
retry=graph(rn,[("z","o"),("o","t"),("t","h","attempts < 3",{"ly":-32}),("h","f","blocked: 3 < 3 is FALSE",{"dash":True,"tone":"bad","lx":-92})],"Retry budget: attempts go 0 to 3 with guard attempts less than 3. A dashed arrow from 3 to 4 is blocked because 3 less than 3 is false.",width=560,height=200)
FIGS={"simple":(sp,"Where TLC's 2003 comes from: 1 + 1001 + 1001. All 1001 pc: done states have no next state, and each one is a place a run stops."),
"counters":(cg,"Top row: the guard is <code>x &lt; Max</code>. Bottom row: <code>x =&lt; Max</code> allows one more step, and <code>x = 4</code> breaks Safe."),
"retry":(retry,"“Three attempts” has four valid values. The guard reads the old value, so the strict comparison is the one that stops at 3.")}
