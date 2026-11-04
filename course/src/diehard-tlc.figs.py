import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
def c(s,b):
    r=s in(0,3) or b in(0,5)
    if not r: return None
    return (f"{s},{b}","bad" if b==4 else "good")
grid=lanes([(f"small = {s}",[c(s,b) for b in range(6)]) for s in (3,2,1,0)],"Grid of states by small and big. Sixteen are reachable: those with a jug empty or full. Two of them, with big 4, are shown red. The remaining eight cells are empty.",cols=[f"big {b}" for b in range(6)],cell=66,labelw=100)
def st(s,b): return f"small {s}\nbig {b}"
T=[(0,0),(0,5),(3,2),(0,2),(2,0),(2,5),(3,4)]
L=["FillBig","BigToSmall","EmptySmall","BigToSmall","FillBig","BigToSmall"]
tn={f"s{i}":(48+i*98,62,st(*v),("bad" if i==6 else "accent" if i==0 else "")) for i,v in enumerate(T)}
trace=graph(tn,[(f"s{i}",f"s{i+1}",L[i],{"ly":-40,"tone":"bad" if i==5 else ""}) for i in range(6)],"The error trace TLC reports: seven states from both jugs empty to small 3 big 4, with the action name above each arrow.",width=690,height=104)
en={"e":(70,60,"Edit and\nsave","accent"),"p":(250,60,"Parser"),"t":(430,60,"TLC runs\nthe spec"),"i":(620,60,"TLC checks\ninvariants"),"pe":(250,170,"deleted +\nor bigg","bad"),"te":(430,170,"=< \"5\"\nor 0 = small'","bad"),"ie":(620,170,"trace ending\nat big = 4","good")}
errs=graph(en,[("e","p"),("p","t"),("t","i"),("p","pe"),("t","te"),("i","ie")],"Errors found at each stage. The parser catches a deleted plus or a misspelled identifier. TLC's run catches a string in arithmetic or a backwards prime. The invariant check produces a trace ending at big 4.",width=700,height=214)
FIGS={"grid":(grid,"The state space TLC finds. Blank cells are unreachable: after any step, one jug is empty or full. TypeOK asks that every filled cell stays inside this 4 by 6 grid. <code>big /= 4</code> claims TLC never reaches a red cell, and that claim is false."),
"trace":(trace,"Saving our heroes. Each arrow names the line of Next that allows the step. The last step pours the big jug into the small one, leaving exactly 4 gallons."),
"errors":(errs,"Each stage catches a different kind of mistake, in this order. The last one is the one we wanted.")}
