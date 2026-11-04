import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
S=("stutter","muted")
FIGS={
"two":(lanes([
 ("TwoPhase step",[None,"Prep r1","Rcv r1","Prep r2","Rcv r2","Commit","Got r2","Got r1"]),
 ("rmState[r1]",["w",("p","accent"),"p","p","p","p","p",("c","accent")]),
 ("rmState[r2]",["w","w","w",("p","accent"),"p","p",("c","accent"),"c"]),
 ("TCSpec sees",[None,("Prepare","accent"),S,("Prepare","accent"),S,S,("Decide","accent"),("Decide","accent")]),
],"The real TwoPhase trace from the previous lesson. Steps that change rmState are Prepare or Decide steps of TCommit. Steps that change only the transaction manager's variables are stuttering steps of TCSpec.",cols=["s1","s2","s3","s4","s5","s6","s7","s8"],labelw=112),
"One TwoPhase behavior read through <code>rmState</code> alone. Outlined cells are <code>TCNext</code> steps. The others leave <code>rmState</code> alone, so they are stuttering steps of TCSpec, even though TwoPhase is hard at work in them."),
"universe":(regions([
 (8,8,664,214,"One state: a value for every possible variable","muted"),
 (30,44,400,160,"TPSpec constrains these"),
 (52,84,180,104,"TCSpec constrains","accent"),
],"A state assigns values to all variables. TCSpec constrains rmState. TPSpec constrains rmState, tmState, tmPrepared and msgs. Other variables such as Mozart are constrained by neither.",width=680,height=230,notes=[
 (142,134,"rmState"),
 (330,110,"tmState"),(330,136,"tmPrepared"),(330,162,"msgs"),
 (550,90,"Mozart"),(550,120,"numberOfCustomers..."),(550,150,"infinitely many more"),
]),"Both formulas talk about the same kind of state. Each one simply says nothing about the variables it doesn't mention."),
"abort":(lanes([
 ("step",[None,"TMAbort"]),
 ("rmState",["w, w, w","w, w, w"]),
 ("tmState",["init","done"]),
 ("msgs",["{}","{Abort}"]),
 ("[TCNext]_rmState",[None,("true: stutter","good")]),
 ("[TCNext]_<<all 4>>",[None,("false","bad")]),
],"TLC's two-state counterexample. A TMAbort step leaves rmState unchanged, so it satisfies TCNext subscript rmState but not TCNext subscript of all four variables.",cols=["State 1","State 2"],labelw=150),
"TLC's counterexample when the only stuttering permitted is that of all four variables. <code>TMAbort</code> is a perfectly good two-phase commit step that <code>TCNext</code> does not contain."),
"bug":(lanes([
 ("step",[None,"TMCommit","Got r1"]),
 ("rmState[r1]",["w","w",("c","bad")]),
 ("rmState[r2]",["w","w","w"]),
 ("tmPrepared",["{}","{}","{}"]),
 ("msgs",["{}","{Commit}","{Commit}"]),
 ("TCSpec",[None,("stutter","muted"),("rejected","bad")]),
],"TLC's counterexample for TwoPhaseBad. The buggy TMCommit fires with nobody prepared, which TCSpec sees as stuttering. Then r1 goes from working to committed, which no TCNext step allows.",cols=["State 1","State 2","State 3"]),
"TLC's counterexample for the bug. The broken step itself is invisible to TCSpec. The violation appears one step later, when <code>rmState</code> moves from working straight to committed."),
"stop":(lanes([
 ("terminates",["start,0","middle,43","done,44",("done,44","muted"),("done,44","muted"),("...","muted")]),
 ("pauses",["start,0",("start,0","muted"),"middle,43",("middle,43","muted"),"done,44",("...","muted")]),
 ("stops early",["start,0","middle,43",("middle,43","bad"),("middle,43","bad"),("middle,43","bad"),("...","bad")]),
],"Three infinite behaviors of SimpleProgram, each shown as pc and i. One terminates and stutters forever at done. One pauses but finishes. One stutters forever at middle.",cols=["s1","s2","s3","s4","s5","s6..."]),
"Three behaviors that all satisfy <code>Init /\\ [][Next]_&lt;&lt;pc, i&gt;&gt;</code>; each cell is pc, i. Termination is an infinite tail of stuttering. So is stopping early, which the formula does not forbid."),
}
FIGS={k:(s.replace('id="dg-a"',f'id="dg-a-imp-{k}"').replace('url(#dg-a)',f'url(#dg-a-imp-{k})'),c) for k,(s,c) in FIGS.items()}
