# Problem set authoring guide

Each chapter ends with a problem set. Every set tests that chapter together with what came before it, using real systems: algorithms, databases, distributed systems, infrastructure and UI design-system components.

The course is one offline HTML page built from `src/`. Read [the lesson guide](lesson-guide.md) first: its rules on files, diagrams (`dg.py`), voice, accuracy, `tlc.sh`, and checking your work all apply here. This file adds what is specific to problem sets.

## Where problem sets sit
`curriculum.py` lists every lesson in order. A `ps-*` entry closes each chapter (part): `ps-l1`…`ps-l10` after lectures 1–10, `ps-b1`…`ps-b4` after the four "Beyond the lectures" parts, and `ps-final` after the review lesson. A set may use ONLY what the lessons before it teach: read every lesson of your chapter in `src/` closely, and skim earlier ones so you know exactly what syntax, operators, tools and ideas the learner has. The build rejects a `{{lesson:x}}` or `{{ref:x}}` that points forward. If a problem needs something not taught yet, change the problem.

## Cumulative
"Derived from all the previous chapters up to that chapter":
- At least two problems in a set exercise the chapter just finished.
- At least one problem, usually the last ("synthesis"), combines this chapter with ideas from at least two earlier chapters, e.g. the model you built in an earlier set, now checked, extended or refined. Revisiting a system from an earlier set is encouraged: the learner sees one system grow. Name the earlier set's problem when you do.
- Difficulty rises inside a set (first problem easiest) and from set to set.

