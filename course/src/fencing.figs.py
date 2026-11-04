import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
A_="Authority";S_="Storage"
bad=sequence([A_,"A","B",S_],[
 (A_,"A","token 1"),("note","A","A pauses"),
 (A_,"B","token 2"),("B",S_,"write(2)"),("note",S_,"fence = 2"),
 ("A",S_,"write(1)",{"tone":"bad"}),("note",S_,"fence = 1: regressed","bad"),
],"Without fencing: A gets token 1 and pauses, B gets token 2 and writes, then A resumes and its write with token 1 is accepted, moving the fence back to 1.",gap=170,step=38)
good=sequence([A_,"A","B",S_],[
 (A_,"A","token 1"),("note","A","A pauses"),
 (A_,"B","token 2"),("B",S_,"write(2)"),("note",S_,"fence = 2"),
 ("A",S_,"write(1)",{"tone":"good"}),("note",S_,"1 < 2: rejected","good"),
],"With fencing: the same order of events, but storage compares token 1 with fence 2 and rejects A's write.",gap=170,step=38)
gap=sequence([A_,"A","B",S_],[
 (A_,"A","token 1"),(A_,"B","token 2"),("note","B","no write yet"),
 ("A",S_,"write(1)",{"tone":"bad"}),("note",S_,"1 >= 0: accepted","bad"),
],"Authority grants token 2 to B, but B has not written. Storage has fence 0, so A's write with token 1 is accepted.",gap=170,step=38)
sess=sequence(["Phone","Server"],[
 ("note","Phone","update(12) sent, delayed"),
 ("Phone","Server","log out"),
 ("note","Server","epoch := 13"),
 ("Phone","Server","update(epoch 12) arrives"),
 ("note","Server","12 # 13: reject","good"),
],"A delayed upload with epoch 12 reaches the server after logout moved the epoch to 13, and the server rejects it.",gap=360,step=38)
split=lanes([("sessionEpoch",["12","12",("13","accent"),"13"]),("pc",["sent","checked","checked","done"]),("acceptedEpoch",["0","0","0",("12","bad")]),("epochAtAcceptance",["0","0","0",("13","bad")])],
 "TLC trace with Split TRUE: Check passes at epoch 12, Revoke moves the epoch to 13, and Write installs with acceptedEpoch 12 and epochAtAcceptance 13.",cols=["Init","Check","Revoke","Write"],labelw=140,cell=84)
FIGS={"bad":(bad,"No fence: the resource takes whichever write arrives. The red write is legal to send and wrong to accept."),
"good":(good,"Same events, with the fence. The check happens at the resource, so it works however late A’s write arrives."),
"gap":(gap,"TLC’s trace for <code>RevokedAtGrant</code> with fencing on. Storage has not heard of token 2, so it has no reason to refuse token 1."),
"sess":(sess,"Logout changes the server’s authority. It cannot recall the request already on the network."),
"split":(split,"TLC’s counterexample when the check and the write are separate steps. The last column shows a write accepted under authority that had already ended.")}
