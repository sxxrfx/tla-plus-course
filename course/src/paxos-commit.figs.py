import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
block=sequence(["r1","TM","r2"],[("note","TM","TMCrash","bad"),("r1","TM","Prepared (r1)",{"lost":True}),("r2","TM","Prepared (r2)",{"lost":True}),("note","r1","r1: prepared, stuck","bad"),("note","r2","r2: prepared, stuck","bad")],
 "The TM crashes. r1 and r2 send Prepared but it's never read. Both are prepared with no action enabled.",gap=210,step=40)
backup=sequence(["r1","TM","Backup","r2"],[("r1","TM","Prepared"),("r2","TM","Prepared"),("note","TM","TMCommit: decides"),("TM","r1","Commit",{"tone":"good"}),("note","Backup","BackupAbort: thinks TM died","bad"),("Backup","r2","Abort",{"tone":"bad"}),("note","r2","r1 committed, r2 aborted","bad")],
 "Both RMs send Prepared to the TM, which commits; r1 receives Commit. The backup TM broadcasts Abort and r2 receives it. r1 is committed and r2 aborted.",gap=175,step=40)
flow=sequence(["r1","a1","a2","a3","Leader"],[("r1","a1","phase2a bal 0"),("r1","a2","phase2a bal 0"),("note","a3","a3: slow"),("a1","Leader","phase2b"),("a2","Leader","phase2b"),("note","Leader","r1: prepared chosen","good"),("Leader","r1","Commit*",{"tone":"good"})],
 "r1 sends a ballot 0 phase 2a message to acceptors a1 and a2, each sends a phase 2b message to the leader, and the value prepared is chosen although a3 is slow. The leader then sends Commit.",gap=140,step=40)
overlap=regions([(10,28,210,120,"voted: {a1, a2}","good"),(120,70,210,120,"polled: {a2, a3}","accent"),
 (370,28,140,120,"voted: {a3}","bad"),(530,70,140,120,"polled: {a1, a2}","accent")],
 "Left: acceptors a1 and a2 voted and a leader polled a2 and a3, so a2 is in both. Right: only a3 voted and the leader polled a1 and a2, so the sets don't overlap.",width=680,height=230,
 notes=[(65,110,"a1"),(170,125,"a2","good"),(270,150,"a3"),(440,100,"a3"),(575,130,"a1"),(630,130,"a2"),(170,212,"a2 reports its vote","good"),(520,212,"no one reports a3's vote","bad")])
FIGS={"block":(block,"Two-phase commit with a crashed TM. Prepared RMs may not decide alone, so they wait forever."),
"backup":(backup,"TLC's 9-state trace with one takeover. Backup doesn't know the TM has already decided, so both decisions go out. Steps not shown: the TM reading the two Prepared messages."),
"flow":(flow,"Normal case for r1's instance. *Commit requires every RM's instance to have chosen prepared; r2's instance runs the same way."),
"overlap":(overlap,"Left: overlap carries the vote into the new ballot. Right: with the broken Majority, a vote in {a3} can't be seen from {a1, a2}.")}
