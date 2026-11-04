import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
win=regions([(20,20,320,96,"previous minute"),(360,20,320,96,"current minute"),
             (32,52,140,52,"first half"),(184,52,144,52,"second half: p2","accent"),
             (372,52,140,52,"first half: a1","accent"),(524,52,144,52,"second half: a2"),
             (184,150,328,44,"60 s that SlidingOK checks: p2 + a1","bad"),
             (372,206,296,44,"60 s that WindowOK checks: a1 + a2","good")],
            "Two minutes split into halves. The previous minute's second half is p2; the current minute's halves are a1 and a2. WindowOK checks a1 plus a2, one fixed window. SlidingOK checks p2 plus a1, a 60 second span that crosses the boundary between the minutes.",
            width=700,height=262,notes=((350,132,"reset"),))
rt=lanes([("half",["1","2","2","2","1","1","1"]),("p2",["0","0","0","0","2","2","2"]),("a1",["0","0","0","0","0","1","2"]),("a2",["0","0","1","2","0","0","0"]),
          ("p2 + a1",["0","0","0","0","2","3",("4","bad")])],
         "TLC's trace for SlidingOK. Tick, two accepts in the second half, Tick into a new minute which moves 2 into p2 and resets the counters, then two accepts in the first half. p2 plus a1 reaches 4.",
         cols=["1 Init","2 Tick","3 Acc2","4 Acc2","5 Tick","6 Acc1","7 Acc1"],cell=72,labelw=70)
wt=lanes([("running",["0","1","2","1","2",("3","bad")]),("permits",["2","1","0","2","1","0"])],
         "TLC's trace for the worker pool: running 0, 1, 2, 1, 2, 3 and permits 2, 1, 0, 2, 1, 0. The steps are Start, Start, Fail, Start, Start. AtMostTwo fails in state 6.",
         cols=["1 Init","2 Start","3 Start","4 Fail","5 Start","6 Start"],cell=78,labelw=80)
en={"a":(70,50,"34, 21","accent"),"b":(250,50,"13, 21"),"c":(430,50,"13, 8"),"d":(610,50,"5, 8"),
    "e":(610,160,"5, 3"),"f":(430,160,"2, 3"),"g":(250,160,"2, 1"),"h":(70,160,"1, 1","good")}
eu=graph(en,[("a","b","SubY",{"ly":-13}),("b","c","SubX",{"ly":-13}),("c","d","SubY",{"ly":-13}),("d","e","SubX",{"lx":24}),
             ("e","f","SubY",{"ly":-13}),("f","g","SubX",{"ly":-13}),("g","h","SubY",{"ly":-13})],
         "Euclid's algorithm from x 34, y 21: 34 21, 13 21, 13 8, 5 8, 5 3, 2 3, 2 1, 1 1. Each step subtracts the smaller value from the larger. At 1 1 no case applies.",width=680,height=200,mono=True)
rn={"t":(80,200,'test',"accent"),"s":(280,200,'send'),"w":(480,200,'wait'),"c":(480,320,'count'),"d":(80,90,'done',"good"),"x":(650,320,"resp = \"lost\":\nno case","bad")}
rnet=graph(rn,[("t","s","Test"),("s","w","Send: resp' is\nok, err or lost",{"ly":-24}),("w","c","GotOk or\nGotErr",{"lx":-38}),("c","t","Count",{"lx":20,"ly":12}),
               ("t","d","Exit",{"lx":-22}),("d","d","Done"),("w","x","",{"dash":True,"tone":"bad"})],
           "Control flow of the retry loop with a network. Test goes to send, Send to wait while choosing the response ok, err or lost. From wait, GotOk or GotErr go to count; count goes back to test. Exit goes from test to done, and Done loops on done. From wait with a lost response no case applies.",width=720,height=360)
FIGS={"windows":(win,"What the two invariants measure. A fixed window resets its counters at the minute boundary, so WindowOK only ever looks inside one minute. The red span crosses the boundary."),
"ratelimit-trace":(rt,"TLC's counterexample to SlidingOK as a grid: one column per state, with the action that produced it. The last row is not a variable; it is the value SlidingOK tests."),
"workers-trace":(wt,"The trace your teammate got, one column per state, headed by the action that produced it. AtMostTwo fails only in state 6."),
"euclid":(eu,"The whole state graph for M = 34 and N = 21. Each state has at most one next state, so the graph is a single path, and it ends at 1, 1."),
"retrynet":(rnet,"The retry loop with a network, by value of pc. The red box is not a value of pc: it marks the states with pc = \"wait\" and a lost response, where no case of Next applies.")}
