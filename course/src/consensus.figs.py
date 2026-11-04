import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
ins=graph({"r1":(70,40,"r1's instance"),"r2":(70,110,"r2's instance"),"r3":(70,180,"r3's instance"),
 "v1":(270,40,"prepared","good"),"v2":(270,110,"prepared","good"),"v3":(270,180,"aborted","bad"),
 "d":(470,110,"any aborted:\nAbort","bad")},
 [("r1","v1","chose"),("r2","v2","chose"),("r3","v3","chose"),("v1","d",""),("v2","d",""),("v3","d","")],
 "Three consensus instances, one per RM, choose prepared, prepared, aborted. The commit rule combines them and gives Abort.",width=560,height=210)
g=lambda t:(t,"good");b=lambda t:(t,"bad")
forget=lanes([("A",["-","-",g("Y @2"),g("Y @2"),g("Y @2")]),("B",[("X @1","accent"),("X @1","accent"),("X @1","accent"),g("Y @2"),g("Y @2")]),("C",["-","-","-","-",b("X @1")]),
 ("chosen",["-","-","-",g("Y"),b("Y and X")])],
 "Last vote of acceptors A, B, C across states 8, 9, 11, 12, 13 of TLC's trace. B votes X in ballot 1 and reports it in state 9. A and B then vote Y in ballot 2, so Y is chosen. C votes X in ballot 1 in state 13, so X is chosen too.",
 cols=["state 8","state 9","state 11","state 12","state 13"],cell=84,labelw=60)
log=lanes([("S1",["set a","pay b","add c","del d"]),("S2",["set a","pay b","add c",None]),("S3",["set a","pay b",None,None])],
 "Three replica logs by position. All agree where filled; S2 lacks position 4 and S3 lacks 3 and 4.",cols=["pos 1","pos 2","pos 3","pos 4"],cell=70,labelw=40)
FIGS={"ins":(ins,"Paxos Commit is one consensus per RM plus a rule on the results."),
"forget":(forget,"TLC's trace with the broken rule. X @1 means \"voted X in ballot 1\". State 10 sends ballot 2's Y."),
"log":(log,"A sketch, not a checked model. Each column is its own consensus decision.")}
