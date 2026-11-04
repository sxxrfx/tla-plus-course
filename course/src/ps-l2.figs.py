import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
rn={"t":(90,120,'pc = "test"',"accent"),"s":(370,120,'pc = "send"'),"c":(600,120,'pc = "count"'),"d":(90,240,'pc = "done"',"good")}
retry=graph(rn,[("t","s","~ok and attempts < 3",{"ly":16}),("s","c","ok becomes\nTRUE or FALSE",{"ly":24}),("c","t","attempts + 1",{"bend":75}),("t","d","otherwise",{"lx":34})],
            "Control flow of the retry loop. From test, go to send when ok is false and attempts is below 3, otherwise to done. Send sets ok to true or false and goes to count. Count adds one to attempts and returns to test.",width=680,height=270,mono=True)
bn={"a":(60,60,"1..16","accent"),"b":(210,60,"1..8"),"c":(360,60,"5..8"),"d":(510,60,"5..6"),"e":(640,60,"6..6","good"),"x":(210,180,"9..16","muted")}
bis=graph(bn,[("a","b","8 bad",{"ly":-14}),("b","c","4 good",{"ly":-14}),("c","d","6 bad",{"ly":-14}),("d","e","5 good",{"ly":-14}),("a","x","8 good",{"dash":True,"lx":-30})],
          "A bisect session as states lo..hi. From 1..16, testing commit 8 as bad gives 1..8; testing 4 as good gives 5..8; testing 6 as bad gives 5..6; testing 5 as good gives 6..6, where it stops. A dashed alternative: 8 good would have given 9..16.",width=690,height=220,mono=True)
def P(i,b): return f"idle {i}\nbusy {b}"
pn={"00":(80,70,P(0,0),"accent"),"10":(300,70,P(1,0)),"01":(300,220,P(0,1)),"20":(540,70,P(2,0)),"11":(540,220,P(1,1))}
pool=graph(pn,[("00","10","Open",{"bend":16,"ly":8}),("10","00","Evict",{"bend":16,"ly":-8}),
               ("10","01","Acquire",{"bend":18,"lx":-34}),("01","10","Release",{"bend":18,"lx":34}),
               ("10","20","Open",{"bend":16,"ly":8}),("20","10","Evict",{"bend":16,"ly":-8}),
               ("01","11","Open",{"ly":-12}),("20","11","Acquire",{"bend":18,"lx":-34}),("11","20","Release",{"bend":18,"lx":34})],
          "Part of the pool's state graph, for at most two connections. From idle 0 busy 0, Open goes to idle 1 busy 0. Acquire moves one connection from idle to busy and Release moves it back. Evict closes an idle connection. Open adds an idle connection.",width=640,height=280,mono=True)
def C(p,d,n,t=""): return (f"{p}/{d}/{n}",t) if t else f"{p}/{d}/{n}"
beh=lanes([("A",[C("idle","F",0),C("loading","F",1),C("error","F",0),C("loading","F",1),C("success","F",0)]),
           ("B",[C("idle","F",0),C("loading","F",1),C("loading","T",1),C("success","T",0),C("idle","T",0)]),
           ("C",[C("idle","F",0),C("loading","F",1),C("loading","F",2)]),
           ("D",[C("idle","F",0),C("loading","F",1),C("success","F",0),C("loading","F",1)])],
          "Four sequences of Button states, each cell phase / disabled / inflight. A: idle F 0, loading F 1, error F 0, loading F 1, success F 0. B: idle F 0, loading F 1, loading T 1, success T 0, idle T 0. C: idle F 0, loading F 1, loading F 2. D: idle F 0, loading F 1, success F 0, loading F 1.",
          cols=["state 1","state 2","state 3","state 4","state 5"],labelw=40)
FIGS={"retry":(retry,"The retry loop's control state. Each box is a value of pc, and each arrow is one case of Next. The labels say when the case applies and what it changes."),
"bisect":(bis,"One bisect session, drawn as states of the range lo..hi. Each arrow is one step: the commit tested and its result. The dashed arrow is the other possible answer at the first step."),
"pool":(pool,"Part of the connection pool's state graph, as the pool's authors intend it. Opposite arrows between the same two states are drawn as a pair of curves."),
"button-behaviors":(beh,"Four sequences of Button states. Each cell is phase / disabled / inflight, where T and F stand for TRUE and FALSE.")}
