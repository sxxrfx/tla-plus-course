import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
shards=lanes([("shard s1",["0","1","1","2",("0","bad")]),("shard s2",["0","0","1","1","1"]),("shard s3",["0","0","0","0","0"]),
 ("count = sum",["0","1","2","3",("1","bad")]),("abstract step",["","Inc","Inc","Inc",("none","bad")])],
 "A behavior of the sharded counter with a Restart step. The mapped count goes 0, 1, 2, 3, then drops to 1 when shard s1 restarts, which no Inc or stuttering step allows.",
 cols=["Init","Inc(s1)","Inc(s2)","Inc(s1)","Restart(s1)"],labelw=120,cell=96)
lsm=lanes([("memtable",["k1↦v1 k2↦v1","—","k1↦v2 k2↦v2","—","—"]),("file 1 (old)",["—","k1↦v1 k2↦v1","k1↦v1 k2↦v1","k1↦v1 k2↦v1",("k1↦v1 k2↦v1","bad")]),
 ("file 2 (new)",["—","—","—","k1↦v2 k2↦v2","—"]),("mapped store",["k1↦v1 k2↦v1","k1↦v1 k2↦v1","k1↦v2 k2↦v2","k1↦v2 k2↦v2",("k1↦v1 k2↦v1","bad")])],
 "Selected states of TLC's trace for the buggy compaction. The mapped store is unchanged by each flush, and the buggy compaction changes both keys back to v1 in one step.",
 cols=["2 puts","Flush","2 puts","Flush","Compact (bug)"],labelw=110,cell=118)
rlog=lanes([("leader",["⟨⟩","⟨a⟩","⟨a,a⟩","⟨a,a⟩","⟨a,a⟩","⟨a,a⟩"]),("f1",["⟨⟩","⟨⟩","⟨⟩","⟨a⟩","⟨a,a⟩","⟨a,a⟩"]),("f2",["⟨⟩","⟨⟩","⟨⟩","⟨⟩","⟨⟩","⟨⟩"]),
 ("commit",["0","0","0","0","0",("2","bad")]),("Committed",["⟨⟩","⟨⟩","⟨⟩","⟨⟩","⟨⟩",("⟨a,a⟩","bad")])],
 "TLC's six-state counterexample for the replicated log. The first five steps leave the mapped log empty, and AdvanceCommit then makes it two entries longer in one step.",
 cols=["Init","Request","Request","Replicate","Replicate","Advance"],labelw=100,cell=82)
tags=sequence(["Tag input","Server"],[
 ("note","Tag input","shows t1, pending"),
 ("Tag input","Server","add t1"),
 ("note","Server","rejects t1",""),
 ("Server","Tag input","rejected t1",{"tone":"bad"}),
 ("note","Tag input","t1 disappears","bad")],
 "The optimistic tag input adds t1 to the screen at once, sends add t1, gets rejected t1 back, and removes t1 from the screen. Shown went from containing t1 to not containing it.",gap=300)
FIGS={"shards":(shards,"A behavior of <code>PSl10_ShardedRestart</code>. The first three steps map to <code>Inc</code>. The restart lowers the sum, and no step of the counter spec can lower it."),
"lsm":(lsm,"Five selected states from the eight-state trace. Each flush moves data without changing the mapped store, and the buggy compaction rolls back two keys in one step."),
"rlog":(rlog,"TLC's shortest counterexample. Replication steps map to stuttering. The jump of the commit index from 0 to 2 would need two abstract appends in one step."),
"tags":(tags,"The rejected path. The user saw t1 (pending), then saw it removed. The server never stored it, so the server's list never shrank.")}
FIGS={k:(v[0].replace("dg-a\"",f"dg-a-psl10-{k}\"").replace("#dg-a)",f"#dg-a-psl10-{k})"),v[1]) for k,v in FIGS.items()}
