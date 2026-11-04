import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
FIGS={
"levels":(regions([
 (8,8,664,250,"Temporal: true or false of a whole behavior","muted"),
 (32,44,616,202,"Action: has a value on a step (a pair of states)"),
 (56,80,568,154,"State: has a value on one state","good"),
 (80,116,520,106,"Constant: has the same value on every state","accent"),
],"Four nested kinds of expression. Constant expressions sit inside state expressions, which sit inside action expressions, which sit inside temporal formulas.",width=680,height=266,notes=[
 (340,172,"2 + 2      foo \\cup {n \\in 1..22 : n^2 > m}"),
 (340,200,"may appear in ASSUME"),
 (520,95,"x + y[foo]"),
 (560,59,"p - q'"),
 (570,23,"[]TPTypeOK"),
]),"Each kind contains the one inside it. The further out you go, the more of the behavior you must see to get a value."),
"trace":(lanes([
 ("step",[None,"Prep r1","Rcv r1","Prep r2","Rcv r2","Commit","Got r2","Got r1"]),
 ("rmState[r1]",["w","p","p","p","p","p","p",("c","good")]),
 ("rmState[r2]",["w","w","w","p","p","p",("c","good"),("c","good")]),
 ("tmState",["init","init","init","init","init","done","done","done"]),
 ("tmPrepared",["{}","{r1}","{r1}","{r1}","{r1,r2}","{r1,r2}","{r1,r2}","{r1,r2}"]),
 ("TPSpec checks",[("TPInit","accent"),"TPNext","TPNext","TPNext","TPNext","TPNext","TPNext","TPNext"]),
],"A real TLC trace of TwoPhase with two resource managers, eight states. TPInit is checked on the first state and TPNext on each of the seven steps.",cols=["s1","s2","s3","s4","s5","s6","s7","s8"]),
"A real TwoPhase behavior from TLC with RM = {r1, r2} (w = working, p = prepared, c = committed). <code>TPInit</code> looks only at s1. Each <code>TPNext</code> cell judges the step that arrives in that column."),
"stutter":(lanes([
 ("step",[None,"Prep r1","stutter","stutter","tm done"]),
 ("rmState[r1]",["w","p",("p","muted"),("p","muted"),"p"]),
 ("tmState",["init","init",("init","muted"),("init","muted"),("done","bad")]),
 ("msgs",["{}","{P r1}",("{P r1}","muted"),("{P r1}","muted"),("{P r1}","bad")]),
 ("[TPNext]_vars",[None,("true","good"),("true","good"),("true","good"),("false","bad")]),
],"A behavior with one TPNext step, two stuttering steps that change no variable, and a final step that sets tmState to done without sending any message, which is rejected.",cols=["s1","s2","s3","s4","s5"]),
"Stuttering steps repeat the state and are allowed. The last step is not stuttering and is not a <code>TPNext</code> step: <code>tmState</code> changed but no Commit or Abort message was sent, so the formula is false on this behavior."),
"deadlock":(graph({
 "s":(90,92,"pc = start\ni = 0"),
 "m":(320,92,"pc = middle\ni = 43"),
 "d":(550,92,"pc = done\ni = 44","accent"),
},[
 ("s","m","Next"),("m","d","Next"),
 ("s","s","stutter",{"dash":True}),("m","m","stutter",{"dash":True}),("d","d","stutter",{"dash":True}),
],"Three states of SimpleProgram. Solid Next arrows go from start to middle to done. Every state also has a dashed stuttering loop. The done state has no solid Next arrow leaving it, which is what TLC reports as a deadlock.",width=640,height=130),
"Solid arrows are <code>Next</code> steps. Dashed loops are the stuttering steps the formula also allows. TLC's deadlock report counts only solid arrows, so <code>done</code> is reported."),
}
FIGS={k:(s.replace('id="dg-a"',f'id="dg-a-tm-{k}"').replace('url(#dg-a)',f'url(#dg-a-tm-{k})'),c) for k,(s,c) in FIGS.items()}
