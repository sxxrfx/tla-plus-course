import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
g=lambda t:(t,"good");b=lambda t:(t,"bad");a=lambda t:(t,"accent")
clock=lanes([("hr",["13","13","14","14"]),("min",["58","59","00","01"]),("HSpec sees",[None,"stutter",g("HNext"),"stutter"])],
 "Four states of the dashboard: 13:58, 13:59, 14:00, 14:01. Only the step from 13:59 to 14:00 changes hr, and it is an HNext step; the other two steps leave hr unchanged and are stuttering steps of the hour spec.",
 cols=["state 1","state 2","state 3","state 4"],cell=100,labelw=100)
dialog=graph({"c":(70,110,"closed","accent"),"o":(250,40,"open"),"s":(470,110,"submitting"),"e":(250,180,"error")},
 [("c","o","Open",{"bend":-22}),("o","c","Cancel",{"bend":-22}),("o","s","Confirm"),("s","c","Succeed",{"ly":-2}),("s","e","Fail",{"bend":26}),("e","s","Retry",{"bend":26}),("e","c","Cancel")],
 "State graph of the dialog. closed goes to open by Open. open goes to closed by Cancel and to submitting by Confirm. submitting goes to closed by Succeed and to error by Fail. error goes to submitting by Retry and to closed by Cancel.",width=560,height=215)
behaviors=lanes([("B1",["closed","open","submitting","closed","stutter"]),("B2",["closed","open","submitting","open","stutter"]),
 ("B3",["open","submitting","error","closed","stutter"]),("B4",["closed","closed","closed","closed","stutter"])],
 "Four behaviors of the dialog variable. B1: closed, open, submitting, closed. B2: closed, open, submitting, open. B3: open, submitting, error, closed. B4 stays closed. Each then stutters forever.",
 cols=["state 1","state 2","state 3","state 4","then"],cell=104,labelw=40)
cache=lanes([("store[k1]",["v2","v2",a("v1"),"v1"]),("cache[k1]",["miss",a("v2"),"v2","v2"]),("out",["none","none","none",b("v2")]),
 ("KVSpec sees",[None,"stutter","Put","not a Get"])],
 "TLC's trace for BugSpec. State 2: Fill copies v2 into the cache, a stuttering step. State 3: the store becomes v1 but the cache keeps v2, a Put step. State 4: Get returns v2 while the store holds v1, which no KV step allows.",
 cols=["state 1","Fill","PutNoInv.","Get"],cell=104,labelw=100)
heur=lanes([("flight",["prepared",b("aborted"),"aborted","aborted",b("committed")]),("hotel",["prepared","prepared","prepared","prepared","prepared"]),
 ("car",["working","working","prepared","prepared","prepared"]),("TM",["init","init","init",a("Commit sent"),"Commit sent"]),
 ("Agreement",[None,g("Decide"),"Prepare","stutter",b("rejected")])],
 "Five states from TLC's trace for OpsSpec. After the TM has recorded flight and hotel as prepared, the operator aborts flight, which agreement allows. Car prepares. The TM commits, a stuttering step for agreement. Flight then receives Commit and goes from aborted to committed, which agreement rejects.",
 cols=["state 5","state 6","state 7","state 9","state 10"],cell=112,labelw=86)
FIGS={"clock":(clock,"From the hour spec's point of view, the minute ticks are steps where nothing happens."),
"dialog":(dialog,"The dialog's Next. There is no arrow from submitting to open, which is what NoReopenWhileBusy checks."),
"behaviors":(behaviors,"Four behaviors to evaluate, one per row. After the last column each repeats its final state forever."),
"cache":(cache,"The bug is in the third state, but KVSpec rejects only the fourth, when a client sees the stale copy."),
"heur":(heur,"The operator's step is a legal abort. The coordinator's commit was already determined by what it had recorded, and the failure shows up only at a receipt.")}
