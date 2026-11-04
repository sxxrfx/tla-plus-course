import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
FIGS={
"send":(lanes([
 ("step",[None,"A","B","A","B","A","B"]),
 ("AVar",["-,1",("Fred,0","accent"),"Fred,0",("Mary,1","accent"),"Mary,1",("Mary,0","accent"),"Mary,0"]),
 ("BVar",["-,1","-,1",("Fred,0","good"),"Fred,0",("Mary,1","good"),"Mary,1",("Mary,0","good")]),
 ("B received",[None,None,"Fred",None,"Mary",None,"Mary"]),
],"Seven states of the alternating bit high-level spec. A sets AVar to a new value with the bit flipped, then B copies it to BVar. Mary is sent twice in a row and the flipped bit makes the second sending visible.",cols=["s1","s2","s3","s4","s5","s6","s7"]),
"The high-level view: A puts a value in <code>AVar</code> (outlined), then B copies it to <code>BVar</code> (green). In the last two steps Mary is sent again. Only the flipped bit makes that a change anyone can see."),
"remove":(lanes([
 ("seq",["1","2",("3","bad"),"4"]),
 ("j < 3: seq[j]",["1","2",None,None]),
 ("else seq[j+1]",[None,None,"4",None]),
 ("Remove(3, seq)",[("1","good"),("2","good"),("4","good"),None]),
],"The sequence 1, 2, 3, 4 with its third element removed. Positions below 3 keep their value and position 3 takes the value from position 4, giving 1, 2, 4.",cols=["j=1","j=2","j=3","j=4"],labelw=130,cell=56),
"<code>Remove(3, &lt;&lt;1, 2, 3, 4&gt;&gt;)</code> position by position. Its domain shrinks to <code>1..3</code>. Positions before the removed one copy across, and later ones shift down."),
"machine":(graph({
 "a":(130,60,"AVar = <<d, 1>>\nBVar = <<d, 1>>","accent"),
 "b":(490,60,"AVar = <<d, 0>>\nBVar = <<d, 1>>"),
 "c":(490,200,"AVar = <<d, 0>>\nBVar = <<d, 0>>","accent"),
 "e":(130,200,"AVar = <<d, 1>>\nBVar = <<d, 0>>"),
},[
 ("a","b","A"),("b","c","B"),("c","e","A"),("e","a","B"),
],"The state graph of ABSpec with one data value. Four states form a cycle, alternating A and B steps. In the two states where the bits match, AVar equals BVar.",width=640,height=250,mono=True),
"All of ABSpec when <code>Data = {d}</code>; TLC finds exactly these 4 states. In the two highlighted states the bits agree and the values agree, which is what <code>Inv</code> says. Each A arrow becomes one arrow per data value when <code>Data</code> grows."),
}
FIGS={k:(s.replace('id="dg-a"',f'id="dg-a-abs-{k}"').replace('url(#dg-a)',f'url(#dg-a-abs-{k})'),c) for k,(s,c) in FIGS.items()}
