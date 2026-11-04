use mio::net::{TcpListener, TcpStream};
use mio::{Events, Interest, Poll, Token};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{self, Read, Write};
use std::net::{Ipv4Addr, SocketAddr};
use std::os::unix::fs::{DirBuilderExt, OpenOptionsExt};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

const LISTENER: Token = Token(0);
const MAX_CONNECTIONS: usize = 128;
const MAX_HEADER: usize = 16 * 1024;
const MAX_BODY: usize = 2 * 1024 * 1024;
const MAX_HTML: u64 = 8 * 1024 * 1024;
const MAX_BUFFERED: usize = 16 * 1024 * 1024;
const REQUEST_TIMEOUT: Duration = Duration::from_secs(15);
const HEARTBEAT: Duration = Duration::from_secs(15);
const STARTUP_TIMEOUT: Duration = Duration::from_secs(90);
const CLOSE_GRACE: Duration = Duration::from_secs(5);
const UNINSTALL_EVENT: &[u8] = b"event: uninstall\ndata: {}\n\n";
const SSE_INITIAL: &[u8] = b"HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-store\r\nConnection: keep-alive\r\nX-Content-Type-Options: nosniff\r\n\r\nretry: 1000\ndata: connected\n\n";

struct Options {
    course: PathBuf,
    progress: PathBuf,
    port: u16,
}

impl Options {
    fn parse() -> Result<Self, String> {
        let mut args = env::args_os().skip(1);
        let (mut course, mut progress, mut port) = (None, None, 49731);
        while let Some(arg) = args.next() {
            let value = args.next().ok_or("Each option needs a value")?;
            match arg.to_str() {
                Some("--course") => course = Some(PathBuf::from(value)),
                Some("--progress") => progress = Some(PathBuf::from(value)),
                Some("--port") => {
                    port = value
                        .to_str()
                        .ok_or("Invalid port")?
                        .parse()
                        .map_err(|_| "Invalid port")?;
                }
                _ => {
                    return Err(
                        "Usage: tla-course-server --course PATH --progress PATH [--port PORT]"
                            .into(),
                    )
                }
            }
        }
        Ok(Self {
            course: course.ok_or("Missing --course")?,
            progress: progress.ok_or("Missing --progress")?,
            port,
        })
    }
}

struct Connection {
    socket: TcpStream,
    input: Vec<u8>,
    output: Vec<u8>,
    sent: usize,
    page: Option<String>,
    responding: bool,
    touched: Instant,
}

impl Connection {
    fn buffered(&self) -> usize {
        self.input.capacity() + self.output.capacity()
    }

    fn response(&mut self, status: &str, content_type: &str, body: &[u8]) {
        self.input = Vec::new();
        let header = format!(
            "HTTP/1.1 {status}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nConnection: close\r\n\r\n",
            body.len()
        );
        self.output = Vec::with_capacity(header.len() + body.len());
        self.output.extend_from_slice(header.as_bytes());
        self.output.extend_from_slice(body);
        self.sent = 0;
        self.responding = true;
        self.touched = Instant::now();
    }

    fn error(&mut self, status: &str, message: &str) {
        self.response(
            status,
            "application/json; charset=utf-8",
            json!({"error":message}).to_string().as_bytes(),
        );
    }
}

struct Request {
    method: String,
    target: String,
    origin: Option<String>,
    body: Vec<u8>,
}

enum Parsed {
    Pending,
    Complete(Request),
    Error(&'static str, &'static str),
}

