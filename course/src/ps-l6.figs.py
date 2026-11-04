import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions

# Problem 1: the trace TLC prints when the car is optional
booking=sequence(["flight","booking","hotel","car"],[
 ("flight","booking","Prepared (flight)"),("hotel","booking","Prepared (hotel)"),
 ("note","booking","{flight, hotel} \\subseteq tmPrepared: TMCommit"),
 ("booking","flight","Commit",{"tone":"good"}),
 ("note","car","car: RMChooseToAbort","bad"),
 ("note","flight","flight committed, car aborted","bad")],
 "Message sequence: flight and hotel send Prepared to the booking service. With both in tmPrepared it commits and sends Commit, which the flight receives. The car, still working, aborts on its own. Flight committed and car aborted: the forbidden pair.",
 gap=180,step=42)

# Problem 2: the coordinator crashes after both databases prepared
prepared=sequence(["orders","app server","payments","report"],[
 ("orders","app server","Prepared (orders)"),("payments","app server","Prepared (payments)"),
 ("note","app server","TMCrash: down for good","bad"),
 ("note","payments","prepared: holds its row locks"),
 ("note","report","UPDATE waits for the lock","bad"),
 ("note","orders","no step is enabled: deadlock","bad")],
 "Message sequence: orders and payments each send Prepared, then the app server crashes. Payments stays prepared and keeps its locks. The report session's UPDATE waits. No action is enabled, and TLC reports deadlock.",
 gap=180,step=42)

# Problem 3: redelivery of one receipt message
receipts=sequence(["orders","queue","worker","email API"],[
 ("orders","queue","publish receipt o1"),("queue","worker","deliver o1"),
 ("worker","email API","send receipt o1"),("note","queue","no ack yet: o1 visible again"),
 ("queue","worker","deliver o1 again",{"dash":True}),
 ("worker","email API","send receipt o1",{"tone":"bad"}),
 ("note","worker","emailed = {} still, until Record","bad")],
 "Message sequence: the order service publishes the receipt for o1. The queue delivers it, and the worker sends the email. Before the worker records it, the queue delivers o1 again and the worker sends a second email.",
 gap=180,step=42)

# Problem 4: two traces that put a unit back that was never taken
B=lambda t:(t,"bad")
stock=lanes([("bug: east",["working","working","aborted",None]),
 ("bug: stock",["1","1",B("2"),None]),
 ("guarded: east",["working","working","aborted","aborted"]),
 ("guarded: stock",["1","1","1",B("2")])],
 "Two traces, state by state. Buggy release: the TM aborts, east receives Abort while working, and its stock goes from 1 to 2. Release guarded by rmState not working: the TM aborts, east aborts on its own, then receives Abort, and its stock goes from 1 to 2.",
 cols=["1","2","3","4"],cell=96,labelw=124)

FIGS={"booking":(booking,"TLC's 8-state trace for the optional car. The flight is ticketed and the car reservation was abandoned, inside one transaction that promised all or nothing."),
"prepared":(prepared,"The blocking case of two-phase commit, as TLC finds it: 4 states. Nothing in the model is wrong. The protocol simply has no step that a prepared participant can take alone."),
"receipts":(receipts,"At-least-once delivery. The second delivery is the same message read again, which the grow-only <code>msgs</code> allows without any extra action."),
"stock":(stock,"Top: TMAbort, then RMRcvAbortMsg(\"east\") while east is working. Bottom, with the release guarded by <code>rmState[r] # \"working\"</code>: TMAbort, RMChooseToAbort(\"east\"), RMRcvAbortMsg(\"east\"). Either way a unit appears from nowhere.")}
