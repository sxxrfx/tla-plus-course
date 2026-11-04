#!/usr/bin/env python3
"""Exercise an isolated course server; never touch the installed app's progress.

Reports one release-build run's process snapshots, not a universal leak proof or
an end-to-end browser memory measurement. Uses only Python's standard library.
"""
from __future__ import annotations

import argparse
import http.client
import json
import os
from pathlib import Path
import re
import selectors
import socket
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlparse
import uuid


class Server:
    def __init__(self, binary: Path, course: Path, progress: Path, work: Path):
        with socket.socket() as reservation:
            reservation.bind(("127.0.0.1", 0))
            port = reservation.getsockname()[1]
        self.log_path = work / f"server-{uuid.uuid4().hex}.log"
        self.log = self.log_path.open("wb")
        self.process = subprocess.Popen(
            [str(binary), "--course", str(course), "--progress", str(progress),
             "--port", str(port)],
            stdout=subprocess.PIPE, stderr=self.log,
        )
        self.base = None
        try:
            with selectors.DefaultSelector() as selector:
                selector.register(self.process.stdout, selectors.EVENT_READ)
                if not selector.select(10):
                    raise AssertionError("Server did not print its URL within 10 seconds")
                line = self.process.stdout.readline().decode("utf-8").strip()
            self.base = urlparse(line)
            assert self.base.scheme == "http" and self.base.hostname == "127.0.0.1", line
            assert self.base.port == port and self.base.path.endswith("/"), line
            assert len(self.base.path.strip("/")) >= 16, "Missing capability token"
        except BaseException:
            self.stop()
            raise

    def request(self, method="GET", suffix="", body=None, path=None):
        connection = http.client.HTTPConnection("127.0.0.1", self.base.port, timeout=5)
        try:
            headers = {"Content-Type": "application/json"} if body is not None else {}
            connection.request(method, path if path is not None else self.base.path + suffix,
                               body=body, headers=headers)
            response = connection.getresponse()
            return response.status, response.read(), dict(response.getheaders())
        finally:
            connection.close()

    def sse(self):
        identifier = str(uuid.uuid4())
        connection = http.client.HTTPConnection("127.0.0.1", self.base.port, timeout=5)
        connection.request("GET", self.base.path + "live?id=" + identifier)
        response = connection.getresponse()
        assert response.status == 200, f"SSE status {response.status}"
        assert response.getheader("Content-Type", "").startswith("text/event-stream")
        lines = []
        for _ in range(8):
            line = response.fp.readline()
            lines.append(line)
            if line in (b"\n", b"\r\n"):
                break
        assert b"connected" in b"".join(lines), f"SSE initial frame: {lines!r}"
        return identifier, connection, response

    def stop(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=4)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=4)
        if self.process.stdout:
            self.process.stdout.close()
        self.log.close()


def snapshot(pid, label):
    def command(*args):
        result = subprocess.run(args, text=True, capture_output=True, timeout=10)
        if result.returncode:
            raise RuntimeError(f"{' '.join(args)} failed: {result.stderr.strip()}")
        return result.stdout
    descriptors = command("lsof", "-nP", "-a", "-p", str(pid), "-Ff")
    threads = command("ps", "-M", "-p", str(pid))
    rss = command("ps", "-p", str(pid), "-o", "rss=")
    return {
        "label": label,
        "numeric_file_descriptors": sum(bool(re.fullmatch(r"f\d+", line))
                                        for line in descriptors.splitlines()),
        "threads": max(0, len([line for line in threads.splitlines() if line.strip()]) - 1),
        "rss_kib": int(rss.strip()),
    }


def encode(payload):
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


def expect(status, expected, context, body=b""):
    assert status == expected, f"{context}: expected HTTP {expected}, got {status}: {body[:200]!r}"


def check_html(server, source, expected_progress):
    status, body, _ = server.request()
    expect(status, 200, "Course GET", body)
    content = body.decode("utf-8")
    assert "__courseProgress" in content, "Initial progress was not injected"
    assert "__courseSavePath" in content, "Save path was not injected"
    first_script = re.search(r"<script\b[^>]*>.*?</script\s*>", source, re.I | re.S)
    if first_script:
        original_at = content.find(first_script.group())
        assert original_at >= 0, "Original course script was changed or removed"
        assert content.index("__courseProgress") < original_at, "Progress injected too late"
    status, body, _ = server.request(suffix="progress")
    expect(status, 200, "Progress GET", body)
    assert json.loads(body) == expected_progress, "Progress GET did not round-trip"
    return len(content.encode("utf-8"))