fn parse_request(bytes: &[u8]) -> Parsed {
    let Some(end) = bytes
        .windows(4)
        .position(|part| part == b"\r\n\r\n")
        .map(|n| n + 4)
    else {
        return if bytes.len() >= MAX_HEADER {
            Parsed::Error(
                "431 Request Header Fields Too Large",
                "Request headers exceed 16 KiB",
            )
        } else {
            Parsed::Pending
        };
    };
    if end > MAX_HEADER {
        return Parsed::Error(
            "431 Request Header Fields Too Large",
            "Request headers exceed 16 KiB",
        );
    }
    let mut headers = [httparse::EMPTY_HEADER; 64];
    let mut request = httparse::Request::new(&mut headers);
    if !matches!(
        request.parse(&bytes[..end]),
        Ok(httparse::Status::Complete(_))
    ) {
        return Parsed::Error("400 Bad Request", "Malformed HTTP headers");
    }
    let mut length = None;
    let mut origin = None;
    for header in request.headers.iter() {
        if header.name.eq_ignore_ascii_case("transfer-encoding") {
            return Parsed::Error("400 Bad Request", "Transfer-Encoding is unsupported");
        }
        if header.name.eq_ignore_ascii_case("content-length") {
            if length.is_some() {
                return Parsed::Error("400 Bad Request", "Duplicate Content-Length");
            }
            let Ok(value) = std::str::from_utf8(header.value) else {
                return Parsed::Error("400 Bad Request", "Invalid Content-Length");
            };
            if value.is_empty() || !value.bytes().all(|b| b.is_ascii_digit()) {
                return Parsed::Error("400 Bad Request", "Invalid Content-Length");
            }
            let Ok(value) = value.parse::<usize>() else {
                return Parsed::Error("413 Payload Too Large", "Request body exceeds 2 MiB");
            };
            if value > MAX_BODY {
                return Parsed::Error("413 Payload Too Large", "Request body exceeds 2 MiB");
            }
            length = Some(value);
        }
        if header.name.eq_ignore_ascii_case("origin") {
            if origin.is_some() {
                return Parsed::Error("400 Bad Request", "Duplicate Origin");
            }
            let Ok(value) = std::str::from_utf8(header.value) else {
                return Parsed::Error("400 Bad Request", "Invalid Origin");
            };
            origin = Some(value.to_owned());
        }
    }
    let length = length.unwrap_or(0);
    if bytes.len() < end + length {
        return Parsed::Pending;
    }
    Parsed::Complete(Request {
        method: request.method.unwrap_or("").to_owned(),
        target: request.path.unwrap_or("").to_owned(),
        origin,
        body: bytes[end..end + length].to_vec(),
    })
}

fn identifier(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 128
        && value
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
}

fn validate_progress(value: &Value) -> Result<(), &'static str> {
    let object = value.as_object().ok_or("Progress must be an object")?;
    for (key, value) in object {
        match key.as_str() {
            "done" | "notes" | "answers" | "reading" => {
                let map = value.as_object().ok_or("Progress maps must be objects")?;
                if map.len() > 2048 {
                    return Err("Too many progress entries");
                }
                for (id, entry) in map {
                    if !identifier(id) {
                        return Err("Invalid lesson or answer identifier");
                    }
                    let valid = match key.as_str() {
                        "done" => entry.is_boolean(),
                        "notes" => entry.as_str().is_some_and(|s| s.len() <= 65536),
                        "answers" => entry.as_str().is_some_and(|s| s.len() <= 128),
                        "reading" => entry
                            .as_f64()
                            .is_some_and(|n| n.is_finite() && (0.0..=1.0).contains(&n)),
                        _ => false,
                    };
                    if !valid {
                        return Err("Invalid progress entry value");
                    }
                }
            }
            "current" if value.as_str().is_some_and(identifier) => {}
            "theme" if matches!(value.as_str(), Some("light" | "dark")) => {}
            "updatedAt"
                if value
                    .as_f64()
                    .is_some_and(|n| n.is_finite() && (0.0..1.0e16).contains(&n)) => {}
            _ => return Err("Unknown progress field or invalid value"),
        }
    }
    Ok(())
}

fn read_progress(path: &Path) -> io::Result<Value> {
    let file = match File::open(path) {
        Ok(file) => file,
        Err(error) if error.kind() == io::ErrorKind::NotFound => return Ok(Value::Null),
        Err(error) => return Err(error),
    };
    if file.metadata()?.len() > MAX_BODY as u64 {
        return Err(io::Error::other("Progress file exceeds 2 MiB"));
    }
    let mut bytes = Vec::new();
    file.take(MAX_BODY as u64 + 1).read_to_end(&mut bytes)?;
    if bytes.len() > MAX_BODY {
        return Err(io::Error::other("Progress file exceeds 2 MiB"));
    }
    let value: Value = serde_json::from_slice(&bytes)?;
    validate_progress(&value).map_err(io::Error::other)?;
    Ok(value)
}

