import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
normal=sequence(["r1","TM","r2"],[("r1","TM","Prepared (r1)"),("note","TM","tmPrepared = {r1}"),("r2","TM","Prepared (r2)"),("note","TM","tmPrepared = {r1, r2}: TMCommit"),
 ("TM","r1","Commit",{"tone":"good"}),("TM","r2","Commit",{"tone":"good"})],
 "Message sequence: r1 and r2 each send Prepared to the TM, which adds them to tmPrepared, then sends Commit, which both receive.",gap=210,step=40)
abort=sequence(["r1","TM","r2"],[("note","r2","r2: RMChooseToAbort, no message","bad"),("r1","TM","Prepared (r1)"),("note","r1","r1 prepared: must wait"),("note","TM","tmPrepared = {r1}: TMAbort"),
 ("TM","r1","Abort",{"tone":"bad"})],
 "Message sequence with an abort: r2 aborts without sending a message, r1 sends Prepared, the TM aborts on its own and sends Abort, which r1 receives.",gap=210,step=40)
swap=lanes([("r1",[("working","accent"),("committed","muted")]),("r2",["prepared","prepared"]),("r3",[("committed","muted"),("working","accent")])],
 "A state and the state obtained by swapping r1 and r3. r1 and r3 exchange values while r2 stays the same.",cols=["a state","r1 and r3 swapped"],cell=150,labelw=50)
FIGS={"normal":(normal,"The normal case. Each message stays in msgs after it's read."),
"abort":(abort,"An RM aborts. r2's choice is not a message; the TM aborts on its own. r2 is already aborted, so it needn't read the Abort."),
"swap":(swap,"Exchanging two RMs in a reachable state gives a reachable state, so TLC can treat the two as one case.")}
