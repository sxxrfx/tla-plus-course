# Course server

Build with `cargo build --release --locked`. The binary is named `tla-course-server`.

```sh
tla-course-server --course /absolute/path/course.html --progress /absolute/path/progress.json
```

`--port` overrides the default loopback port 49731; `--port 0` requests an ephemeral port for isolated tests. On readiness, stdout contains exactly one line: the full tokenized URL. Startup/runtime failures go to stderr and return a nonzero exit code. The native launcher starts this binary; it does not need to remain resident.

The server uses safe Rust, one thread, and mio's OS event poller. There is no web framework, async runtime, worker pool, or periodic browser polling. Ordinary responses close their socket when fully sent. Every course GET reads the current HTML and injects the current disk snapshot before existing scripts. The file is limited to 8 MiB.

Each page maintains a UUID-addressed EventSource. Live streams get a 15-second keepalive and retain no sent response buffer. An EOF, socket error, or pagehide leave beacon removes the stream. The process exits five seconds after the final stream disappears, allowing a reload/reconnect to arrive. If no page establishes a stream, it exits after 90 seconds; requesting the course without an active stream starts a fresh opening window. Quiet connected pages have no reading timeout.

## Progress API

Routes are relative to the per-run 256-bit random URL token. No other interface is exposed.

- `GET progress`: the saved JSON snapshot, or `null` if there is no file.
- `POST progress`: validate and atomically save a full snapshot; acknowledge with `{ "saved": true, "updatedAt": ... }`.

The permitted optional fields are `done` (boolean map), `notes` (string map), `answers` (string map), `reading` (numeric 0–1 fraction map), `current` (identifier), `theme` (`light` or `dark`), and `updatedAt` (finite nonnegative epoch milliseconds below 10^16). Maps permit at most 2048 entries, identifiers are 1–128 ASCII letters/digits/hyphens/underscores, notes are at most 64 KiB each, and answers are at most 128 bytes. Unknown fields and invalid values are rejected without writing. Explicit `false` completion states remain meaningful.

A snapshot with `updatedAt` no greater than the current saved timestamp is acknowledged without replacing newer data. The frontend serializes saves and coalesces changes; this timestamp check prevents an older delayed beacon from reverting acknowledged progress. It is not a multi-user merge protocol. If a timestamp is omitted, the server generates a value newer than the existing one.

Writes use a same-directory temporary file, `write_all`, file `fsync`, atomic rename, and directory `fsync`. New progress directories are private (0700); each replacement file is 0600. Existing directory permissions are not changed. Invalid existing snapshots cause an error and are preserved. JSON inserted into a script escapes `<` and Unicode line separators. POST requests carrying an Origin must match this loopback origin.

## Bounds and cleanup

There are at most 128 open connections. Header input is limited to 16 KiB, bodies to 2 MiB, and aggregate retained input/output buffer capacity to 16 MiB. Incomplete HTTP requests and stalled responses expire after 15 seconds without I/O. A slow stream cannot accumulate keepalives indefinitely. All disconnect/error/timeout paths deregister and drop the socket and its buffers. Completed output buffers are replaced with empty vectors, releasing their allocations. Diagnostic logs do not accumulate per request.

Only Content-Length request framing is supported. Transfer-Encoding, duplicate/invalid lengths, oversized input, and malformed requests are rejected. Header and body parsing handles fragmentation across TCP packets. Persistent HTTP connections and pipelining are intentionally unsupported; SSE is the sole long-lived response.

Durable file reads and writes run synchronously on the event-loop thread. This keeps resident memory and thread count small; a slow or failing filesystem can briefly delay other requests. The service is designed for a small local course file and local private progress storage, not network filesystems or public traffic.

## Verification

```sh
cargo fmt --check
cargo test
cargo clippy --all-targets -- -D warnings
cargo build --release --locked
```

Unit tests cover fragmented bodies, ambiguous framing, input bounds, progress schema, explicit false states, script-safe bootstrap injection, UUID validation, atomic persistence and permissions, stale-save suppression, and preservation of malformed disk snapshots. The parent app's `mac-app/check-server.py` exercises the actual binary, concurrent EventSource lifetimes, HTTP churn, restart persistence, and resource behavior. A bounded stress run can demonstrate cleanup under those conditions; it cannot establish absence of every possible leak or operating-system defect.

## Native controller controls

The menu-bar controller can call two additional token-authenticated POST routes. As with progress writes, any supplied Origin must match the loopback server origin. GET requests do not activate these controls.

- `POST shutdown` acknowledges `{ "stopping": true }` with HTTP 200, then exits about 200 ms later so the small response can flush.
- `POST uninstall` acknowledges the same JSON, broadcasts `event: uninstall` / `data: {}` to every live EventSource, rejects subsequent progress POSTs with HTTP 410, and exits about one second later. A stream reconnecting during that interval receives the event too. Repeated uninstall calls do not extend the deadline.

An explicit stop deadline takes priority over the ordinary startup/last-page timers. The service retains its connection and buffer bounds during this interval. Neither control deletes any files. The native controller is responsible for user confirmation, waiting for the service to stop, and then deleting only the app and its course-data directory. Browser pages handle the named event by stopping autosaves and removing the course's own browser-local state.

An isolated control integration check verified two simultaneous event streams received uninstall, progress POST returned 410, wrong tokens and cross-origin controls were rejected, and both paths exited successfully while preserving the synthetic progress file. Measured exit times in that check were approximately 1.04 seconds for uninstall and 0.24 seconds for shutdown; these include process-wait overhead and are not response-time guarantees.
