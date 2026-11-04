import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
abort=sequence(["Input","Combobox","Network"],[
 ("Input","Combobox","type \"al\""),
 ("Combobox","Network","fetch 1 (\"al\")"),
 ("Network","Combobox","response 1 read"),
 ("note","Combobox","callback 1 queued"),
 ("Input","Combobox","type \"ali\""),
 ("Combobox","Network","abort in-flight: none left",{"tone":"bad"}),
 ("Combobox","Network","fetch 2 (\"ali\")"),
 ("note","Combobox","callback 1 renders \"al\"","bad"),
],"TLC's Abort trace: request 1's response is read and its callback queued; the second keystroke aborts what is still on the network, which no longer includes request 1; the queued callback then renders the options for al.",gap=260,step=38)
lease=sequence(["Reader","Cache","Database","Writer"],[
 ("Reader","Cache","GET: miss, lease 1"),
 ("Reader","Database","SELECT: v1"),
 ("Writer","Database","UPDATE: v2"),
 ("Writer","Cache","DELETE: lease void"),
 ("Reader","Cache","SET v1 with lease 1",{"tone":"good"}),
 ("note","Cache","lease 0 # 1: refused","good"),
],"The task 1 interleaving with leases on: the reader's lease is issued at the miss, the writer's delete after the update voids it, and the reader's stale SET is refused.",gap=190,step=38)
lsn=lanes([("primary",["0","1","1","1","1"]),("replay[r1]",["0","0","1","1","1"]),("replay[r2]",["0","0","0","0","0"]),("token",["0","0","0","0","0"]),("last",["0","0","0",("1","accent"),("0","bad")]),("before",["0","0","0","0",("1","bad")])],
 "TLC's WriteLsn trace: another session commits LSN 1, replica r1 replays it, a read from r1 returns 1, then a read from r2 returns 0 although 1 was already shown. The token stays 0 throughout.",cols=["Init","OtherWrite","Replay(r1)","Read(r1)","Read(r2)"],labelw=100,cell=110)
toast=graph({
 "s0":(55,45,"shown"),
 "s1":(250,45,"hidden\nUndo toast"),
 "s2":(250,185,"shown\n(undone)","good"),
 "s3":(470,45,"hidden\nDELETE sent"),
 "s4":(650,45,"deleted\nok reply"),
 "s6":(650,185,"hidden\ndeleted","good"),
 "s5":(470,185,"kept\nfail reply"),
 "s7":(470,315,"shown\nerror toast"),
 "s8":(650,315,"shown\nkept","good"),
},[
 ("s0","s1","Delete"),("s1","s2","Undo"),("s1","s3","Timeout"),
 ("s3","s4","Serve ok"),("s4","s6","Receive"),
 ("s3","s5","Serve fails"),("s5","s7","Receive"),("s7","s8","Dismiss"),
],"The nine reachable states of the Deferred design with failures. Delete hides the message and shows Undo. Undo leads to a final shown state. Timeout sends DELETE; success leads to a final deleted state; failure leads to an error toast and, after Dismiss, a final state where the message is shown and kept.",width=715)
FIGS={"abort":(abort,"An abort reaches the network, not the event loop. A response already read has escaped it."),
"lease":(lease,"The lease is a fencing token issued by the cache, and the delete moves the fence. The refusal happens where the stale value would land."),
"lsn":(lsn,"The flicker in TLC’s trace. The session never wrote, so a token built from writes stays 0 and both replicas qualify."),
"toast":(toast,"TLC’s complete state graph for <code>\"Deferred\"</code>. Undo exists only before the request leaves, and every final state, in green, agrees with the server.")}