fn save_progress(path: &Path, value: &mut Value, suffix: &str) -> io::Result<u64> {
    let previous = read_progress(path)?;
    let old_time = previous
        .get("updatedAt")
        .and_then(Value::as_f64)
        .unwrap_or(0.0) as u64;
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(io::Error::other)?
        .as_millis() as u64;
    let supplied = value
        .get("updatedAt")
        .and_then(Value::as_f64)
        .map(|n| n as u64);
    if previous.is_object() && supplied.is_some_and(|n| n <= old_time) {
        return Ok(old_time);
    }
    let timestamp = supplied.unwrap_or_else(|| now.max(old_time.saturating_add(1)));
    value["updatedAt"] = json!(timestamp);
    let bytes = serde_json::to_vec(value)?;
    if bytes.len() > MAX_BODY {
        return Err(io::Error::other("Progress snapshot exceeds 2 MiB"));
    }
    let parent = path
        .parent()
        .filter(|p| !p.as_os_str().is_empty())
        .unwrap_or(Path::new("."));
    fs::DirBuilder::new()
        .recursive(true)
        .mode(0o700)
        .create(parent)?;
    let filename = path
        .file_name()
        .ok_or_else(|| io::Error::other("Progress path needs a filename"))?;
    let mut temporary_name = filename.to_os_string();
    temporary_name.push(format!(".tmp-{suffix}"));
    let temporary = parent.join(temporary_name);
    let result = (|| {
        let mut file = OpenOptions::new()
            .write(true)
            .create_new(true)
            .mode(0o600)
            .open(&temporary)?;
        file.write_all(&bytes)?;
        file.sync_all()?;
        fs::rename(&temporary, path)?;
        File::open(parent)?.sync_all()?;
        Ok(timestamp)
    })();
    if result.is_err() {
        let _ = fs::remove_file(&temporary);
    }
    result
}

fn page_id(query: Option<&str>) -> Option<String> {
    let id = query?.strip_prefix("id=")?;
    if id.len() != 36 {
        return None;
    }
    for (index, byte) in id.bytes().enumerate() {
        if [8, 13, 18, 23].contains(&index) {
            if byte != b'-' {
                return None;
            }
        } else if !byte.is_ascii_hexdigit() {
            return None;
        }
    }
    Some(id.to_owned())
}

fn read_course(path: &Path) -> io::Result<String> {
    let mut html = String::new();
    File::open(path)?
        .take(MAX_HTML + 1)
        .read_to_string(&mut html)?;
    if html.len() as u64 > MAX_HTML {
        return Err(io::Error::other("Course exceeds 8 MiB"));
    }
    Ok(html)
}

fn inject_html(mut html: String, snapshot: &Value, token: &str) -> String {
    let snapshot = snapshot
        .to_string()
        .replace('<', "\\u003c")
        .replace('\u{2028}', "\\u2028")
        .replace('\u{2029}', "\\u2029");
    let initial = format!("<script>window.__courseProgress={snapshot};window.__courseSavePath='/{token}/progress';</script>");
    let lower = html.to_ascii_lowercase();
    let position = lower
        .find("<head")
        .and_then(|start| lower[start..].find('>').map(|end| start + end + 1))
        .unwrap_or(0);
    drop(lower);
    html.insert_str(position, &initial);
    let lifecycle = format!(
        r#"<script>(()=>{{const base='/{token}/';const id=crypto.randomUUID();let stream;let removed=false;function connect(){{if(removed)return;stream?.close();stream=new EventSource(base+'live?id='+id);stream.addEventListener('uninstall',()=>{{removed=true;stream.close();dispatchEvent(new Event('course-uninstall'));}});}}connect();addEventListener('pagehide',()=>{{stream?.close();navigator.sendBeacon(base+'leave?id='+id,'');}});addEventListener('pageshow',event=>{{if(event.persisted)connect();}});}})();</script>"#
    );
    let position = html
        .to_ascii_lowercase()
        .rfind("</body>")
        .unwrap_or(html.len());
    html.insert_str(position, &lifecycle);
    html
}

