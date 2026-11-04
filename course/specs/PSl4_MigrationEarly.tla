--------------------------- MODULE PSl4_MigrationEarly ---------------------------
EXTENDS Integers

VARIABLES schema,      \* columns that exist: "old", "both", or "new"
          app,         \* deployed app version, 1..4
          backfilled,  \* the backfill job has finished
          missing      \* some row has no value in email_address

TypeOK == /\ schema \in {"old", "both", "new"}
          /\ app \in 1..4
          /\ backfilled \in {TRUE, FALSE}
          /\ missing \in {TRUE, FALSE}

Init == /\ schema = "old"
        /\ app = 1
        /\ backfilled = FALSE
        /\ missing = TRUE

OldExists == schema \in {"old", "both"}
NewExists == schema \in {"both", "new"}

\* v1 reads and writes email; v2 writes both; v3 reads email_address;
\* v4 writes only email_address.
WritesOld == app \in {1, 2, 3}
WritesNew == app \in {2, 3, 4}
ReadsNew  == app \in {3, 4}

AddColumn == /\ schema = "old"
             /\ schema' = "both"
             /\ app' = app
             /\ backfilled' = backfilled
             /\ missing' = missing

DeployV2 == /\ app = 1
            /\ NewExists
            /\ app' = 2
            /\ schema' = schema
            /\ backfilled' = backfilled
            /\ missing' = missing

Backfill == /\ ~backfilled
            /\ NewExists
            /\ backfilled' = TRUE
            /\ missing' = FALSE
            /\ schema' = schema
            /\ app' = app

DeployV3 == /\ app = 2
            /\ backfilled
            /\ app' = 3
            /\ schema' = schema
            /\ backfilled' = backfilled
            /\ missing' = missing

DeployV4 == /\ app = 3
            /\ app' = 4
            /\ schema' = schema
            /\ backfilled' = backfilled
            /\ missing' = missing

DropOld == /\ schema = "both"
           /\ app = 4
           /\ schema' = "new"
           /\ app' = app
           /\ backfilled' = backfilled
           /\ missing' = missing

\* A user signs up while v1 is live: the new row gets only email.
SignUp == /\ app = 1
          /\ missing' = TRUE
          /\ schema' = schema
          /\ app' = app
          /\ backfilled' = backfilled

Next == \/ AddColumn \/ DeployV2 \/ Backfill \/ DeployV3
        \/ DeployV4 \/ DropOld \/ SignUp

WritesOK == /\ (WritesOld => OldExists)
            /\ (WritesNew => NewExists)
ReadsOK == IF ReadsNew THEN NewExists /\ ~missing ELSE OldExists
NotDone == ~(schema = "new" /\ app = 4)
=============================================================================
