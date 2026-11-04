import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
race=sequence(["User","Screen","API"],[
 ("User","Screen","search cats"),("Screen","API","request 1"),
 ("User","Screen","search dogs"),("Screen","API","request 2"),
 ("API","Screen","2: dogs"),("note","Screen","shows dogs","good"),
 ("API","Screen","1: cats (late)",{"tone":"bad"}),("note","Screen","shows cats","bad"),
],"The user searches cats then dogs. The dogs response arrives first and is shown. The cats response arrives later and replaces it, so the screen shows cats while the user's choice is dogs.",gap=220,step=36)
buggy=lanes([("latest",["0","1","2","2","2"]),("pending",["{}","{1}","{1,2}","{1}","{}"]),("ui",["idle","loading 1","loading 2","ready 2 dogs",("ready 1 cats","bad")])],
 "Unguarded trace: start 1, start 2, deliver 2 shows dogs, deliver 1 shows cats while latest is 2.",cols=["Init","Start","Start","Deliver(2)","Deliver(1)"],labelw=70)
guarded=lanes([("latest",["0","1","2","2","2"]),("pending",["{}","{1}","{1,2}","{1}","{}"]),("ui",["idle","loading 1","loading 2","ready 2 dogs",("ready 2 dogs","good")])],
 "Guarded trace: the same steps, but deliver 1 leaves the ui as ready 2 dogs while pending still changes.",cols=["Init","Start","Start","Deliver(2)","Deliver(1)"],labelw=70)
space=graph({
 "s0":(52,120,"0 {}\nidle"),"s1":(180,120,"1 {1}\nloading 1"),
 "s2":(340,50,"2 {1,2}\nloading 2"),"s3":(340,190,"1 {}\nready 1"),
 "s4":(510,190,"2 {2}\nloading 2"),"s5":(510,50,"2 {1}\nready 2"),
 "s6":(650,120,"2 {}\nready 2","good"),
},[
 ("s0","s1","Start"),("s1","s2","Start"),("s1","s3","Deliver(1)",{"lx":-20,"ly":22}),
 ("s3","s4","Start"),("s2","s5","Deliver(2)"),
 ("s2","s4","Deliver(1)\nui same",{"tone":"accent","dash":True,"lx":-8,"ly":-20}),
 ("s4","s6","Deliver(2)",{"lx":8,"ly":12}),
 ("s5","s6","Deliver(1)\nui same",{"tone":"accent","dash":True,"lx":6,"ly":-16}),
],"All seven reachable states of AppState, each labelled latest, pending and ui. The two dashed edges are Deliver(1) arriving after request 2 started; they change pending but leave the ui unchanged.",width=710,height=230)
FIGS={"race":(race,"Each response is correct on its own. The bug is in what the screen does with the one that arrives last."),
"buggy":(buggy,"Without the guard. Request order and response order are independent, and the last column breaks the contract."),
"guarded":(guarded,"With the guard, the same delivery order. Only <code>pending</code> changes in the last step."),
"space":(space,"The whole state space of the module, each state written as latest, pending, ui. TLC’s count of 7 distinct and 9 generated is these seven boxes, eight arrows, and the initial state. The dashed arrows are where the guard does its work.")}
