import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
_b={"bend":16}
states=graph({"e":(50,170,"⟨⟩"),"a":(240,70,"⟨A⟩"),"b":(240,270,"⟨B⟩"),"ba":(240,170,"⟨B, A⟩"),"ab":(440,170,"⟨A, B⟩"),"aa":(440,40,"⟨A, A⟩"),"bb":(440,300,"⟨B, B⟩")},
 [("e","a","enq A",{"bend":-16}),("a","e","deq",{"bend":-16}),("e","b","enq B",{"bend":16}),("b","e","deq",{"bend":16}),
  ("a","aa","enq A",{"bend":-16}),("aa","a","deq",{"bend":-16}),("b","bb","enq B",{"bend":16}),("bb","b","deq",{"bend":16}),
  ("a","ab","enq B"),("ab","b","deq"),("b","ba","enq A"),("ba","a","deq")],
 "The 7 reachable queue values for two values and capacity 2, with their enqueue and dequeue steps. Dequeue always removes the left element.")
order=lanes([("sent",["⟨⟩","⟨A⟩","⟨A,B⟩","⟨A,B⟩"]),("q: Head out",["⟨⟩","⟨A⟩","⟨A,B⟩",("⟨B⟩","good")]),("received",["⟨⟩","⟨⟩","⟨⟩",("⟨A⟩","good")]),
 ("q: last out",["⟨⟩","⟨A⟩","⟨A,B⟩",("⟨A⟩","bad")]),("received",["⟨⟩","⟨⟩","⟨⟩",("⟨B⟩","bad")])],
 "The correct dequeue and TLC's trace for the mutated one, side by side. After enqueueing A then B, the correct queue delivers A and the mutated one delivers B.",cols=["Init","Enq A","Enq B","Dequeue"],labelw=120,cell=74)
jobs=graph({"n":(60,60,"not accepted"),"w":(240,60,"waiting"),"a":(420,60,"active"),"d":(590,60,"done","good"),"x":(240,160,"in no place","bad")},
 [("n","w","Accept"),("w","a","Claim"),("a","d","Finish"),("w","x","removed, then crash",{"tone":"bad","dash":True})],
 "A job's lifecycle. Accept, Claim and Finish each move it between exactly one place. The dashed crash path removes it from waiting without recording it anywhere.")
FIGS={"states":(states,"All 7 reachable queues. Enqueue appends on the right and dequeue removes from the left, so ⟨A, B⟩ goes to ⟨B⟩ and ⟨B, A⟩ goes to ⟨A⟩. Those two edges are what FIFO means."),
"order":(order,"The correct dequeue on top, and on the bottom TLC’s 3-step trace of the one that removes the last item. Both keep the same queue length."),
"jobs":(jobs,"One job’s lifecycle. Every solid edge moves it from one place to exactly one other. The dashed edge is the crash that breaks ownership.")}
# Markers live per SVG: hidden lessons would otherwise hold the only #dg-a that url() resolves to, and arrowheads vanish.
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-fifo-{k}\"").replace("#dg-a)",f"#dg-a-fifo-{k})"),v[1]) for k,v in FIGS.items()}
