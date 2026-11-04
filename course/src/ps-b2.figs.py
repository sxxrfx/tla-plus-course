import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
G="good"
cti=graph({"r0":(48,50,"a=2 b=1\nnew new",G),"r1":(205,50,"a=1 b=1\ndeb new",G),"r2":(362,50,"a=1 b=2\ncred new",G),"r3":(519,50,"a=1 b=0\ncred deb",G),"r4":(674,50,"a=3 b=0\ncred cred",G),
 "x":(205,190,"a=0 b=2\nnew deb","accent"),"y":(519,190,"a=2 b=2\nnew cred","bad")},
 [("r0","r1","Debit(1)"),("r1","r2","Credit(1)"),("r2","r3","Debit(2)"),("r3","r4","Credit(2)"),("x","y","Credit(2)",{"tone":"bad","dash":True})],
 "Top row: the five reachable states of the ledger, alice's and bob's balances and the status of transfers 1 and 2. Bottom: an unreachable state where the sum is 2 and transfer 2 is debited; Credit(2) leads to a sum of 4, violating NoMint.",width=720,height=230)
sym=graph({"p":(150,70,"admin c1: waiting\nc2: busy (k1)\nc3: busy (k2)","bad"),"q":(520,70,"c2: waiting\nadmin c1: busy (k1)\nc3: busy (k2)","good")},
 [("p","q","swap c1, c2",{"bend":-30}),("q","p","swap c1, c2",{"bend":-30})],
 "Two states of the buggy pool that a symmetry over all clients treats as one. In the left one the admin waits with no free connection, which violates AdminCanConnect. In the right one the invariant holds.",width=680,height=170)
comp=graph({"s0":(95,120,"reqs 0  served 0\ntokens 2"),"s1":(350,45,"reqs 1  served 0\ntokens 2"),"s2":(600,45,"reqs 1  served 1\ntokens 1","good"),"sx":(350,205,"reqs 1  served 0\ntokens 1","bad")},
 [("s0","s1","Send"),("s1","s2","Admit"),("s0","sx","Send and Take at once",{"tone":"bad","dash":True})],
 "From the initial state, the composed gateway takes Send, then Admit, which spends a token as a request is served. The naive conjunction also allows a single step in which the client sends and the bucket loses a token for nothing.",width=700,height=250)
proof=graph({"t":(360,30,"Spec ⇒ []NoLostUpdate"),"a":(110,110,"⟨1⟩1 Init ⇒ Inv"),"b":(360,110,"⟨1⟩2 Inv ∧ [Next] ⇒ Inv′","accent"),"c":(610,110,"⟨1⟩3 Inv ⇒ NoLostUpdate"),
 "s":(85,205,"Select"),"u":(275,205,"Update","accent"),"m":(445,205,"Commit"),"z":(625,205,"stutter / Terminating"),"k":(275,285,"⟨3⟩ CardAdd: Paid grows by one")},
 [("t","a"),("t","b"),("t","c"),("b","s"),("b","u"),("b","m"),("b","z"),("u","k")],
 "The proof tree. The top claim splits into the three invariance obligations. The step case splits into one case per action, and only Update needs its own sub-steps, about the cardinality of Paid.",width=720,height=310)
FIGS={"cti":(cti,"The reachable states in green, and the counterexample to induction that TLC finds for <code>TypeOK /\\ NoMint</code>, which starts outside them."),
"sym":(sym,"One symmetry class, two members. TLC explores one member of each class, so whether it ever checks the violating one depends on the order of the search, and here it never does."),
"compose":(comp,"The solid path is the composed gateway. The dashed step is allowed only by the naive composition, and it breaks <code>TokensAccounted</code> at once."),
"proof":(proof,"The structure of the proof in the solution. Each leaf is one obligation small enough to discharge by expanding definitions.")}
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-psb2-{k}\"").replace("#dg-a)",f"#dg-a-psb2-{k})"),v[1]) for k,v in FIGS.items()}
