import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions,_svg,_text
def n(x,y,t,tone=""):
    return f'<rect x="{x-44}" y="{y-16}" width="88" height="32" rx="7" class="dg-n {("dg-"+tone) if tone else ""}"/>'+_text(x,y,t)
def a(x1,y1,x2,y2,tone="",dash=False,lab=""):
    d=' stroke-dasharray="5 4"' if dash else ""
    s=f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" class="dg-e {("dg-"+tone) if tone else ""}" marker-end="url(#dg-a)"{d}/>'
    return s
def r(x,y,w,h,t,tone=""):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" class="dg-r {("dg-"+tone) if tone else ""}"/>'+_text(x+12,y+16,t,anchor="start")
body=(r(6,6,700,296,"TypeOK: 27 type-correct states","muted")
 +r(26,36,660,214,"Inv: 6 states, closed under Next","accent")
 +r(46,66,620,74,"Reachable: 3 states","good")
 +n(130,110,"2 · 0 · 0","good")+a(174,110,303,110)+n(350,110,"1 · 1 · 0","good")+a(394,110,523,110)+n(570,110,"1 · 0 · 1","good")
 +_text(238,98,"Debit",cls="dg-t dg-sm",size=12)+_text(458,98,"Credit",cls="dg-t dg-sm",size=12)
 +_text(120,172,"Unreachable, still in Inv:",anchor="middle",cls="dg-t dg-sm",size=12)
 +n(130,205,"0 · 2 · 0")+a(174,205,303,205)+n(350,205,"0 · 1 · 1")+a(394,205,523,205,"bad",True)+n(570,205,"0 · 0 · 2","bad")
 +_text(238,193,"Credit",cls="dg-t dg-sm",size=12)+_text(458,193,"breaks bob ≤ 1",cls="dg-t dg-sm dg-t-bad",size=12)
 +n(130,276,"1 · 0 · 0")+_text(320,276,"sum 1: outside Inv, and no Inv edge reaches it",cls="dg-t dg-sm",size=12,anchor="start") .replace('x="320.0"','x="186.0"'))
reg=_svg(712,308,body,"Three nested sets of Transfer states. The 3 reachable states sit inside the 6 states of Inv, which sit inside 27 type-correct states. The 3 unreachable Inv states form their own chain; its last step breaks bob at most 1, which is why that fact is not inductive.")
run=lanes([("alice",["2","1","1"]),("transit",["0","1","0"]),("bob",["0","0","1"]),("alice + bob",["2",("1","bad"),"2"]),("all three",[("2","good"),("2","good"),("2","good")])],
 "A legal run of Transfer. The sum of alice and bob dips to 1 while the unit is in transit. The sum of all three stays 2.",cols=["Init","Debit","Credit"],cell=64,labelw=100)
cti=graph({"s":(80,50,"1 left, {}","good"),"a":(360,35,"0 left, {A}","good"),"b":(360,95,"0 left, {B}","good"),
 "x":(80,170,"1 left, {A}"),"y":(80,250,"1 left, {B}"),"z":(360,300,"0 left, {}"),"o":(560,210,"0 left, {A, B}","bad")},
 [("s","a","Reserve(A)"),("s","b","Reserve(B)"),("x","o","Reserve(B)",{"tone":"bad"}),("y","o","Reserve(A)",{"tone":"bad"})],
 "Six states satisfy NoOverselling with TypeOK. Three are reachable. Two unreachable ones, one left with a booking already made, have a step to a double booking.")
FIGS={"regions":(reg,"The Transfer states, written alice · transit · bob. Green is what TLC can reach. Blue, Inv, adds three states that no behavior visits, and still no arrow leaves it. The dashed arrow leaves the fact <code>bob ≤ 1</code>, though every reachable state satisfies it."),
"run":(run,"A legal run. <code>alice + bob</code> fails while the unit is in transit. Adding the third place makes a quantity that every step preserves."),
"cti":(cti,"All 6 states satisfying <code>TypeOK /\\ NoOverselling</code>. Green is reachable. The red edges start from states that are safe but never occur: one ticket left, and someone already booked.")}
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-inv-{k}\"").replace("#dg-a)",f"#dg-a-inv-{k})"),v[1]) for k,v in FIGS.items()}
