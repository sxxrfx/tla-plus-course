import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
arc=graph({
 "a":(110,36,"State machines\nand logic"),"b":(350,36,"TLC, actions,\nset theory"),"c":(590,36,"Commit protocols\nand quorums"),
 "d":(590,126,"Temporal logic\nand fairness"),"e":(350,126,"Implementation\nand refinement"),"f":(110,126,"Concurrency\nand PlusCal"),
 "g":(110,216,"Invariants, scale,\nproofs"),"h":(350,216,"Failure patterns","accent"),"i":(590,216,"Applied models\nand capstone","good"),
},[("a","b"),("b","c"),("c","d"),("d","e"),("e","f"),("f","g"),("g","h"),("h","i")],
"The course as a path: state machines and logic, TLC and set theory, commit protocols and quorums, temporal logic and fairness, implementation and refinement, concurrency and PlusCal, invariants and proofs, failure patterns, applied models and the capstone.",width=700,height=262)
photo=graph({
 "p":(70,60,"Phone\nupload ID"),"o":(280,60,"Object store\nbytes"),"m":(540,60,"Metadata row\n\"complete\"","accent"),
 "t":(540,190,"Thumbnail\nworker"),"c":(280,190,"CDN\ncached version"),
},[
 ("p","o","PUT, may retry",{"ly":-14}),("o","m","no shared\ntransaction",{"tone":"bad","dash":True}),
 ("m","t","event",{"bend":70,"lx":-10,"ly":-10}),("t","t","runs twice",{"tone":"bad"}),("t","c","publish"),("c","p","stale after\nreplacement",{"tone":"bad","dash":True}),
],"The upload path: phone to object store with retries, object store to metadata row with no shared transaction, metadata to thumbnail worker, which may run twice, worker to CDN, and CDN back to the phone with a possibly stale response.",width=660,height=250)
FIGS={"arc":(arc,"Each stage uses the one before it. The accent box and the green box are where the earlier tools meet failure."),
"photo":(photo,"One familiar app. Each red edge is a boundary from an earlier lesson: retries, separate stores, duplicate work, and a stale fill.")}
