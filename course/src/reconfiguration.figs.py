import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
disjoint=regions([
 (20,14,340,190,"Old: {A,B,C}","muted"),(250,14,340,190,"New: {C,D,E}","muted"),
 (44,70,180,90,"old quorum","bad"),(262,70,190,90,"new quorum","bad"),
],"Two overlapping boxes: old configuration A, B, C and new configuration C, D, E share node C. The old quorum A, B and the new quorum C, D do not overlap.",width=610,height=220,notes=[
 (90,125,"A"),(180,125,"B"),(300,125,"C"),(410,125,"D"),(530,125,"E")])
joint=regions([
 (20,14,340,216,"Old: {A,B,C}","muted"),(250,14,340,216,"New: {C,D,E}","muted"),
 (40,56,170,126,"decided","accent"),
 (140,100,310,110,"joint ack","good"),
],"Five nodes in a row, B, A, C, D, E, inside the old and new configurations. The decided old quorum surrounds B and A. The joint acknowledgement set surrounds A, C and D. The two sets overlap at A.",width=610,height=240,notes=[
 (85,155,"B"),(175,155,"A"),(300,155,"C"),(410,155,"D"),(530,155,"E")])
phases=graph({
 "o":(70,120,"old\nmajority of Old"),"j":(320,120,"joint\nmajority of each","accent"),"n":(590,120,"new\nmajority of New","good"),
},[
 ("o","j","EnterJoint\nstops old-only"),
 ("j","n","Activate if a\nNew majority\nholds decided"),
 ("o","n","Direct: Activate with no guard",{"bend":-80,"tone":"bad","dash":True}),
],"Phase diagram. Old goes to joint through EnterJoint, then joint goes to new through Activate, which requires a majority of New to hold each decided value. A dashed red arrow shows the Direct design jumping from old to new with no guard.",width=680,height=170)
trace=lanes([
 ("phase",["old","old","old","old","old",("new","accent"),"new","new"]),
 ("A",["-","X","X","X","X","X","X","X"]),("B",["-","-","X","X","X","X","X","X"]),
 ("C",["-","-","-","Y","Y","Y","Y","Y"]),("D",["-","-","-","-","-","-","Y","Y"]),("E",["-","-","-","-","-","-","-","-"]),
 ("decided",["{}","{}","{}","{}",("X","good"),"X","X",("X,Y","bad")]),
],"TLC trace for Direct: A and B store X, C stores Y, X is decided under Old, the phase becomes new, D stores Y, and Y is decided under New with C and D. Decided ends as both X and Y.",cols=["Init","A:=X","B:=X","C:=Y","Decide","Activate","D:=Y","Decide"],labelw=70,cell=72,rowh=30)
shard=sequence(["Old client","A + B","D + E","New client"],[
 ("A + B","D + E","copy: stock = 3"),
 ("Old client","A + B","reserve 1 (r1)"),
 ("A + B","Old client","ok"),
 ("note","D + E","route switches"),
 ("New client","D + E","reserve 3 (r2)"),
 ("D + E","New client","ok"),
 ("note","D + E","4 acked, 3 in stock","bad"),
],"The snapshot of stock 3 is copied to D and E. A and B acknowledge r1 for one unit. After the route switches, D and E acknowledge r2 for three units, for four units acknowledged out of three.",gap=190,step=38)
FIGS={"disjoint":(disjoint,"Node C is in both configurations, but the old quorum does not use it. The two red quorums share nothing."),
"joint":(joint,"Any joint acknowledgement holds a majority of Old, so it must contain A or B. Here the two sets overlap at A."),
"phases":(phases,"The safe path has two guards. The dashed path is the handoff that fails."),
"trace":(trace,"TLC’s counterexample for <code>Direct</code>. C is the shared member and it did not help: it was outside the old quorum, then inside the new one."),
"shard":(shard,"The worked example. Each cluster’s local majority was satisfied; the overselling only appears in the global total.")}
