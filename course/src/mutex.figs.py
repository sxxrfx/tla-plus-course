import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
_b={"tone":"bad"}
X=[130,370,610];Y=[80,210,340]
g=graph({
 "oo":(X[0],Y[0],"A out, B out\nfree"),"wo":(X[1],Y[0],"A wait, B out\nfree","bad"),"co":(X[2],Y[0],"A crit, B out\nowner A"),
 "ow":(X[0],Y[1],"A out, B wait\nfree"),"ww":(X[1],Y[1],"A wait, B wait\nfree","bad"),"cw":(X[2],Y[1],"A crit, B wait\nowner A"),
 "oc":(X[0],Y[2],"A out, B crit\nowner B"),"wc":(X[1],Y[2],"A wait, B crit\nowner B","bad"),"cc":(X[2],Y[2],"A crit, B crit\nunreachable","muted"),
},[("oo","wo","req A"),("wo","co","acq A"),("ow","ww","req A"),("ww","cw","acq A"),("oc","wc","req A"),
   ("oo","ow","req B"),("ow","oc","acq B"),("wo","ww","req B",_b),("ww","wc","acq B",_b),("co","cw","req B"),
   ("co","oo","rel A",{"bend":70}),("cw","ow","rel A",{"bend":70,"lx":120}),
   ("oc","oo","rel B",{"bend":-140,"ly":-90}),("wc","wo","rel B",{"bend":-140,"tone":"bad","ly":45})],
 "All 8 reachable states of the two-process lock, in a grid by each process's stage. The ninth position, both critical, is unreachable. A red cycle shows B repeatedly acquiring and releasing while A waits.")
race=lanes([("pc[A]",["outside","outside","saw-free","critical",("critical","bad")]),("pc[B]",["outside","saw-free","saw-free","saw-free",("critical","bad")]),
 ("owner",["none","none","none","A","B"])],"TLC's trace for a lock that checks then sets: both processes see it free, then both take it.",cols=["Init","Look B","Look A","Take A","Take B"],cell=80)
seq=sequence(["Request A","Lock","Stock","Request B"],[
 ("Request A","Lock","acquire"),("Request A","Stock","read: 1"),("note","Request B","acquire disabled","muted"),("Request A","Stock","reserve"),("Request A","Lock","release"),
 ("Request B","Lock","acquire"),("Request B","Stock","read: 0")],
 "Request A holds the lock across the read and the reservation. Request B's acquire is disabled until A releases, so B then reads zero stock.",gap=165,step=38)
FIGS={"grid":(g,"All 8 reachable states. Columns are A’s stage, rows are B’s. Both critical is the empty corner: no edge goes there. The red cycle is the starvation TLC finds: B keeps winning while A waits."),
"race":(race,"TLC’s trace when the check and the set are separate steps. The last column has two processes in the critical section."),
"seq":(seq,"The critical section includes the decision and the update. Locking only the read would leave the reservation race open.")}
# Markers live per SVG: hidden lessons would otherwise hold the only #dg-a that url() resolves to, and arrowheads vanish.
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-mutex-{k}\"").replace("#dg-a)",f"#dg-a-mutex-{k})"),v[1]) for k,v in FIGS.items()}
