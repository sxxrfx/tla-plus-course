import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
rm=graph({"w":(220,30,"working","accent"),"p":(220,110,"prepared"),"c":(80,195,"committed","good"),"a":(360,195,"aborted","bad")},
 [("w","p","Prepare"),("p","c","commit"),("p","a","abort"),("w","a","abort",{"bend":-35,"lx":10})],
 "State machine of one resource manager. Working goes to prepared or aborted. Prepared goes to committed or aborted. Committed and aborted have no outgoing arrows.",width=440,height=225)
X={"a":60,"w":195,"p":330,"c":465};Y={"a":30,"w":110,"p":190,"c":270}
n=lambda s:(X[s[0]],Y[s[1]],s[0]+","+s[1])
good=["ww","wp","wa","pw","pp","pa","pc","aw","ap","aa","cp","cc"]
N={s:n(s) for s in good};N["ww"]=N["ww"]+("accent",)
for s in ("ac","ca"): N[s]=n(s)+("bad",)
for s in ("cc",): N[s]=N[s]+("good",)
for s in ("aa",): N[s]=N[s]+("muted",)
E=[("ww","pw"),("ww","aw"),("pw","aw",""),("wp","pp"),("wp","ap"),("pp","cp",""),("pp","ap",""),("wa","pa"),("wa","aa"),("pa","aa",""),("pc","cc"),
 ("ww","wp"),("ww","wa"),("wp","wa",""),("pw","pp"),("pw","pa"),("pp","pc"),("pp","pa",""),("aw","ap"),("aw","aa"),("ap","aa",""),("cp","cc")]
ed=[]
for e in E:
    a,b=e[0],e[1]
    jump=(a[0]=="p" and b[0]=="a" and a[1]==b[1]) or (a[1]=="p" and b[1]=="a" and a[0]==b[0])
    ed.append((a,b,"",{"bend":-72} if jump else {}))
pairs=graph(N,ed,"Every reachable state of two resource managers on a grid, with arrows for each single step. Twelve states are reachable from w,w. The states a,c and c,a are shown in red with no arrows into them.",width=520,height=300,mono=True)
L=lambda *a:list(a)
g=lambda t:(t,"good");b=lambda t:(t,"bad")
trace=lanes([("r1 real",L("working","prepared","prepared","prepared",g("committed"),g("committed"),g("committed"))),
 ("r2 real",L("working","working","prepared","prepared","prepared",g("committed"),g("committed"))),
 ("r3 real",L("working","working","working","prepared","prepared","prepared",g("committed"))),
 ("r1 broken",L("working","prepared","prepared","prepared",b("committed"),b("committed"))),
 ("r2 broken",L("working","working","prepared","prepared","prepared",b("aborted"))),
 ("r3 broken",L("working","working","working","prepared","prepared","prepared"))],
 "Two behaviors of three resource managers state by state. In the real spec all three commit. In the broken spec, r1 commits and then r2 aborts in state 6.",cols=L("1","2","3","4","5","6","7"),cell=84,labelw=78)
FIGS={"rm":(rm,"The states of one RM. The lecture draws the same machine for a wedding participant, with \"unsure\" in place of \"working\"."),
"pairs":(pairs,"All reachable states for RM = {r1, r2}: w, p, c, a stand for working, prepared, committed, aborted; each label is r1's state, then r2's. Red: states TCConsistent forbids. Nothing leads to them."),
"trace":(trace,"Top: a behavior of TCommit. Bottom: TLC's 6-state error trace with notCommitted deleted.")}
