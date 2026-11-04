import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
_d={"tone":"bad","dash":True}
_g={"tone":"good","dash":True}
windows=graph({
 "l1":(62,40,"Effect\nfirst","muted"),"a0":(190,40,"effects 0\nno ID"),"a1":(385,40,"effects 1\nno ID"),"a2":(610,40,"effects 2","bad"),
 "l2":(62,130,"ID\nfirst","muted"),"b0":(190,130,"effects 0\nno ID"),"b1":(385,130,"effects 0\nID saved"),"b2":(610,130,"\"done\"\neffects 0","bad"),
 "l3":(62,220,"Atomic","muted"),"c0":(190,220,"effects 0\nno ID"),"c1":(385,220,"effects 1\nID saved"),"c2":(610,220,"saved reply\neffects 1","good"),
},[
 ("a0","a1","charge"),("a1","a2","crash, retry",_d),
 ("b0","b1","save ID"),("b1","b2","crash, retry",_d),
 ("c0","c1","commit both"),("c1","c2","crash, retry",_g),
],"Three rows, one per design. Effect first: a crash after the charge makes the retry charge again, reaching effects 2. ID first: a crash after saving the ID makes the retry reply done with effects 0. Atomic: the crash leaves effects 1 with the ID saved, and the retry returns the saved reply.",width=700)
bad=lanes([("effects",["0","1","1",("2","bad")]),("seen",["FALSE","FALSE","FALSE","FALSE"]),("pc",["idle","record",("idle","accent"),"record"])],
 "TLC trace for EffectFirst: Begin sets effects to 1, Crash returns pc to idle, and Begin sets effects to 2 because seen is still FALSE.",cols=["Init","Begin","Crash","Begin"],labelw=80,cell=84)
good=lanes([("effects",["0","1","1","1","1"]),("seen",["FALSE","TRUE","TRUE","TRUE","TRUE"]),("pc",["idle","reply",("idle","accent"),"reply","idle"]),("replied",["FALSE","FALSE","FALSE","FALSE",("TRUE","good")])],
 "The same crash in the Atomic design: Begin sets effects 1 and seen TRUE together, Crash returns pc to idle, Begin finds seen TRUE and moves to reply without charging, then Reply tells the client.",cols=["Init","Begin","Crash","Begin","Reply"],labelw=80,cell=84)
race=sequence(["Worker 1","Store","Worker 2"],[
 ("Worker 1","Store","read r42: unseen"),
 ("Worker 2","Store","read r42: unseen"),
 ("Worker 1","Store","commit credit + ID"),
 ("note","Store","effects = 1"),
 ("Worker 2","Store","commit credit + ID",{"tone":"bad"}),
 ("note","Store","effects = 2","bad"),
],"Two workers both read r42 as unseen, then each commits a credit with no recheck, so effects reaches 2 with no crash.",gap=200)
receipt=sequence(["Queue","Worker","Store"],[
 ("Queue","Worker","deliver r42"),
 ("note","Worker","OCR (volatile)"),
 ("Worker","Store","commit credit + result"),
 ("note","Worker","crash before ack","bad"),
 ("Worker","Queue","ack r42",{"lost":True,"tone":"bad"}),
 ("Queue","Worker","redeliver r42",{"dash":True}),
 ("Worker","Store","read r42"),
 ("Store","Worker","saved result",{"tone":"good"}),
 ("Worker","Queue","ack r42",{"tone":"good"}),
],"Receipt job r42: the worker commits the credit and result in one transaction, crashes before acknowledging, and the redelivery reads the saved result rather than crediting again.",gap=200,step=38)
FIGS={"windows":(windows,"The gap between two durable writes is where a crash lands. Only the third row has no gap, so a retry finds either nothing or everything."),
"bad":(bad,"TLC’s counterexample for the effect-first design. The crash erases pc; nothing durable says the charge happened."),
"good":(good,"The same crash against the atomic design, stepped by hand through the module’s actions. The second Begin reads <code>seen</code> and skips the charge."),
"race":(race,"TLC’s two-worker counterexample, drawn as messages. Nothing crashed: the check and the commit were separate steps."),
"receipt":(receipt,"A crash after the commit costs one repeated read. The dashed redelivery is harmless because the store already holds the answer.")}
