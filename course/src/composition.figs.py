import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
grid=graph({"oo":(70,110,"x=0, y=0"),"xo":(300,40,"x=1, y=0"),"oy":(300,180,"x=0, y=1"),"xy":(540,110,"x=1, y=1")},
 [("oo","xo","A"),("oo","oy","B"),("xo","xy","B"),("oy","xy","A"),("oo","xy","both at once",{"dash":True,"tone":"accent"})],
 "The four states of two one-bit components. Interleaving allows the four solid steps. Letting each component constrain only its own variable adds the dashed step where both move.")
subst=graph({"v":(80,30,"Values"),"c":(80,90,"Capacity"),"q":(80,150,"q"),"j":(330,30,"Jobs"),"t":(330,90,"2"),"p":(330,150,"pending")},
 [("v","j","<-"),("c","t","<-"),("q","p","<-")],"INSTANCE substitutions: BoundedFIFO's parameters Values, Capacity and q are each replaced by JobQueue's Jobs, 2 and pending.",mono=True)
seq=sequence(["Input","Server","Screen"],[
 ("Input","Server","“ca”: r1, gen 1"),("Input","Server","“cat”: r2, gen 2"),("Server","Screen","r2 arrives first"),
 ("note","Screen","shows gen 2","good"),("Server","Screen","r1 arrives late",{"tone":"bad"}),
 ("note","Screen","no guard: shows gen 1","bad"),("note","Screen","with guard: dropped","good")],
 "Two requests are sent in order and the responses arrive reversed. Without a generation guard the late response replaces the current results.",gap=230,step=38)
FIGS={"grid":(grid,"Two components, one bit each. <code>Interleaved</code> has only the solid steps. <code>OwnVars</code> also has the dashed one. <code>Conjoined</code> has none of these: it never leaves x=0, y=0."),
"subst":(subst,"What <code>INSTANCE … WITH</code> does: every occurrence of the left name in <code>BoundedFIFO</code> is read as the right one."),
"seq":(seq,"Each component behaved as specified. The composition is wrong in the red step, and the guard is the contract that repairs it.")}
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-cmp-{k}\"").replace("#dg-a)",f"#dg-a-cmp-{k})"),v[1]) for k,v in FIGS.items()}