struct Server {
    options: Options,
    poll: Poll,
    listener: TcpListener,
    connections: HashMap<Token, Connection>,
    next_token: usize,
    secret: String,
    origin: String,
    startup_deadline: Option<Instant>,
    idle_deadline: Option<Instant>,
    stop_deadline: Option<Instant>,
    uninstalling: bool,
    next_ping: Instant,
}

impl Server {
    fn new(options: Options) -> io::Result<Self> {
        let metadata = fs::metadata(&options.course)?;
        if !metadata.is_file() || metadata.len() > MAX_HTML {
            return Err(io::Error::other(
                "Course must be a file no larger than 8 MiB",
            ));
        }
        read_course(&options.course)?;
        read_progress(&options.progress)?;
        let mut random = [0_u8; 32];
        File::open("/dev/urandom")?.read_exact(&mut random)?;
        let secret = random.iter().map(|byte| format!("{byte:02x}")).collect();
        let poll = Poll::new()?;
        let mut listener =
            TcpListener::bind(SocketAddr::from((Ipv4Addr::LOCALHOST, options.port)))?;
        poll.registry()
            .register(&mut listener, LISTENER, Interest::READABLE)?;
        let origin = format!("http://127.0.0.1:{}", listener.local_addr()?.port());
        Ok(Self {
            options,
            poll,
            listener,
            connections: HashMap::new(),
            next_token: 1,
            secret,
            origin,
            startup_deadline: Some(Instant::now() + STARTUP_TIMEOUT),
            idle_deadline: None,
            stop_deadline: None,
            uninstalling: false,
            next_ping: Instant::now() + HEARTBEAT,
        })
    }

    fn live_count(&self) -> usize {
        self.connections
            .values()
            .filter(|c| c.page.is_some())
            .count()
    }

    fn remove(&mut self, token: Token) {
        if let Some(mut connection) = self.connections.remove(&token) {
            let _ = self.poll.registry().deregister(&mut connection.socket);
            if connection.page.is_some() && self.live_count() == 0 {
                self.idle_deadline = Some(Instant::now() + CLOSE_GRACE);
                self.startup_deadline = None;
            }
        }
    }

    fn accept(&mut self) -> io::Result<()> {
        loop {
            let (mut socket, _) = match self.listener.accept() {
                Ok(pair) => pair,
                Err(error) if error.kind() == io::ErrorKind::WouldBlock => break,
                Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
                Err(error) => return Err(error),
            };
            if self.connections.len() >= MAX_CONNECTIONS {
                continue;
            }
            let token = Token(self.next_token);
            self.next_token = self
                .next_token
                .checked_add(1)
                .ok_or_else(|| io::Error::other("Connection token space exhausted"))?;
            socket.set_nodelay(true)?;
            self.poll
                .registry()
                .register(&mut socket, token, Interest::READABLE)?;
            self.connections.insert(
                token,
                Connection {
                    socket,
                    input: Vec::new(),
                    output: Vec::new(),
                    sent: 0,
                    page: None,
                    responding: false,
                    touched: Instant::now(),
                },
            );
        }
        Ok(())
    }