def split_post(server, payload):
    raw_body = encode(payload)
    headers = (
        f"POST {server.base.path}progress HTTP/1.1\r\n"
        f"Host: 127.0.0.1:{server.base.port}\r\n"
        "Content-Type: application/json\r\n"
        f"Content-Length: {len(raw_body)}\r\nConnection: close\r\n\r\n"
    ).encode("ascii")
    with socket.create_connection(("127.0.0.1", server.base.port), timeout=5) as connection:
        # Split both headers and body; the server must frame before parsing JSON.
        for chunk in (headers[:17], headers[17:], raw_body[:1], raw_body[1:19], raw_body[19:]):
            connection.sendall(chunk)
            time.sleep(0.01)
        response = http.client.HTTPResponse(connection)
        response.begin()
        body = response.read()
        expect(response.status, 200, "Split POST", body)
        ack = json.loads(body)
        assert ack.get("saved") is True
        assert isinstance(ack.get("updatedAt"), (int, float))
        return ack


def oversized_post(server):
    connection = http.client.HTTPConnection("127.0.0.1", server.base.port, timeout=5)
    try:
        connection.putrequest("POST", server.base.path + "progress")
        connection.putheader("Content-Type", "application/json")
        connection.putheader("Content-Length", str(2 * 1024 * 1024 + 1))
        connection.endheaders()
        response = connection.getresponse()
        return response.status, response.read()
    finally:
        connection.close()


