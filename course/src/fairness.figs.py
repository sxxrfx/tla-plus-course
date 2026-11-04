import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
Y=("true","good");N="false"
FIGS={
"kinds":(lanes([
 ("Safety: []x<=3",["1","2","3",("4","bad"),("?","muted"),("?","muted"),("?","muted")]),
 ("Liveness: <>(x=5)",["1","2","3","4",("...","accent"),("...","accent"),("...","accent")]),
],"Two behaviors. On the safety row x becomes 4, a violation at one point, after which nothing matters. On the liveness row no state violates the formula because a later state could always make x equal 5.",cols=["s1","s2","s3","s4","s5","s6","s7"],labelw=140),
"A safety formula is violated <em>at a point</em> (red), and nothing later can repair it. A liveness formula has no such point: after any prefix, a later state could still make x equal 5."),
"wf":(lanes([
 ("Run 1: enabled",[N,"true",N,Y,Y,Y,Y,Y,("...","good")]),
 ("WF requires",[None,None,None,("step","accent"),("step","accent"),("step","accent"),("step","accent"),("step","accent"),("...","accent")]),
 ("Run 2: enabled",["true",N,"true",N,"true",N,"true",N,("...","muted")]),
 ("WF requires",[("none","muted")]*9),
 ("SF requires",[("step","accent")]*8+[("...","accent")]),
],"Two enabling patterns over time. In run 1 A flickers then stays enabled forever, so weak fairness requires an A step in that stretch. In run 2 A keeps flickering, so weak fairness requires nothing, but strong fairness still requires an A step at some point.",cols=["s42","s43","s44","s45","s46","s47","s48","s49","..."],labelw=120),
"The cells marked step show where a required A step must fall: one step, somewhere among them. Run 1 stays enabled forever, so weak fairness demands a step. Run 2 never stays enabled, so weak fairness demands nothing, and only strong fairness does."),
"stutter":(lanes([
 ("step",[None,"A","stutter","stutter","..."]),
 ("AVar",["d2,1","d1,0",("d1,0","muted"),("d1,0","muted"),("...","muted")]),
 ("BVar",["d2,1","d2,1",("d2,1","bad"),("d2,1","bad"),("...","bad")]),
 ("B enabled",[N,Y,Y,Y,("...","good")]),
],"TLC's counterexample for Spec against the delivery property. A sets AVar to d1,0 and then the behavior stutters forever with B enabled and BVar still d2,1.",cols=["State 1","State 2","State 3","",""]),
"TLC's counterexample when <code>Spec</code> has no fairness. After State 3 TLC reports only Stuttering, meaning forever. B stays enabled throughout, and this is exactly the behavior <code>WF_vars(Next)</code> forbids."),
"upload":(lanes([
 ("connection",["online","offline","online","offline","online","offline","..."]),
 ("Send(U) enabled",[("yes","good"),"no",("yes","good"),"no",("yes","good"),"no",("...","muted")]),
 ("Send(U) runs",[("no","bad"),("no","bad"),("no","bad"),("no","bad"),("no","bad"),("no","bad"),("...","bad")]),
],"A phone alternates online and offline forever. Send U is enabled whenever online but is never chosen, so it is enabled infinitely often and never continuously.",labelw=130),
"Repeated opportunities satisfy <em>enabled infinitely often</em>, not <em>continuously enabled from some point on</em>. Weak fairness of <code>Send(U)</code> accepts this behavior, and strong fairness rejects it."),
}
FIGS={k:(s.replace('id="dg-a"',f'id="dg-a-fr-{k}"').replace('url(#dg-a)',f'url(#dg-a-fr-{k})'),c) for k,(s,c) in FIGS.items()}