    fn route(&mut self, connection: &mut Connection, request: Request) {
        let (path, query) = request
            .target
            .split_once('?')
            .map_or((request.target.as_str(), None), |(p, q)| (p, Some(q)));
        let prefix = format!("/{}/", self.secret);
        let Some(route) = path.strip_prefix(&prefix) else {
            connection.error("404 Not Found", "Not found");
            return;
        };
        if request.method == "POST" && request.origin.as_deref().is_some_and(|o| o != self.origin) {
            connection.error("403 Forbidden", "Origin is not allowed");
            return;
        }
        match (request.method.as_str(), route) {
            ("GET", "") => {
                let result = (|| -> io::Result<String> {
                    if fs::metadata(&self.options.course)?.len() > MAX_HTML {
                        return Err(io::Error::other("Course exceeds 8 MiB"));
                    }
                    let html = read_course(&self.options.course)?;
                    let snapshot = read_progress(&self.options.progress)?;
                    Ok(inject_html(html, &snapshot, &self.secret))
                })();
                match result {
                    Ok(html) => {
                        connection.response("200 OK", "text/html; charset=utf-8", html.as_bytes());
                        if self.live_count() == 0 {
                            self.startup_deadline = Some(Instant::now() + STARTUP_TIMEOUT);
                            self.idle_deadline = None;
                        }
                    }
                    Err(_) => connection.error(
                        "500 Internal Server Error",
                        "Could not read the course or saved progress",
                    ),
                }
            }
            ("GET", "live") => {
                let Some(id) = page_id(query) else {
                    connection.error("400 Bad Request", "A UUID page id is required");
                    return;
                };
                let duplicates: Vec<_> = self
                    .connections
                    .iter()
                    .filter(|(_, c)| c.page.as_deref() == Some(&id))
                    .map(|(t, _)| *t)
                    .collect();
                for token in duplicates {
                    self.remove(token);
                }
                connection.page = Some(id);
                connection.input = Vec::new();
                connection.output = SSE_INITIAL.to_vec();
                if self.uninstalling {
                    connection.output.extend_from_slice(UNINSTALL_EVENT);
                }
                connection.sent = 0;
                self.startup_deadline = None;
                self.idle_deadline = None;
            }
            ("POST", "leave") => {
                let Some(id) = page_id(query) else {
                    connection.error("400 Bad Request", "A UUID page id is required");
                    return;
                };
                let leaving: Vec<_> = self
                    .connections
                    .iter()
                    .filter(|(_, c)| c.page.as_deref() == Some(&id))
                    .map(|(t, _)| *t)
                    .collect();
                for token in leaving {
                    self.remove(token);
                }
                connection.response("204 No Content", "text/plain", b"");
            }
            ("GET", "progress") => match read_progress(&self.options.progress) {
                Ok(value) => connection.response(
                    "200 OK",
                    "application/json; charset=utf-8",
                    value.to_string().as_bytes(),
                ),
                Err(_) => {
                    connection.error("500 Internal Server Error", "Could not read saved progress")
                }
            },
            ("POST", "progress") => {
                if self.uninstalling {
                    connection.error("410 Gone", "The course is being uninstalled");
                    return;
                }
                let Ok(mut value) = serde_json::from_slice::<Value>(&request.body) else {
                    connection.error("400 Bad Request", "Malformed progress JSON");
                    return;
                };
                if let Err(message) = validate_progress(&value) {
                    connection.error("400 Bad Request", message);
                    return;
                }
                match save_progress(&self.options.progress, &mut value, &self.secret) {
                    Ok(timestamp) => connection.response(
                        "200 OK",
                        "application/json; charset=utf-8",
                        json!({"saved":true,"updatedAt":timestamp})
                            .to_string()
                            .as_bytes(),
                    ),
                    Err(_) => {
                        connection.error("500 Internal Server Error", "Could not save progress")
                    }
                }
            }
            ("POST", "shutdown") => {
                self.stop_deadline
                    .get_or_insert_with(|| Instant::now() + Duration::from_millis(200));
                connection.response(
                    "200 OK",
                    "application/json; charset=utf-8",
                    b"{\"stopping\":true}",
                );
            }
            ("POST", "uninstall") => {
                if !self.uninstalling {
                    self.uninstalling = true;
                    self.stop_deadline = Some(Instant::now() + Duration::from_secs(1));
                    self.broadcast_uninstall();
                }
                connection.response(
                    "200 OK",
                    "application/json; charset=utf-8",
                    b"{\"stopping\":true}",
                );
            }
            _ => connection.error("404 Not Found", "Not found"),
        }
    }

