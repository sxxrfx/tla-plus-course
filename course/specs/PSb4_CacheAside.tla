---------------- MODULE PSb4_CacheAside ----------------
EXTENDS Naturals
CONSTANTS Leases, DeleteFirst, MaxVersion
ASSUME Leases \in BOOLEAN /\ DeleteFirst \in BOOLEAN
VARIABLES db,       \* the row's version in the database
          cache,    \* the cached version, or 0 for a miss
          lease,    \* the cache's outstanding lease token, 0 for none
          tokens,   \* lease tokens issued so far
          rpc,      \* reader: "idle", "reading" or "setting"
          rtoken,   \* the lease token the reader holds
          rval,     \* the version the reader read from the database
          wpc       \* writer: "idle", "updated" or "deleted"
vars == <<db, cache, lease, tokens, rpc, rtoken, rval, wpc>>

Init == /\ db = 1 /\ cache = 0 /\ lease = 0 /\ tokens = 0
        /\ rpc = "idle" /\ rtoken = 0 /\ rval = 0
        /\ wpc = "idle"

\* Reader: GET misses. With leases, the cache hands out a token.
Miss == /\ rpc = "idle" /\ cache = 0
        /\ IF Leases THEN /\ tokens' = tokens + 1
                          /\ lease' = tokens + 1
                          /\ rtoken' = tokens + 1
                     ELSE UNCHANGED <<tokens, lease, rtoken>>
        /\ rpc' = "reading"
        /\ UNCHANGED <<db, cache, rval, wpc>>
\* Reader: SELECT from the database.
Read == /\ rpc = "reading"
        /\ rval' = db
        /\ rpc' = "setting"
        /\ UNCHANGED <<db, cache, lease, tokens, rtoken, wpc>>
\* Reader: SET the value. With leases, only if the token is still valid.
Set == /\ rpc = "setting"
       /\ IF ~Leases \/ lease = rtoken
             THEN cache' = rval /\ lease' = 0
             ELSE UNCHANGED <<cache, lease>>
       /\ rpc' = "idle"
       /\ UNCHANGED <<db, tokens, rtoken, rval, wpc>>

\* Writer: UPDATE the database and DELETE the cache key, in either order.
\* A delete also invalidates any outstanding lease.
Update == /\ db < MaxVersion
          /\ wpc = IF DeleteFirst THEN "deleted" ELSE "idle"
          /\ db' = db + 1
          /\ wpc' = IF DeleteFirst THEN "idle" ELSE "updated"
          /\ UNCHANGED <<cache, lease, tokens, rpc, rtoken, rval>>
Delete == /\ wpc = IF DeleteFirst THEN "idle" ELSE "updated"
          /\ (DeleteFirst => db < MaxVersion)
          /\ cache' = 0 /\ lease' = 0
          /\ wpc' = IF DeleteFirst THEN "deleted" ELSE "idle"
          /\ UNCHANGED <<db, tokens, rpc, rtoken, rval>>

Next == Miss \/ Read \/ Set \/ Update \/ Delete
Spec == Init /\ [][Next]_vars

\* Once the writer has finished, a cached value is the current one.
FreshAfterWrite == (wpc = "idle" /\ cache # 0) => cache = db
=========================================================
