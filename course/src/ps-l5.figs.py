import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions

# Problem 1: the status function, with the one change the Next step makes
fail=graph({"d1":(90,40,"db1  (lag 0)"),"d2":(90,120,"db2  (lag 4)"),"d3":(90,200,"db3  (lag 90)"),
 "x":(470,40,"\"down\"","bad"),"s":(470,120,"\"streaming\"","good"),"c":(470,200,"\"catchup\"")},
 [("d1","s"),("d2","s"),("d3","c"),("d1","x","after Next",{"dash":True,"tone":"bad","ly":-12})],
 "The function status from three replicas to their states. db1 and db2 map to streaming, db3 to catchup. A dashed red arrow from db1 to down shows the change Next makes. Each replica's lag is written beside it: 0, 4 and 90 seconds.",
 width=560,height=232)

# Problem 2: the trace TLC prints for the buggy rollout guard
S=lambda t:t;M=lambda t:(t,"muted");X=lambda t:(t,"bad")
roll=lanes([("p1",["v1",M("stopping"),M("starting"),X("starting")]),
 ("p2",["v1","v1","v1",X("stopping")]),
 ("p3",["v1","v1","v1","v1"])],
 "Four states of three pods. p1 goes from v1 to stopping to starting. In the fourth state p2 is stopping too, so p1 and p2 are both out of service.",
 cols=["Init","Stop(p1)","Start(p1)","Stop(p2)"],cell=110,labelw=50)

# Problem 3: one service's upgrade states, named after TCommit's
svc=graph({"w":(250,34,"v1  (working)","accent"),"p":(250,124,"ready  (prepared)"),
 "c":(90,224,"v2  (committed)","good"),"a":(420,224,"pinned  (aborted)","bad")},
 [("w","p","GetReady"),("p","c","Switch: all ready or v2",{"lx":-58}),("p","a","Cancel: none on v2",{"lx":54}),
  ("w","a","Cancel",{"bend":-60,"lx":24})],
 "State machine of one service in the schema upgrade. v1 goes to ready by GetReady. Ready goes to v2 by Switch, allowed only when all services are ready or on v2, or to pinned by Cancel, allowed only when no service is on v2. v1 can also Cancel directly to pinned.",
 width=540,height=258)

# Problem 4: the check-then-run race
cron=sequence(["n1","jobs table","n2"],[
 ("n1","jobs table","SELECT owner: none"),("n2","jobs table","SELECT owner: none"),
 ("n1","jobs table","UPDATE owner = n1"),("note","n1","n1 runs backup"),
 ("n2","jobs table","UPDATE owner = n2",{"tone":"bad"}),("note","n2","n2 runs backup","bad")],
 "Message sequence: n1 and n2 each read owner none from the jobs table. n1 writes owner n1 and runs the backup. n2, which already saw none, writes owner n2 and runs the backup a second time.",
 gap=230,step=42)

FIGS={"failover":(fail,"<code>status</code> is a function: one solid arrow out of each replica. <code>lag</code> is a second function with the same domain. The dashed arrow is the only change <code>Next</code> makes."),
"rollout":(roll,"TLC's trace for the buggy guard. In the last state p1 is still starting, so it doesn't serve, and the guard let p2 stop anyway: two of three pods are down."),
"schema":(svc,"One service's upgrade, with TCommit's name for each state in parentheses. The guards on Switch and Cancel read every service's state, exactly like <code>canCommit</code> and <code>notCommitted</code>."),
"cron":(cron,"Check, then act. Both nodes saw <code>none</code> before either wrote, and nothing makes the second <code>UPDATE</code> look again.")}