def run(args):
    binary = args.binary.resolve()
    course = args.course.resolve()
    assert binary.is_file(), f"Build the release server first: missing {binary}"
    assert course.is_file(), f"Missing course: {course}"
    assert args.requests >= 300, "Use at least 300 ordinary requests for the resource check"
    assert args.sse_cycles >= 1
    report = {
        "kind": "one isolated functional/resource run",
        "binary": str(binary),
        "course": str(course),
        "ordinary_success_responses": 0,
        "expected_rejections": 0,
        "sse_connections_verified": 0,
        "unexpected_failures": 0,
        "snapshots": [],
        "limitations": [
            "RSS is the Rust server only; no browser or WebKit process is included.",
            "One persistent SSE connection emulates one open tab; this is not a browser UI test.",
            "FD/thread stability and RSS snapshots cover this one run and workload, not all leak paths.",
            "This is not a throughput or latency benchmark and makes no old/new comparison.",
        ],
    }
    report["load_average"] = list(os.getloadavg()) if hasattr(os, "getloadavg") else None
    report["logical_cpus"] = os.cpu_count()
    source = course.read_text(encoding="utf-8")
    payload = {
        "done": {"orientation": True, "states": False},
        "notes": {"orientation": "A durable note: 🧠, quotes \" and newline\nsecond line"},
        "answers": {"states": "1"},
        "reading": {"states": 0.3125},
        "current": "states",
        "theme": "dark",
        "updatedAt": 1780000000000,
    }
    server = None
    anchor = None
    try:
        with tempfile.TemporaryDirectory(prefix="tla-server-check-") as dirname:
            work = Path(dirname)
            progress = work / "progress.json"
            server = Server(binary, course, progress, work)
            report["html_bytes_with_injection"] = check_html(server, source, None)
            report["ordinary_success_responses"] += 2
            ack = split_post(server, payload)
            payload["updatedAt"] = ack["updatedAt"]
            report["ordinary_success_responses"] += 1
            assert json.loads(progress.read_text(encoding="utf-8")) == payload, "Disk snapshot differs"
            report["saved_file_mode"] = oct(progress.stat().st_mode & 0o777)
            assert progress.stat().st_mode & 0o077 == 0, "Progress is readable by other users"
            server.stop()
            server = Server(binary, course, progress, work)
            check_html(server, source, payload)
            report["ordinary_success_responses"] += 2
            report["restart_roundtrip"] = "passed"
            stale = json.loads(json.dumps(payload))
            stale["updatedAt"] -= 1
            stale["notes"]["orientation"] = "This old snapshot must not replace the saved note"
            status, body, _ = server.request("POST", "progress", encode(stale))
            expect(status, 200, "Stale snapshot acknowledgement", body)
            assert json.loads(body).get("updatedAt") == payload["updatedAt"]
            status, body, _ = server.request(suffix="progress")
            expect(status, 200, "Progress after stale write", body)
            assert json.loads(body) == payload, "A stale snapshot overwrote newer progress"
            assert json.loads(progress.read_text(encoding="utf-8")) == payload
            report["ordinary_success_responses"] += 2
            report["stale_write_preservation"] = "passed"

            for path in ("/", "/not-the-token/progress", server.base.path + "unknown"):
                status, body, _ = server.request(path=path)
                expect(status, 404, "Wrong token/route", body)
                report["expected_rejections"] += 1
            bad_payloads = [b"{", b"[]", encode({"done": {"orientation": "yes"}}),
                            encode({"notes": {"orientation": 1}}),
                            encode({"reading": {"states": "twelve"}}),
                            encode({"reading": {"states": 1.1}}),
                            b'{"reading":{"states":NaN}}', encode({"theme": "purple"})]
            for raw in bad_payloads:
                status, body, _ = server.request("POST", "progress", raw)
                expect(status, 400, "Malformed/schema POST", body)
                report["expected_rejections"] += 1
            status, body = oversized_post(server)
            expect(status, 413, "Oversized POST", body)
            report["expected_rejections"] += 1
            status, body, _ = server.request(suffix="progress")
            expect(status, 200, "Snapshot after rejected writes", body)
            assert json.loads(body) == payload, "Rejected write changed saved progress"
            report["ordinary_success_responses"] += 1

            anchor = server.sse()
            report["sse_connections_verified"] += 1
            time.sleep(0.2)
            report["snapshots"].append(snapshot(server.process.pid, "one_live_connection_idle"))
            checkpoints = {args.requests // 4, args.requests // 2, args.requests * 3 // 4, args.requests}
            cycles_done = 0
            for i in range(1, args.requests + 1):
                if i % 10 == 0:
                    payload["reading"]["states"] = float(i) / args.requests
                    payload["updatedAt"] += 1
                    status, body, _ = server.request("POST", "progress", encode(payload))
                    expect(status, 200, "Soak POST", body)
                    ack = json.loads(body)
                    assert ack.get("saved") is True, "Write acknowledgement missing"
                    assert ack.get("updatedAt", 0) >= payload["updatedAt"], "Timestamp not monotonic"
                    payload["updatedAt"] = ack["updatedAt"]
                elif i % 2:
                    status, body, _ = server.request()
                    expect(status, 200, "Soak HTML GET", body)
                    assert b"__courseProgress" in body and b"__courseSavePath" in body
                else:
                    status, body, _ = server.request(suffix="progress")
                    expect(status, 200, "Soak progress GET", body)
                    assert json.loads(body) == payload
                report["ordinary_success_responses"] += 1
                target_cycles = i * args.sse_cycles // args.requests
                while cycles_done < target_cycles:
                    _, conn, response = server.sse()
                    response.close()
                    conn.close()
                    cycles_done += 1
                    report["sse_connections_verified"] += 1
                if i in checkpoints:
                    time.sleep(0.1)
                    report["snapshots"].append(snapshot(server.process.pid, f"after_{i}_requests"))
            time.sleep(0.5)
            report["snapshots"].append(snapshot(server.process.pid, "completed_connections_settled"))
            baseline = report["snapshots"][0]
            settled = report["snapshots"][-1]
            report["fd_delta_settled"] = settled["numeric_file_descriptors"] - baseline["numeric_file_descriptors"]
            report["thread_delta_settled"] = settled["threads"] - baseline["threads"]
            assert report["fd_delta_settled"] <= args.fd_slack, "Completed connections retained too many FDs"
            assert report["thread_delta_settled"] <= args.thread_slack, "Completed connections retained too many threads"
            assert all(s["numeric_file_descriptors"] <= baseline["numeric_file_descriptors"] + args.fd_slack
                       for s in report["snapshots"]), "FD count grew beyond allowed slack"
            assert all(s["threads"] <= baseline["threads"] + args.thread_slack
                       for s in report["snapshots"]), "Thread count grew beyond allowed slack"
            assert json.loads(progress.read_text(encoding="utf-8")) == payload, "Final disk write missing"
            report["successful_soak_writes"] = args.requests // 10
            report["sse_churn_cycles"] = cycles_done
            identifier, connection, response = anchor
            status, body, _ = server.request("POST", "leave?id=" + identifier, b"")
            assert status in (200, 204), f"Last tab leave: HTTP {status}: {body[:200]!r}"
            report["ordinary_success_responses"] += 1
            response.close()
            connection.close()
            anchor = None
            started_wait = time.monotonic()
            try:
                exit_code = server.process.wait(timeout=15)
            except subprocess.TimeoutExpired as exc:
                raise AssertionError("Server did not exit within 15 seconds after last live client left") from exc
            assert exit_code == 0, f"Idle exit code {exit_code}"
            report["last_client_exit_seconds"] = round(time.monotonic() - started_wait, 3)
            report["result"] = "passed"
            return report
    except BaseException:
        report["unexpected_failures"] += 1
        report["result"] = "failed"
        if server and server.log_path.exists():
            if not server.log.closed:
                server.log.flush()
            report["server_stderr"] = server.log_path.read_text(encoding="utf-8", errors="replace")[-4000:]
        print(json.dumps(report, indent=2), file=sys.stderr)
        raise
    finally:
        if anchor:
            anchor[2].close()
            anchor[1].close()
        if server:
            server.stop()


def main():
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", type=Path, default=root / "mac-app/server/target/release/tla-course-server")
    parser.add_argument("--course", type=Path, default=root / "tla-plus-course.html")
    parser.add_argument("--requests", type=int, default=1000)
    parser.add_argument("--sse-cycles", type=int, default=200)
    parser.add_argument("--fd-slack", type=int, default=4)
    parser.add_argument("--thread-slack", type=int, default=2)
    args = parser.parse_args()
    try:
        report = run(args)
    except (AssertionError, OSError, RuntimeError, ValueError, subprocess.SubprocessError) as exc:
        print(f"CHECK FAILED: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
