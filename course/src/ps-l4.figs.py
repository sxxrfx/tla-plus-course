import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions

# Problem 1: the modal's states, with the bad state the copied frame line reaches
modal=graph({"c":(100,60,"closed\npage, unlocked","accent"),"o":(360,60,"open\ndialog, locked"),
 "bad":(600,60,"closed\npage, LOCKED","bad"),"q":(360,196,"closed, page\nscrollLocked = ?","muted")},
 [("c","o","OpenDialog",{"bend":-26}),("o","c","CloseButton",{"bend":-26}),
  ("o","bad","PressEscape",{"tone":"bad","ly":-16}),("bad","o","OpenDialog",{"bend":-40,"dash":True,"ly":4}),
  ("o","q","PressEscape, no frame line",{"dash":True})],
 "State graph of the modal. Closed with the page unlocked goes to open with focus in the dialog and scroll locked, and back by CloseButton. PressEscape with the copied frame line goes to a red state: closed, focus on the page, scroll still locked. Without any frame line, PressEscape leads to a state whose scrollLocked value is unspecified.",
 width=700,height=236)

# Problem 2: the bad behavior when Backfill runs before dual writes
B=lambda t:(t,"bad");G=lambda t:(t,"good")
mig=lanes([("schema",["old","both","both","both","both","both"]),
 ("app",["1","1","1","1","2",B("3")]),
 ("backfilled",["FALSE","FALSE",G("TRUE"),"TRUE","TRUE","TRUE"]),
 ("missing",["TRUE","TRUE",G("FALSE"),B("TRUE"),B("TRUE"),B("TRUE")])],
 "The six-state trace TLC prints when Backfill may run as soon as the column exists: AddColumn, Backfill, SignUp, DeployV2, DeployV3. Missing becomes FALSE at the backfill, TRUE again at the sign-up, and app 3 then reads the new column with a row missing.",
 cols=["Init","AddColumn","Backfill","SignUp","DeployV2","DeployV3"],cell=92,labelw=96)

# Problem 3: TLC's shortest Hanoi solution
H=[(1,1,1),(3,1,1),(3,2,1),(2,2,1),(2,2,3),(1,2,3),(1,3,3),(3,3,3)]
A=["Init","MoveD1","MoveD2","MoveD1","MoveD3","MoveD1","MoveD2","MoveD1"]
def cell(i,v): return (str(v),"good") if i==7 else (str(v),"accent") if i==0 else str(v)
hanoi=lanes([(f"d{k+1}",[cell(i,h[k]) for i,h in enumerate(H)]) for k in range(3)],
 "Eight states of TLC's trace for three disks. Each column gives the peg of d1, d2 and d3. The smallest disk moves every other step; the largest disk moves once, in the middle, from peg 1 to peg 3.",
 cols=A,cell=72,labelw=50)

# Problem 4: reachable states of the 4 L and 6 L chambers
def dc(s,b):
    if not (s in (0,4) or b in (0,6)): return None
    if s%2 or b%2: return None
    return (f"{s},{b}","good" if (s,b)!=(0,0) else "accent")
grid=lanes([(f"small = {s}",[dc(s,b) for b in range(7)]) for s in (4,3,2,1,0)],
 "Grid of chamber states, small 0 to 4 by big 0 to 6. The ten reachable states are filled; all have even amounts. The row small = 3 and the column big = 3 are empty, as are the odd rows and columns.",
 cols=[f"big {b}" for b in range(7)],cell=62,labelw=96)

FIGS={"modal":(modal,"The copied frame line keeps the lock on after Escape: the red state. With no frame line at all, the next state isn't determined, which is what TLC complains about."),
"migration":(mig,"Backfilling before v2 is live. The sign-up in column 4 writes only <code>email</code>, so the backfill's work is out of date before anyone reads the new column."),
"hanoi":(hanoi,"TLC's breadth-first search returns a shortest solution: 7 moves. It is the move sequence the recursive algorithm produces."),
"dosing":(grid,"Every state TLC reaches for 4 L and 6 L chambers. Nothing lands in the 3 row or column, and every amount is a multiple of gcd(4, 6) = 2.")}
