import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
FIGS={
"map":(lanes([
 ("AVar",["<Tom,1>",("<Tom,1>","good")]),
 ("BVar",["<Ann,0>",("<Ann,0>","good")]),
 ("AtoB2 -> AtoB",[("<Bad, <Tom,1>>","bad"),("<<Tom,1>>","good")]),
 ("BtoA2 -> BtoA",[("<0, Bad, 0, Bad>","bad"),("<0, 0>","good")]),
],"One AB2 state and the AB state it stands for. AVar and BVar are copied. The channels drop their Bad entries.",cols=["state of AB2","state of AB"],labelw=120),
"The lecture's example, one state at a time. <code>AVar</code> and <code>BVar</code> carry across. Each channel loses its <code>Bad</code> entries."),
"steps":(lanes([
 ("AB2 step",[None,"BSnd","CorruptMsg","ARcv"]),
 ("BtoA2",["<<>>","<<1>>",("<<Bad>>","bad"),"<<>>"]),
 ("RemoveBad(BtoA2)",["<<>>","<<1>>","<<>>","<<>>"]),
 ("AB sees",[None,("BSnd","good"),("LoseMsg","good"),("stutter","muted")]),
 ("wrong: BtoA2 itself",["<<>>","<<1>>",("<<Bad>>","bad"),None]),
 ("AB sees",[None,("BSnd","good"),("rejected","bad"),None]),
],"An AB2 behavior read through two mappings. Through RemoveBad the steps are BSnd, LoseMsg and a stutter. Through the identity mapping the corrupt step yields a channel containing Bad, which no AB step allows.",cols=["State 1","State 2","State 3","State 4"],labelw=150),
"One AB2 behavior through two mappings. Under <code>RemoveBad</code>, corrupting a message <em>is</em> losing it, and receiving the corrupted slot is stuttering. Under the wrong mapping, TLC's counterexample stops at State 3, since no AB step leads there."),
"chain":(graph({
 "a":(320,28,"SpecH => AB!Spec","accent"),
 "b":(320,110,"SpecH => (AB!Spec WITH AtoB <- ..., BtoA <- ...)"),
 "c":(320,192,"AB2!Spec => (AB!Spec WITH AtoB <- ..., BtoA <- ...)"),
 "d":(320,274,"Spec => AB!Spec    in module AB2, with INSTANCE AB WITH ...","good"),
},[
 ("a","b","Temporal Substitution Law"),
 ("b","c","always conjunct no longer needed"),
 ("c","d","move into AB2, write as INSTANCE"),
],"Four equivalent theorems. The Temporal Substitution Law replaces AB!Spec by its substituted form. Then SpecH's always conjunct is irrelevant and is dropped. Finally, moving to module AB2 gives a theorem TLC can check.",width=640,height=302),
"Four equivalent theorems. The first one defines what we mean, but TLC can't check it. The last one TLC can check. Each arrow is one small justified step."),
"editor":(lanes([
 ("step",[None,"Type t","Send r","Commit r","Ack r"]),
 ("draftText",["ca","cat","cat","cat","cat"]),
 ("durable ops",["{}","{}","{}","{r}","{r}"]),
 ("savedText",["ca",("ca","muted"),("ca","muted"),("cat","accent"),("cat","muted")]),
 ("abstract step",[None,("stutter","muted"),("stutter","muted"),("Edit","accent"),("stutter","muted")]),
],"A document editor's concrete behavior. Typing, sending and acknowledging leave the mapped saved text unchanged and appear as stutters. Only the durable commit is an abstract Edit step.",cols=["s1","s2","s3","s4","s5"],labelw=110),
"Choosing the mapping chooses the contract. With <code>savedText</code> mapped from the durable log, only the commit is an abstract edit. Everything else is stuttering, as with <code>ARcv</code> of a <code>Bad</code> message above."),
}
FIGS={k:(s.replace('id="dg-a"',f'id="dg-a-ref-{k}"').replace('url(#dg-a)',f'url(#dg-a-ref-{k})'),c) for k,(s,c) in FIGS.items()}
