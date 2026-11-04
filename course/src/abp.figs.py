import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
FIGS={
"protocol":(sequence(["A","B"],[
 ("note","A","AVar = <<Mary,1>>"),
 ("note","B","BVar = <<Fred,0>>"),
 ("B","A","0 (old ack: A's bit is 1, ignored)"),
 ("A","B","<<Mary,1>>",{"lost":True}),
 ("A","B","<<Mary,1>>  new bit, so BVar := <<Mary,1>>",{"tone":"good"}),
 ("B","A","1",{"lost":True}),
 ("A","B","<<Mary,1>>  same bit, duplicate, ignored",{"dash":True}),
 ("B","A","1  matches A's bit, so choose a new value",{"tone":"good"}),
 ("note","A","AVar = <<Anne,0>>"),
 ("B","A","1 (old ack: A's bit is 0, ignored)",{"dash":True}),
 ("A","B","<<Anne,0>>  new bit, so BVar := <<Anne,0>>",{"tone":"good"}),
],"Message sequence between A and B. A's first message and B's first ack are lost and resent. Duplicate messages and stale acks are ignored because of their bits. Green arrows are the ones that change state.",gap=420,step=40),
"The protocol on its two lossy channels. A and B both resend forever. Only the green arrows change anything; the bit tells each side which arrivals are news."),
"constraint":(graph({
 "z":(70,70,"Len = 0"),
 "o":(240,70,"Len = 1"),
 "t":(410,70,"Len = 2"),
 "x":(590,70,"Len = 3\nnot explored","bad"),
},[
 ("z","o","ASnd",{"bend":-14}),("o","z","BRcv / Lose",{"bend":-14,"ly":6}),
 ("o","t","ASnd",{"bend":-14}),("t","o","BRcv / Lose",{"bend":-14,"ly":6}),
 ("t","x","ASnd",{"dash":True,"tone":"bad"}),
],"States by the length of channel AtoB with a bound of 2. ASnd lengthens the channel, and BRcv or LoseMsg shorten it. A state of length 3 fails the constraint, so TLC does not compute any successors from it.",width=680,height=130),
"How TLC uses <code>Bound</code>, drawn by length of <code>AtoB</code> only. A state failing the constraint is simply not explored further. The spec is unchanged, and only this model's search is cut."),
"weak":(lanes([
 ("step",[None,"ASnd","BSnd","LoseMsg","BRcv"]),
 ("AtoB",["<<>>","<<m>>","<<m>>","<<m>>","<<>>"]),
 ("BtoA",["<<>>","<<>>",("<<1>>","accent"),"<<>>","<<>>"]),
 ("ARcv enabled",["no","no",("yes","accent"),"no","no"]),
 ("AVar, BVar",["same","same","same","same","same"]),
],"TLC's counterexample for the weak fairness spec. ASnd, BSnd, LoseMsg removing the ack, then BRcv of a duplicate returns to the first state, forever. ARcv is enabled only in state 3 and so never continuously.",cols=["State 1","State 2","State 3","State 4","back to 1"]),
"TLC's counterexample with weak fairness everywhere, where m = <code>&lt;&lt;d1, 1&gt;&gt;</code>. The loop repeats forever. <code>ARcv</code> is enabled once per lap and disabled by <code>LoseMsg</code> before it can run, so <code>WF_vars(ARcv)</code> is satisfied, and <code>AVar</code> and <code>BVar</code> never change."),
"bug":(lanes([
 ("step",[None,"BSnd","ARcv","BSnd","ARcv"]),
 ("BtoA",["<<>>","<<1>>","<<>>","<<1>>","<<>>"]),
 ("AVar",["d2,1","d2,1",("d1,0","accent"),"d1,0",("d1,1","bad")]),
 ("BVar",["d2,1","d2,1","d2,1","d2,1","d2,1"]),
 ("ABS sees",[None,("stutter","muted"),("A","accent"),("stutter","muted"),("rejected","bad")]),
],"TLC's counterexample when A ignores the acknowledgement's bit. The stale ack makes A overwrite d1,0 with d1,1 before B received it. ABS rejects that because action A needs AVar equal to BVar.",cols=["State 1","State 2","State 3","State 4","State 5"]),
"TLC's counterexample for a broken <code>ARcv</code> that moves on after any ack. Its second new value overwrites one B never got, which <code>ABS!Spec</code> rejects because A needs <code>AVar = BVar</code>."),
}
FIGS={k:(s.replace('id="dg-a"',f'id="dg-a-abp-{k}"').replace('url(#dg-a)',f'url(#dg-a-abp-{k})'),c) for k,(s,c) in FIGS.items()}
