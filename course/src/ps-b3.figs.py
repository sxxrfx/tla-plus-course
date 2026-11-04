import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
wallet=sequence(["App","Handler","Postgres"],[
 ("App","Handler","POST /debit, key k"),
 ("Handler","Postgres","SELECT k: none"),
 ("Handler","Postgres","INSERT ledger (commits)"),
 ("note","Handler","killed by deploy","bad"),
 ("App","Handler","retry, key k",{"dash":True}),
 ("Handler","Postgres","SELECT k: none"),
 ("Handler","Postgres","INSERT ledger (commits)",{"tone":"bad"}),
 ("note","Postgres","two debit rows","bad"),
],"NoTx with one handler: the first attempt commits the debit, the process is killed before the key is saved, and the retry finds no key and debits again.",gap=230,step=38)
pause=sequence(["Lock service","c1","c2","Storage"],[
 ("Lock service","c1","lease, token 1 (t=0)"),
 ("note","c1","t=1: check: valid"),
 ("note","c1","GC pause; t=2: expired","bad"),
 ("c1","Storage","write(1), delayed",{"dash":True}),
 ("Lock service","c2","lease, token 2 (t=2)"),
 ("c2","Storage","write(2)"),
 ("note","Storage","log = <<2>>"),
 ("c1","Storage","write(1) arrives",{"tone":"bad"}),
 ("note","Storage","log = <<2, 1>>","bad"),
],"TLC's trace with no fencing: c1 checks its lease at time 1, pauses until the lease expires at time 2, and sends token 1. c2 gets token 2 and writes. Storage applies 2 and then the stale 1.",gap=180,step=38)
grow=regions([
 (10,10,690,200,"Configuration 3: A, B, C, D, E"),
 (25,40,430,155,"Configuration 1: A, B, C"),
 (40,75,250,100,"decided X","good"),
 (300,75,385,100,"decided Y","bad"),
],"Five nodes in a row. The region for configuration 1 holds A, B and C; configuration 3 holds all five. The quorum that decided X is A and B; the quorum that decided Y is C, D and E. They share no node.",width=710,height=220,
 notes=[(95,140,"A","good"),(225,140,"B","good"),(355,140,"C","bad"),(480,140,"D","bad"),(610,140,"E","bad")])
outbox=sequence(["Checkout","Postgres","Relay","Broker","Shipping"],[
 ("Checkout","Postgres","order + outbox row"),
 ("note","Postgres","one transaction","good"),
 ("Relay","Broker","publish o1"),
 ("note","Relay","crash before delete","bad"),
 ("Relay","Broker","publish o1 again",{"dash":True}),
 ("Broker","Shipping","deliver o1"),
 ("note","Shipping","label + processed: 1 tx","good"),
 ("Broker","Shipping","deliver o1 again",{"dash":True}),
 ("note","Shipping","o1 processed: skip","good"),
],"Outbox flow: the order and its outbox row commit together; the relay publishes, crashes before deleting the row and publishes again; the broker delivers o1 twice; the shipping service prints one label because it records o1 as processed in the same transaction.",gap=145,step=38)
FIGS={"wallet":(wallet,"TLC’s trace for <code>NoTx</code>, as messages. The key exists to remember the debit, but a separate commit writes it, so the crash lands in the gap."),
"pause":(pause,"The pause sits between the check and the send, and the network adds more delay after it. Both are invisible to c1, and only storage sees the order in which writes land."),
"grow":(grow,"The two quorums from TLC’s <code>\"3to4to5\"</code> trace. Configuration 2 (A, B, C, D) sat between them and overlapped both, but nothing forced it to hold X."),
"outbox":(outbox,"Duplicates arrive from two places, a relay retry and a broker redelivery. Only the consumer’s check stops both.")}