## Real world
Every problem is a real system or algorithm with its real name and a concrete scenario: a database (transactions, isolation anomalies, replication, migrations, connection pools, MVCC, WAL), a distributed system (quorums, leader election, queues, leases, idempotency), an algorithm (GCD, binary search, sorting, puzzles solved by TLC's search), a UI design system component (button, combobox, toast queue, modal: components as state machines), infrastructure (deploys, Kubernetes rollouts, rate limiters, CI). State facts about real products only when you are sure of them (e.g. "Postgres's `PREPARE TRANSACTION` keeps locks until `COMMIT PREPARED` or `ROLLBACK PREPARED`"); otherwise describe the scenario generically ("a key-value store with N replicas"). Each set is listed below with suggested problems; you may change a problem if it doesn't fit what the chapter actually teaches, keeping the domain mix (every set: at least one database problem; across your sets: at least one UI design-system problem and one algorithm problem).

## Markup
`src/ps-X.html` starts with `<h1>` (the set's theme, e.g. "Problem set 4: let TLC search for you."), then `<p class="lead">` (what the set practices and which chapters it draws on). Then a short `<h2>`-less intro paragraph if needed, then the problems:

```html
<article class="problem" id="ps-l4-migration">
<p class="problem-meta"><span>Problem 1</span><span class="level" title="Difficulty 1 of 3">●○○</span><span class="domain">Databases</span></p>
<h2>Expand and contract a column rename</h2>
<p class="uses">Draws on {{ref:diehard}}, {{ref:actions}} and {{ref:counter}}.</p>
<p>Scenario: who, what system, what goes wrong in production. Concrete.</p>
<!--fig:migration-->
<ol class="tasks">
<li>Task (a) …</li>
<li>Task (b) …</li>
</ol>
<div class="numcheck" data-answer="7|seven" data-explain="Why that is right." data-retry="Optional hint shown on a wrong answer."><label>Length of the shortest trace TLC reports <input type="text" inputmode="numeric" autocomplete="off"></label><button type="button">Check answer</button><p class="quiz-feedback" aria-live="polite"></p></div>
<div class="quiz" data-answer="1" data-explain="Why."><fieldset><legend>Question?</legend><label><input type="radio" name="q-ps-l4-migration" value="0">A</label><label><input type="radio" name="q-ps-l4-migration" value="1">B</label></fieldset><button type="button">Check answer</button><p class="quiz-feedback" aria-live="polite"></p></div>
<details class="hint"><summary>Hint</summary><p>…</p></details>
<details class="answer solution"><summary>Solution</summary><p>…</p><pre><code>…verified spec…</code></pre><p>What TLC reports, and why.</p></details>
</article>
```
- Problem ids start with the set id (`ps-l4-…`). Quiz radio names are unique across the whole course (`q-ps-l4-…`; a second quiz in one problem gets `-2`).
- Difficulty: `●○○`, `●●○`, `●●●` with the matching title. Domain chip: one or two words.
- `<p class="uses">` is required; use `{{ref:id}}` (renders the lesson title as a link). Reference earlier problem sets the same way, e.g. `{{ref:ps-l3}}`.
- `.numcheck` checks a short typed answer: `data-answer` lists accepted forms separated by `|`; matching ignores case, spaces, commas and underscores. Use it for numbers the learner can get by reasoning or by running TLC on a spec you give them in full (states found, shortest trace length, which step fails), never for numbers that depend on how they wrote their own spec.
- Every problem: at least one auto-checked question (`.numcheck` or `.quiz`), one or more tasks, a hint, and a solution. Solutions explain the reasoning, not only the answer.
- Each set: 4 problems (`ps-final`: 5), at least 3 diagrams in the set, each showing the actual mechanism (the bad interleaving, the state graph, the quorum overlap). Problem text 150–450 words, solutions as long as they must be.
- The JS adds "Mark solved" and the solved count; don't write them.

## Accuracy
Every complete module shown (in a task or a solution) lives in `specs/PS<set>_<Name>.tla` + `.cfg` (e.g. `specs/PSl4_Migration.tla`; module name = file name) and you ran it with `./tlc.sh PSl4_Migration`. Every number and trace you state comes from those runs. A "find the bug" problem gives the buggy module, and its solution shows the counterexample TLC actually printed (shortened faithfully). If a spec has a PlusCal algorithm, translate it with `java -cp ../tla2tools.jar pcal.trans` and check the translation. If the chapter has not taught TLC yet (sets 1–2), still check every spec you print. Keep models small enough that TLC finishes in under a minute.

## Checking
```
python3 build.py --partial --out /tmp/course-draft.html     # no ERRORS
COURSE=/tmp/course-draft.html node render.mjs ps-l4 light   # look at shots/ps-l4-light.png; fix clipped or crossing diagrams
```
Check one of your sets in dark and at 390px width. Open each set's solutions in a screenshot at least once (you can render with details open by editing temporarily, or trust the markup if it mirrors a checked one).


## Suggested problems
Sets are listed with their chapter's lessons. The last problem in each list is the synthesis problem.

**ps-l1** (why, states). No TLA+ syntax yet beyond what these lessons show. 1. Elevator door controller: states, steps, which listed sequences are behaviors (a lanes figure). 2. Database transaction lifecycle (active, committed, aborted): which properties are about one state and which about a behavior ("a committed transaction never becomes aborted"). 3. Design system Button (idle, loading, disabled, success, error): choose the variables, decide what to leave out (hover colour, animation), and why. 4. Synthesis: a CI/CD deploy pipeline: why a test suite that passed 1,000 times can still miss a bad behavior; count the interleavings of two deploys (numcheck).

**ps-l2** (program, logic). 1. An HTTP client retry loop (max 3 attempts) in a few lines of code: write Init and Next with a pc variable. 2. Binary search as a state machine: which given steps satisfy Next (evaluate the formula with primed variables). 3. Database connection pool acquire/release: Next as a disjunction; find the step a buggy Next allows. 4. Synthesis: the Button from ps-l1, now as Init and Next; check ps-l1's behaviors against your formulas.

**ps-l3** (tools, counter). 1. Fixed-window API rate limiter: write it, run TLC with an invariant, report states found. 2. Read a TLC error trace: a semaphore-guarded worker pool with a bug; given the module and trace, find the step. 3. Euclid's GCD algorithm with CONSTANTS in the .cfg; invariant that gcd is preserved; what deadlock means here. 4. Synthesis: model-check ps-l2's retry loop; what the deadlock TLC reports means and how to tell a real deadlock from termination.

**ps-l4** (diehard, actions, diehard-tlc). 1. Expand/contract database migration (add column, dual-write, backfill, switch reads, drop): guards and the "NotSolved" invariant trick to make TLC find a safe deploy order. 2. A shopping cart spec with a missing UNCHANGED (frame) bug: what TLC reports. 3. Algorithm puzzle solved by TLC (Tower of Hanoi with 3 disks or the wolf/goat/cabbage river crossing): shortest solution length (numcheck: TLC's BFS gives the shortest). 4. Synthesis: jugs of 4 and 6 litres (or batch sizes) cannot measure 3: TLC finds no violation; connect to the GCD invariant of ps-l3.

**ps-l5** (sets, tcommit). 1. Kubernetes rolling update: pods as a function from Pod to state; invariant "at least N−1 pods serve traffic" with quantifiers. 2. Schema-version agreement among microservices, modeled like TCommit: all adopt v2 or none. 3. Evaluate set/function/quantifier expressions over a replica-status map (numchecks/quizzes). 4. Synthesis: distributed cron (each job runs at most once across nodes): set comprehension, TLC, and the migration ordering idea from ps-l4.

**ps-l6** (transactions, messages). 1. Travel booking (flight, hotel, car) with two-phase commit messages; check consistency. 2. Coordinator crash: Postgres `PREPARE TRANSACTION` leaves prepared transactions holding locks; show the blocking behavior. 3. Why modeling messages as a set covers duplication and reordering; an at-least-once email service. 4. Synthesis: reserving stock across warehouses with TwoPhase; TypeOK and a consistency invariant, with ps-l5's agreement spec as the comparison.

**ps-l7** (replication, paxos-commit, consensus). 1. Dynamo/Cassandra-style R+W>N: TLC finds the stale read when R+W≤N. 2. Quorum placement across data centres (5 nodes in 2 DCs vs 3 DCs): which quorums survive a DC loss (set operations, SUBSET). 3. Raft-style election: at most one leader per term; votes as messages. 4. Synthesis: Paxos Commit vs 2PC for ps-l6's booking: what failure each survives.

**ps-l8** (temporal, implementation). 1. Stuttering: a metrics dashboard clock (hours vs hours:minutes) and why the spec must allow stuttering. 2. Evaluate temporal formulas (as the lesson writes them) on given behaviors of a job's status. 3. Does a write-through cache spec implement a key-value store spec? Check the implication with TLC. 4. Synthesis: does ps-l6's booking 2PC implement ps-l5's agreement spec?

**ps-l9** (abspec, fairness, abp). 1. Job queue worker: "every job is eventually processed"; TLC's liveness result with and without WF. 2. Reader-writer lock in a database: writer starvation; WF vs SF. 3. Alternating bit for an IoT sensor over a lossy link; what breaks if the link can reorder (TLC trace). 4. Synthesis: retries with a bounded channel, fairness, and the 2PC of ps-l6: does every transaction eventually decide?

**ps-l10** (impl-general, refinement). 1. Sharded counter refines a single counter (mapping = sum). 2. LSM tree (memtable plus SSTables) refines a key-value map. 3. Replicated log's commit index refines an append-only log. 4. Synthesis: a design-system optimistic list (pending items) refines the server's list; or a batched writer refines a single-write spec.

**ps-b1** (inventory, pluscal, fifo, mutex). 1. Postgres lost update (read-modify-write of a balance) in PlusCal; fixes: atomic `UPDATE … SET x = x + 1` or `SELECT … FOR UPDATE`. 2. Seat double booking with check-then-insert; a unique constraint as the fix. 3. Kafka-like bounded queue with producer backpressure: ordering and deadlock. 4. Synthesis: a spinlock or Redis `SET NX` lock guarding ps-b1's balance: mutual exclusion and fairness (ps-l9).

**ps-b2** (invariants, composition, scaling, proofs). 1. Bank transfers: conservation of money; the invariant is not inductive; strengthen it. 2. A connection pool: state explosion; symmetry numbers with and without. 3. Compose a client module and an API-gateway rate limiter module (INSTANCE). 4. Synthesis: a TLAPS-style proof outline for ps-b1's fixed counter (SANY-parsed only; say so).

**ps-b3** (idempotency, fencing, reconfiguration). 1. Payment API idempotency keys with retries and crashes: the double charge and the fix. 2. Lease with a GC pause; fencing tokens checked by storage. 3. Adding a replica: unsafe single-step membership change vs joint consensus; quorum overlap. 4. Synthesis: the transactional outbox (database + message broker), at-least-once delivery, idempotent consumer.

**ps-b4** (app-state, cache, capstone). 1. Design-system combobox/typeahead with stale async responses (request id vs abort). 2. Cache-aside with the delete/fill race; a lease or version fix. 3. Read-your-writes with a primary, async replicas and session LSNs. 4. Synthesis: an undoable delete toast in a design system with optimistic UI and server failure.

**ps-final** (all). 1. Snapshot isolation write skew (two on-call doctors): MVCC model, TLC finds it; serializable fix. 2. Order saga with compensations vs 2PC. 3. Multi-leader replication with a G-counter CRDT: convergence, and refinement to a counter. 4. Raft log replication, simplified: log matching. 5. Capstone: a job scheduler with leases, fencing and idempotent effects: design, spec, safety and liveness.
