---------------- MODULE JobQueue ----------------
CONSTANT Jobs
VARIABLE pending
Queue == INSTANCE BoundedFIFO
    WITH Values <- Jobs, Capacity <- 2, q <- pending
Spec == Queue!Spec
QueueSafe == Queue!TypeOK
=================================================
