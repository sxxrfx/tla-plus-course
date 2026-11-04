import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
fn=graph({"r1":(50,30,"r1"),"r2":(50,95,"r2"),"r3":(50,160,"r3"),
 "w":(330,60,"working"),"p":(330,160,"prepared"),"c":(520,60,"committed","muted"),"a":(520,160,"aborted","muted")},
 [("r1","w"),("r2","w"),("r3","p"),("r2","p","after EXCEPT",{"dash":True,"tone":"accent","ly":-2})],
 "A function rmState from three resource managers to state values. r1 and r2 map to working, r3 to prepared. A dashed arrow shows r2 mapping to prepared after an EXCEPT.",width=600,height=190)
funcs=regions([(10,10,660,150,'[{"r1", "r2"} -> {"a", "b"}] is a set of 4 functions'),
 (28,44,145,100,"","accent"),(186,44,145,100,""),(344,44,145,100,""),(502,44,145,100,"")],
 "A large box, the set of all functions from r1 and r2 to a and b, contains four smaller boxes, one per function. The first is highlighted as the single function mapping both to a.",
 width=680,height=170,notes=[(100,78,"r1 |-> a"),(100,110,"r2 |-> a"),(258,78,"r1 |-> a"),(258,110,"r2 |-> b"),(416,78,"r1 |-> b"),(416,110,"r2 |-> a"),(574,78,"r1 |-> b"),(574,110,"r2 |-> b")])
wrong=lanes([("r1",["working",("?","bad"),"working"]),("r2",["working",("prepared","accent"),("prepared","accent")]),("r3",["working",("?","bad"),"working"])],
 "Three columns for r1, r2, r3: the current state, the new state as far as rmState prime of r2 equals prepared determines it, with question marks for r1 and r3, and the EXCEPT version with r1 and r3 still working.",
 cols=["now","r2 only","EXCEPT"],cell=110,labelw=50)
quant=lanes([("r1",["working",("FALSE","bad")]),("r2",["prepared",("TRUE","good")]),("r3",["working",("FALSE","bad")]),("\\E: any",[None,("TRUE","good")]),("\\A: all",[None,("FALSE","bad")])],
 "For each of r1, r2, r3, the state and whether it equals prepared: only r2 is true. The exists formula is true and the forall formula is false.",
 cols=["rmState[r]","= prepared"],cell=110,labelw=80)
order=graph({"b":(50,35,"book"),"m":(50,110,"mug"),"e":(220,35,"East"),"w":(220,110,"West"),
 "e2":(400,72,"East","accent"),"b2":(590,35,"book"),"m2":(590,110,"mug")},
 [("b","e","can ship",{"tone":"good"}),("m","w","can ship",{"tone":"good"}),("e2","b2","yes",{"tone":"good"}),("e2","m2","no",{"tone":"bad","dash":True})],
 "Left: book ships from East and mug from West, so every item has a warehouse. Right: East can ship book but not mug, so no single warehouse ships every item.",width=650,height=140)
FIGS={"fn":(fn,"One function. Each element of the domain has exactly one value at a time; the dashed arrow is r2's value after one step."),
"funcs":(funcs,"The arrow form is a set of functions. The |-&gt; form, highlighted, is one element of it."),
"wrong":(wrong,"Setting one entry leaves the other entries' new values unsaid. EXCEPT says all of them."),
"quant":(quant,"Over a finite set, \\E is a big \"or\" of the rows and \\A is a big \"and\"."),
"order":(order,"Each item has a warehouse (left), but no warehouse has every item (right). Swapping the quantifiers separates these claims.")}
