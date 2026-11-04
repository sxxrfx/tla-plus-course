import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
race=sequence(["Reader","Database","Writer","Cache"],[
 ("Reader","Cache","miss"),
 ("Reader","Database","read price"),
 ("Database","Reader","v0, still in flight",{"dash":True}),
 ("Writer","Database","write v1"),
 ("Writer","Cache","invalidate"),
 ("Reader","Cache","publish v0",{"tone":"bad"}),
 ("note","Cache","valid, but v0 < v1","bad"),
],"The reader misses and reads v0 while its response is in flight. The writer writes v1 and invalidates the cache. The reader then publishes v0, so the cache is valid and stale.",gap=170,step=38)
branch=graph({
 "c":(70,90,"captured v0"),"s":(270,90,"source now v1","accent"),
 "n":(530,36,"no fence: publish v0\nvalid and stale","bad"),
 "f":(530,144,"fence: discard v0\ncache stays invalid","good"),
 "r":(530,262,"later fill captures v1\nvalid and fresh","good"),
},[("c","s","Write +\ninvalidate"),("s","n","Fence = FALSE",{"tone":"bad"}),("s","f","Fence = TRUE",{"tone":"good"}),("f","r","BeginFill, FinishFill")],
"After a capture of v0 and a write of v1, the no-fence path publishes v0 and is stale. The fence path discards v0, leaves the cache invalid, and a later fill captures v1 and is fresh.",width=650,height=300)
bad=lanes([("sourceVersion",["0","0",("1","accent"),"1"]),("fillVersion",["0","0","0","0"]),("loading",["FALSE","TRUE","TRUE","FALSE"]),("cacheVersion",["0","0","0",("0","bad")]),("valid",["FALSE","FALSE","FALSE",("TRUE","bad")])],
"TLC trace with Fence FALSE: BeginFill captures version 0, WriteAndInvalidate moves the source to 1, FinishFill sets valid TRUE with cacheVersion 0.",cols=["Init","BeginFill","Write+Inv","FinishFill"],labelw=120,cell=86)
split=lanes([("sourceVersion",["0","0","0",("1","accent"),"1"]),("fillVersion",["0","0","0","0","0"]),("fill",["none","loading","checked","checked","none"]),("cacheVersion",["0","0","0","0",("0","bad")]),("valid",["FALSE","FALSE","FALSE","FALSE",("TRUE","bad")])],
"TLC trace with the check split from publication: BeginFill captures 0, CheckFence passes, a write moves the source to 1, Install publishes version 0 as valid.",cols=["Init","BeginFill","CheckFence","Write","Install"],labelw=120,cell=88)
FIGS={"race":(race,"The invalidation was delivered correctly. The fill path restored the old value afterwards."),
"bad":(bad,"TLC’s counterexample, one column per state. The fill carries version 0 across the write."),
"branch":(branch,"A rejected fill is allowed. Safety does not need every fill to succeed; a later one can restore availability."),
"split":(split,"The fence passed, then stopped being true. A check whose result outlives the state it read is the same stale-check shape as in the earlier lessons.")}
