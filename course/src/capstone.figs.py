import sys,os; sys.path.insert(0,os.path.join(os.path.dirname(__file__),".."))
from dg import graph,sequence,lanes,regions
arch=regions([
 (10,10,530,84,"Identity: which request is this?","accent"),
 (10,104,530,84,"Transaction: one outcome per transfer","accent"),
 (10,198,530,84,"Delivery: an effect downstream","accent"),
 (552,10,138,272,"Authority","muted"),
],"Three stacked boundaries and a side column. Identity holds clients with stable IDs and an API with deduplication. Transaction holds shard A, a decision service and shard B. Delivery holds a durable outbox, event transport and an idempotent consumer. The authority column, covering leaders, epochs and membership, spans all three.",width=700,height=292,notes=[
 (140,62,"Clients, stable IDs"),(400,62,"API + deduplication"),
 (90,156,"Shard A"),(270,156,"Decision service"),(450,156,"Shard B"),
 (90,250,"Durable outbox"),(270,250,"Event transport"),(450,250,"Idempotent consumer"),
 (621,100,"leaders"),(621,146,"epochs"),(621,192,"membership")])
retry=sequence(["Browser","East","West","Provider"],[
 ("Browser","East","order r42, $100"),
 ("East","Provider","charge r42"),
 ("Provider","East","charged"),
 ("East","Browser","reply",{"lost":True,"tone":"bad"}),
 ("Browser","West","retry r42",{"dash":True}),
 ("West","Provider","charge r42"),
 ("Provider","West","saved result",{"tone":"good"}),
 ("West","Browser","same order",{"tone":"good"}),
],"East charges r42 and its reply is lost. The browser retries r42 through West. The provider recognizes r42 and returns the saved result, and West answers with the same order.",gap=170,step=36)
newid=lanes([("attempts",["r42","r42,r43","r42,r43","r42,r43","r42,r43","r42,r43"]),("stockFree",["2","2","1","1","0","0"]),("charges r42",["0","0","0",("1","accent"),"1","1"]),("charges r43",["0","0","0","0","0",("1","bad")])],
"TLC trace with a new ID on retry and two in stock: Retry adds r43, r42 reserves and pays, r43 reserves and pays, and both IDs have one charge.",cols=["Init","Retry","Reserve 42","Pay 42","Reserve 43","Pay 43"],labelw=100,cell=88)
stale=sequence(["Epoch 7 worker","New leader","Shard"],[
 ("New leader","Shard","debit, epoch 8"),("note","Shard","fence = 8"),
 ("Epoch 7 worker","Shard","debit, epoch 7",{"tone":"good"}),("note","Shard","7 < 8: rejected","good"),
],"The new leader writes with epoch 8 and the shard records fence 8. A delayed debit from an epoch 7 worker reaches the shard and is rejected.",gap=210,step=38)
ship=sequence(["Outbox","Consumer","Shipping"],[
 ("Outbox","Consumer","event r42"),("Consumer","Shipping","create shipment"),
 ("note","Consumer","crash before record","bad"),
 ("Outbox","Consumer","event r42 again",{"dash":True}),("Consumer","Shipping","create shipment",{"tone":"bad"}),
 ("note","Shipping","shipments[r42] = 2","bad"),
],"The outbox delivers r42, the consumer creates a shipment and crashes before recording it. The event is delivered again and a second shipment is created.",gap=210,step=38)
FIGS={"arch":(arch,"Each band has its own failure and its own property. Authority cuts across all three, so a stale leader can damage any of them."),
"retry":(retry,"Trace A with a stable ID. The region changed; the logical order did not. The dashed retry is an extra delivery, not a new order."),
"newid":(newid,"TLC’s counterexample when the browser mints a new ID. Each ID is charged once, so a per-ID check passes while the buyer pays twice."),
"stale":(stale,"Trace B. The rejection happens at the shard, where the write is accepted, as in {{lesson:fencing}}."),
"ship":(ship,"Trace C with no consumer record, matching TLC’s trace: two <code>Consume(\"r42\")</code> steps and two shipments.")}