    fn broadcast_uninstall(&mut self) {
        let live: Vec<_> = self
            .connections
            .iter()
            .filter(|(_, connection)| connection.page.is_some())
            .map(|(token, _)| *token)
            .collect();
        for token in live {
            if let Some(connection) = self.connections.get_mut(&token) {
                connection.output.extend_from_slice(UNINSTALL_EVENT);
            }
            self.ready(token, false, true, false);
        }
    }

    fn ready(&mut self, token: Token, readable: bool, writable: bool, closed: bool) {
        let Some(mut connection) = self.connections.remove(&token) else {
            return;
        };
        let was_page = connection.page.is_some();
        let mut keep = !closed;
        if readable && keep {
            let mut chunk = [0_u8; 8192];
            loop {
                match connection.socket.read(&mut chunk) {
                    Ok(0) => {
                        keep = false;
                        break;
                    }
                    Ok(count) => {
                        connection.touched = Instant::now();
                        if connection.page.is_some() || connection.responding {
                            keep = false;
                            break;
                        }
                        connection.input.extend_from_slice(&chunk[..count]);
                        match parse_request(&connection.input) {
                            Parsed::Pending => {}
                            Parsed::Error(status, message) => {
                                connection.error(status, message);
                                break;
                            }
                            Parsed::Complete(request) => {
                                self.route(&mut connection, request);
                                break;
                            }
                        }
                    }
                    Err(error) if error.kind() == io::ErrorKind::WouldBlock => break,
                    Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
                    Err(_) => {
                        keep = false;
                        break;
                    }
                }
            }
        }
        if keep && (writable || !connection.output.is_empty()) {
            while connection.sent < connection.output.len() {
                match connection
                    .socket
                    .write(&connection.output[connection.sent..])
                {
                    Ok(0) => {
                        keep = false;
                        break;
                    }
                    Ok(count) => {
                        connection.sent += count;
                        connection.touched = Instant::now();
                    }
                    Err(error) if error.kind() == io::ErrorKind::WouldBlock => break,
                    Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
                    Err(_) => {
                        keep = false;
                        break;
                    }
                }
            }
            if connection.sent == connection.output.len() {
                connection.output = Vec::new();
                connection.sent = 0;
                if connection.responding {
                    keep = false;
                }
            }
        }
        let buffered = self
            .connections
            .values()
            .map(Connection::buffered)
            .sum::<usize>()
            + connection.buffered();
        if buffered > MAX_BUFFERED {
            keep = false;
        }
        if keep {
            let interest = if connection.output.is_empty() {
                Interest::READABLE
            } else {
                Interest::READABLE | Interest::WRITABLE
            };
            if self
                .poll
                .registry()
                .reregister(&mut connection.socket, token, interest)
                .is_ok()
            {
                self.connections.insert(token, connection);
                return;
            }
        }
        let _ = self.poll.registry().deregister(&mut connection.socket);
        if (was_page || connection.page.is_some()) && self.live_count() == 0 {
            self.idle_deadline = Some(Instant::now() + CLOSE_GRACE);
            self.startup_deadline = None;
        }
    }

    fn timers(&mut self) -> bool {
        let now = Instant::now();
        let stale: Vec<_> = self
            .connections
            .iter()
            .filter(|(_, c)| {
                (c.page.is_none() || !c.output.is_empty())
                    && now.duration_since(c.touched) >= REQUEST_TIMEOUT
            })
            .map(|(token, _)| *token)
            .collect();
        for token in stale {
            self.remove(token);
        }
        if now >= self.next_ping {
            let live: Vec<_> = self
                .connections
                .iter()
                .filter(|(_, c)| c.page.is_some())
                .map(|(t, _)| *t)
                .collect();
            for token in live {
                if let Some(connection) = self.connections.get_mut(&token) {
                    if connection.output.is_empty() {
                        connection.output = b": keep-alive\n\n".to_vec();
                        connection.sent = 0;
                    }
                }
                self.ready(token, false, true, false);
            }
            self.next_ping = now + HEARTBEAT;
        }
        if let Some(deadline) = self.stop_deadline {
            now >= deadline
        } else {
            self.startup_deadline.is_some_and(|d| now >= d)
                || self.idle_deadline.is_some_and(|d| now >= d)
        }
    }

