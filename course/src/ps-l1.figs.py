import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
elev=lanes([("A",["1 closed","1 opening","1 open","1 closing","1 closed","2 closed"]),
            ("B",["1 closed","2 closed","2 opening","3 opening"]),
            ("C",["1 closed","1 opening","1 open","1 closing","1 opening","1 open"]),
            ("D",["1 closed","3 closed","3 opening"]),
            ("E",["2 closed","2 opening","2 open"])],
           "Five candidate sequences for the elevator. Each cell is one state: floor, then door. A: 1 closed, 1 opening, 1 open, 1 closing, 1 closed, 2 closed. B: 1 closed, 2 closed, 2 opening, 3 opening. C: 1 closed, 1 opening, 1 open, 1 closing, 1 opening, 1 open. D: 1 closed, 3 closed, 3 opening. E: 2 closed, 2 opening, 2 open.",
           cols=["state 1","state 2","state 3","state 4","state 5","state 6"],labelw=40)
tn={"a":(90,125,"active\nvisible: no","accent"),"c":(330,42,"committed\nvisible: yes","good"),"f":(330,208,"failed\nvisible: no"),"x":(570,125,"aborted\nvisible: no","bad")}
txn=graph(tn,[("a","c","COMMIT",{"lx":-18,"ly":-12}),("a","f","error",{"lx":-14,"ly":12}),("a","x","ROLLBACK"),("f","x","ROLLBACK\nor COMMIT",{"lx":30,"ly":14})],
          "Transaction lifecycle. Active, the initial state, goes to committed on COMMIT, to aborted on ROLLBACK, and to failed on an error. Failed goes to aborted on ROLLBACK or COMMIT. Committed and aborted have no outgoing arrows.",width=660,height=250)
bn={"i":(80,205,"idle"),"l":(300,205,"loading","accent"),"s":(540,85,"success","good"),"e":(540,315,"error","bad")}
btn=graph(bn,[("i","l","click"),("l","s","resolve",{"lx":-26,"ly":-6}),("l","e","reject",{"bend":22,"lx":-34,"ly":4}),
              ("s","i","after 2 s",{"bend":70,"ly":-4}),("e","l","click (retry)",{"bend":22,"lx":40,"ly":4}),
              ("l","l","2nd click?",{"dash":True,"tone":"bad"})],
          "Button phases. Idle goes to loading on click. Loading goes to success on resolve or to error on reject. Success returns to idle after 2 seconds. Error goes back to loading on click. A dashed self-loop on loading, labelled 2nd click, is in question.",width=640,height=350)
typ=lanes([("live",["40","40","40","41","41","41","42"]),
           ("run A",["start","tested","read 40","wrote 41","wrote 41","wrote 41","wrote 41"]),
           ("run B",["start","start","start","start","tested","read 41","wrote 42"])],
          "The order the end-to-end test always produces. Run A tests, reads 40 and writes 41; then run B tests, reads 41 and writes 42. Live goes 40, 41, 42.",
          cols=["state 1","2","3","4","5","6","7"],labelw=60)
bad=lanes([("live",["40","40","40","40","40","42",("41","bad")]),
           ("run A",["start","tested","tested","read 40","read 40","read 40",("wrote 41","bad")]),
           ("run B",["start","start","tested","tested","read 40","wrote 42","wrote 42"])],
          "A bad interleaving. A tests, B tests, A reads 40, B reads 40, B writes 42, then A writes 41 because 41 is newer than the 40 it read. Live ends at 41.",
          cols=["state 1","2","3","4","5","6","7"],labelw=60)
FIGS={"elevator":(elev,"Five sequences from the controller's logs. Each row is a sequence of states; each cell shows the floor and the door. Which rows are behaviors?"),
"txn":(txn,"One transaction's lifecycle, with the value of both variables in each state. Committed and aborted have no outgoing arrows: the machine halts there."),
"button":(btn,"The Button's phases as the team describes them. The dashed loop is the question behind the double charge: what does a second click do while a request is loading?"),
"deploy-typical":(typ,"The interleaving the end-to-end test produces every time: run A starts a minute earlier and finishes before run B reads. Each column is a state."),
"deploy-bad":(bad,"One of the six bad interleavings. B's whole read and write happen between A's read and A's write, so A's check compares 41 with a stale 40 and replaces the newer version.")}
