import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
def st(s,b): return f"small {s}\nbig {b}"
T=[(0,0),(3,0),(0,3),(3,3),(1,5),(1,0)]
tn={f"s{i}":(50+i*118,62,st(*v),"accent" if i==0 else "") for i,v in enumerate(T)}
L=["fill small","pour to big","fill small","pour to big","empty big"]
beh=graph(tn,[(f"s{i}",f"s{i+1}",L[i],{"ly":-38}) for i in range(5)],"The first behavior from the lecture: small and big go 0,0 then 3,0 then 0,3 then 3,3 then 1,5 then 1,0, with the step named above each arrow.",width=690,height=100)
sn={"a":(60,50,st(0,3),"accent"),"b":(560,50,st(3,3),"good"),"c":(60,150,st(0,3),"accent"),"d":(230,150,st(1,3),"bad"),"e":(390,150,st(2,3),"bad"),"f":(560,150,st(3,3))}
fill=graph(sn,[("a","b","filling is one step",{"tone":"good","ly":-14}),("c","d","",{"tone":"bad","dash":True}),("d","e","not modeled",{"tone":"bad","dash":True,"ly":-16,"lx":0}),("e","f","",{"tone":"bad","dash":True})],"Top row: filling the small jug is a single step from small 0 to small 3. Bottom row, not modeled: partial fills through small 1 and small 2.",width=630,height=196)
fn={"c":(120,160,st(3,3),"accent"),"a":(480,34,st(3,5)),"b":(480,108,st(0,3)),"d":(480,182,st(3,0)),"e":(480,256,st(1,5))}
fan=graph(fn,[("c","c","FillSmall, BigToSmall"),("c","a","FillBig",{"lx":10,"ly":-6}),("c","b","EmptySmall",{"lx":-2,"ly":-4}),("c","d","EmptyBig",{"lx":-2,"ly":4}),("c","e","SmallToBig",{"lx":10,"ly":6})],"From small 3 big 3, the six kinds of step lead to four other states; FillSmall and BigToSmall leave the state unchanged.",width=560,height=296)
FIGS={"behavior":(beh,"One correct behavior, written before any formula. It told us the two variables and what counts as one step."),
"fill":(fill,"The top row is the abstraction: no partly filled state exists. The red states would add nothing to the question we are asking, so they are not in the model."),
"fan":(fan,"Next is a choice among six kinds of step. From this state four lead elsewhere; the loop on top is two more that change nothing, since the small jug is already full.")}