    fn timeout(&self) -> Duration {
        let mut deadline = self.next_ping;
        let lifecycle_deadlines = if self.stop_deadline.is_some() {
            [self.stop_deadline, None]
        } else {
            [self.startup_deadline, self.idle_deadline]
        };
        for value in lifecycle_deadlines.into_iter().flatten() {
            deadline = deadline.min(value);
        }
        for connection in self.connections.values() {
            if connection.page.is_none() || !connection.output.is_empty() {
                deadline = deadline.min(connection.touched + REQUEST_TIMEOUT);
            }
        }
        deadline.saturating_duration_since(Instant::now())
    }

    fn run(&mut self) -> io::Result<()> {
        println!("{}/{}/", self.origin, self.secret);
        io::stdout().flush()?;
        let mut events = Events::with_capacity(256);
        loop {
            match self.poll.poll(&mut events, Some(self.timeout())) {
                Ok(()) => {}
                Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
                Err(error) => return Err(error),
            }
            for event in &events {
                if event.token() == LISTENER {
                    self.accept()?;
                } else {
                    self.ready(
                        event.token(),
                        event.is_readable(),
                        event.is_writable(),
                        event.is_error(),
                    );
                }
            }
            if self.timers() {
                return Ok(());
            }
        }
    }
}

fn main() {
    let result = Options::parse()
        .map_err(io::Error::other)
        .and_then(Server::new)
        .and_then(|mut server| server.run());
    if let Err(error) = result {
        eprintln!("TLA+ course server: {error}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn body_must_be_complete_before_parsing() {
        let header = b"POST /x/progress HTTP/1.1\r\nContent-Length: 2\r\n\r\n";
        assert!(matches!(parse_request(header), Parsed::Pending));
        let mut bytes = header.to_vec();
        bytes.push(b'{');
        assert!(matches!(parse_request(&bytes), Parsed::Pending));
        bytes.push(b'}');
        assert!(
            matches!(parse_request(&bytes),Parsed::Complete(Request { body, .. }) if body == b"{}")
        );
    }

    #[test]
    fn parser_rejects_ambiguous_framing_and_limits() {
        for bytes in [
            b"POST / HTTP/1.1\r\nContent-Length: 1\r\nContent-Length: 1\r\n\r\nx".as_slice(),
            b"POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n".as_slice(),
            b"POST / HTTP/1.1\r\nContent-Length: -1\r\n\r\n".as_slice(),
        ] {
            assert!(matches!(
                parse_request(bytes),
                Parsed::Error("400 Bad Request", _)
            ));
        }
        assert!(matches!(
            parse_request(b"POST / HTTP/1.1\r\nContent-Length: 2097153\r\n\r\n"),
            Parsed::Error("413 Payload Too Large", _)
        ));
        assert!(matches!(
            parse_request(&vec![b'x'; MAX_HEADER]),
            Parsed::Error("431 Request Header Fields Too Large", _)
        ));
    }

    #[test]
    fn schema_preserves_false_and_validates_fraction() {
        assert!(validate_progress(&json!({"done":{"counter":false},"reading":{"counter":0.25},"answers":{"logic-1":"0"},"notes":{"counter":"hello"},"current":"counter","theme":"dark","updatedAt":1234})).is_ok());
        for value in [
            json!({"reading":{"x":1.01}}),
            json!({"notes":{"x":false}}),
            json!({"done":{"x":1}}),
            json!({"unknown":{}}),
            json!({"current":"../x"}),
        ] {
            assert!(validate_progress(&value).is_err());
        }
    }

    #[test]
    fn injection_precedes_existing_scripts_and_escapes_closing_tags() {
        let result = inject_html(
            "<!doctype html><HEAD><script>original()</script></HEAD><body></body>".into(),
            &json!({"notes":{"x":"</script><script>attack()</script>"}}),
            "secret",
        );
        assert!(
            result.find("window.__courseProgress").unwrap() < result.find("original()").unwrap()
        );
        assert!(result.contains("\\u003c/script>"));
        assert!(!result.contains("<script>attack()"));
        assert!(result.contains("EventSource"));
    }

    #[test]
    fn uuid_query_is_bounded() {
        assert!(page_id(Some("id=12345678-1234-1234-1234-123456789abc")).is_some());
        assert!(page_id(Some("id=not-a-uuid")).is_none());
        assert!(page_id(Some("id=12345678-1234-1234-1234-123456789abc&x=1")).is_none());
    }

    #[test]
    fn atomic_snapshot_preserves_false_and_ignores_older_beacons() {
        use std::os::unix::fs::PermissionsExt;
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let directory =
            env::temp_dir().join(format!("tla-server-test-{}-{nonce}", std::process::id()));
        let path = directory.join("progress.json");
        let mut value = json!({"done":{"counter":true},"updatedAt":100});
        assert_eq!(save_progress(&path, &mut value, "test").unwrap(), 100);
        let mut stale = json!({"done":{"counter":false},"updatedAt":99});
        assert_eq!(save_progress(&path, &mut stale, "test").unwrap(), 100);
        assert_eq!(read_progress(&path).unwrap()["done"]["counter"], true);
        let mut newer = json!({"done":{"counter":false},"updatedAt":101});
        assert_eq!(save_progress(&path, &mut newer, "test").unwrap(), 101);
        assert_eq!(read_progress(&path).unwrap(), newer);
        assert_eq!(
            fs::metadata(&path).unwrap().permissions().mode() & 0o777,
            0o600
        );
        assert_eq!(
            fs::metadata(&directory).unwrap().permissions().mode() & 0o777,
            0o700
        );
        fs::write(&path, b"malformed").unwrap();
        assert!(save_progress(&path, &mut newer, "test").is_err());
        assert_eq!(fs::read(&path).unwrap(), b"malformed");
        fs::remove_dir_all(directory).unwrap();
    }

    #[test]
    fn authenticated_controls_override_idle_timers_without_deleting_data() {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let directory =
            env::temp_dir().join(format!("tla-controls-test-{}-{nonce}", std::process::id()));
        fs::create_dir_all(&directory).unwrap();
        let course = directory.join("course.html");
        let progress = directory.join("progress.json");
        fs::write(&course, b"<html><head></head><body>test</body></html>").unwrap();
        fs::write(&progress, b"{}").unwrap();
        let mut server = Server::new(Options {
            course,
            progress: progress.clone(),
            port: 0,
        })
        .unwrap();
        let peer = std::net::TcpStream::connect(server.listener.local_addr().unwrap()).unwrap();
        server.accept().unwrap();
        let token = *server.connections.keys().next().unwrap();
        let mut connection = server.connections.remove(&token).unwrap();
        let request = |target: String, origin| Request {
            method: "POST".into(),
            target,
            origin,
            body: Vec::new(),
        };
        server.route(&mut connection, request("/wrong/uninstall".into(), None));
        assert!(!server.uninstalling);
        assert!(connection.output.starts_with(b"HTTP/1.1 404"));
        let path = format!("/{}/uninstall", server.secret);
        server.route(
            &mut connection,
            request(path.clone(), Some("https://example.com".into())),
        );
        assert!(!server.uninstalling);
        assert!(connection.output.starts_with(b"HTTP/1.1 403"));
        server.route(&mut connection, request(path.clone(), None));
        assert!(server.uninstalling);
        assert!(connection.output.starts_with(b"HTTP/1.1 200"));
        let stop = server.stop_deadline;
        server.route(&mut connection, request(path, None));
        assert_eq!(server.stop_deadline, stop);
        server.route(
            &mut connection,
            request(format!("/{}/progress", server.secret), None),
        );
        assert!(connection.output.starts_with(b"HTTP/1.1 410"));
        server.startup_deadline = Some(Instant::now());
        server.idle_deadline = Some(Instant::now());
        assert!(!server.timers());
        server.stop_deadline = Some(Instant::now());
        assert!(server.timers());
        assert_eq!(fs::read(progress).unwrap(), b"{}");
        drop(connection);
        drop(peer);
        drop(server);
        fs::remove_dir_all(directory).unwrap();
    }
}
