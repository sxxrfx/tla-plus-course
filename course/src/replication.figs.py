import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
venn=regions([(40,20,300,110,"MS1 = {a1, a2}","accent"),(220,50,300,110,"MS2 = {a2, a3}","good")],
 "Two overlapping regions: MS1 holds a1 and a2; MS2 holds a2 and a3; the overlap holds a2.",width=560,height=180,
 notes=[(130,90,"a1"),(280,88,"a2"),(430,120,"a3"),(280,112,"MS1 \\cap MS2")])
maj=lanes([("{a1, a2}",[("a1","good"),("a2","good"),None]),("{a1, a3}",[("a1","good"),None,("a3","good")]),("{a2, a3}",[None,("a2","good"),("a3","good")]),("{a3}",[None,None,("a3","bad")])],
 "A grid of acceptor sets against acceptors. Each pair of the three two-element sets shares a column. The bad set holding only a3 shares no column with the set of a1 and a2.",cols=["a1","a2","a3"],cell=64,labelw=90)
g=lambda t:(t,"good");b=lambda t:(t,"bad")
read=lanes([("A",["v8",None,g("v8")]),("B",["v7",b("asked: v7"),"v7"]),("C",["v8",None,g("v8")])],
 "Replicas after an acknowledged write: A and C have version 8, B has version 7. A read asking only B returns 7. A read asking any two replicas includes A or C, so it finds 8.",
 cols=["after ack","R = 1 read","R = 2: any two"],cell=120,labelw=40)
FIGS={"venn":(venn,"Two majorities of three acceptors. Their intersection is not empty, and it's the only thing they have to share."),
"maj":(maj,"Each row is a set in Majority, each column an acceptor. Any two green rows share a column. The red row breaks the property against {a1, a2}."),
"read":(read,"TLC's trace at R = 1 stops with a read of B alone. At R = 2, each possible pair of replies includes v8.")}
