import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
def st(s,b): return f"small {s}\nbig {b}"
fn={"a":(60,110,st(0,3),"accent"),"g":(420,34,st(3,3),"good"),"b":(420,110,"small 3\nbig √7","bad"),"c":(420,190,"small 3\nbig \"abc\"","bad")}
ff=graph(fn,[("a","g","allowed by both",{"tone":"good","ly":-20,"lx":-20}),("a","b","only by small' = 3",{"tone":"bad","dash":True,"ly":-12}),("a","c","only by small' = 3",{"tone":"bad","dash":True,"ly":14,"lx":-10})],"From small 0 big 3, the formula small prime equals 3 alone allows next states with big 3, big root 7, or big abc. Adding big prime equals big allows only the first.",width=500,height=230)
pn={"a":(70,44,st(3,0),"accent"),"b":(370,44,st(0,3),"good"),"c":(70,140,st(3,3),"accent"),"d":(370,140,st(1,5),"good")}
pour=graph(pn,[("a","b","case 1: total 3 fits in big",{"ly":-14}),("c","d","case 2: total 6, big fills",{"ly":-14})],"Two pour cases from the lecture. Case 1: small 3, big 0 becomes small 0, big 3. Case 2: small 3, big 3 becomes small 1, big 5.",width=440,height=186)
s=("same","muted")
mat=lanes([("FillSmall",["3",s]),("FillBig",[s,"5"]),("EmptySmall",["0",s]),("EmptyBig",[s,"0"]),("SmallToBig",[("pour","accent"),("pour","accent")]),("BigToSmall",[("pour","accent"),("pour","accent")])],"Frame matrix for the six jug actions. Rows are actions, columns are small prime and big prime; every cell says the new value, same, or pour.",cols=["small'","big'"],cell=80,labelw=120,rowh=32)
cn={"a":(130,60,"draft = \"hello\"\npending = 0\nlastSent = \"\"\nselected = \"room7\"","accent"),"b":(480,60,"draft = \"\"\npending = 1\nlastSent = \"hello\"\nselected = \"room7\"","good")}
chat=graph(cn,[("a","b","Send",{"ly":-14})],"Before and after one Send step: draft hello becomes empty, pending goes 0 to 1, lastSent becomes hello, and selected stays room7.",width=620,height=120,mono=True)
FIGS={"frame":(ff,"Under <code>small' = 3</code> alone, all three arrows are allowed, because the formula says nothing about <code>big'</code>. Adding <code>big' = big</code> removes the two red ones."),
"pour":(pour,"The two cases of SmallToBig. Which one applies depends only on the total water, <code>big + small</code>."),
"matrix":(mat,"Check every action this way. No blank cells: each primed variable is either given a value or explicitly kept the same."),
"chat":(chat,"One step, constrained whole. lastSent gets the old draft even though draft is cleared in the same step.")}
