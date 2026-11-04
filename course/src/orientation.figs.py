import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
xs=[66,204,342,480,618]
n={}
L=[("Lecture 1\nIntroduction"),("Lecture 2\nState machines"),("Lecture 3\nTools"),("Lecture 4\nDie Hard"),("Lecture 5\nTransaction\ncommit")]
for i,t in enumerate(L): n[f"l{i+1}"]=(xs[i],44,t,"accent")
L2=[("Lecture 6\nTwo-phase commit"),("Lecture 7\nPaxos commit"),("Lecture 8\nImplementation"),("Lecture 9\nAlternating bit"),("Lecture 10\nRefinement")]
for i,t in enumerate(L2): n[f"l{i+6}"]=(xs[4-i],134,t,"accent")
B=["Beyond I\nConcurrency","Beyond II\nReasoning\nat scale","Beyond III\nFailure-prone","Beyond IV\nApplied models","Practice\nReview"]
for i,t in enumerate(B): n[f"b{i+1}"]=(xs[i],224,t,"good" if i==4 else "")
e=[(f"l{i}",f"l{i+1}") for i in range(1,10)]+[("l10","b1")]+[(f"b{i}",f"b{i+1}") for i in range(1,5)]
route=graph(n,e,"The course route as a snake: lectures 1 to 5 left to right, lectures 6 to 10 right to left, then four Beyond the lectures parts and a Practice part.",width=700,height=264)
ln={"w":(70,50,"Watch\na segment"),"p":(230,50,"Pause and\npredict","accent"),"r":(390,50,"Read the\nlesson"),"t":(570,50,"Run it\n(lab or TLC)"),"b":(570,170,"Break it\non purpose"),"x":(390,170,"Explain it\nfrom memory"),"n":(230,170,"Next segment")}
loop=graph(ln,[("w","p"),("p","r"),("r","t"),("t","b"),("b","x"),("x","n"),("n","w"),("t","p","surprised?",{"bend":-72,"dash":True,"tone":"accent"})],"Study loop: watch a segment, pause and predict, read the lesson, run it, break it, explain from memory, then the next segment. A dashed arrow returns from run to predict when the result surprises you.",width=650,height=214)
un={"i":(70,110,"idle\ndocs: 0"),"u":(240,110,"uploading\ndocs: 0","accent"),"s":(440,50,"saved\ndocs: 1","good"),"c":(440,170,"timed out\ndocs: 1"),"d":(620,170,"saved\ndocs: 2","bad")}
upload=graph(un,[("i","u","tap Upload",{"ly":-14}),("u","s","server commits",{"ly":-12,"lx":-14,"tone":"good"}),("u","c","commits, reply lost",{"ly":14,"lx":-20}),("c","d","retry",{"ly":-14,"tone":"bad"})],"Upload as a graph. The good path goes idle, uploading, saved with one document. The bad path has the reply lost, a timeout, a retry and two documents.",width=690,height=218)
FIGS={"route":(route,"The whole route. Each arrow is one step harder: lectures 1 to 4 build one small spec, 5 to 7 model real protocols, 8 to 10 ask what implementing a spec means, and the last row applies the method without a video."),
"loop":(loop,"One pass per video segment. The dashed arrow matters most: a result you did not predict is the thing to study."),
"upload":(upload,"Two paths from the same tap. Every screen on the lower path looks reasonable, yet it ends with two documents.")}
