use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{self, BufRead, BufReader, Read, Seek, SeekFrom, Write};
use std::net::{SocketAddr, TcpStream};
use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{self, Child, Command, Stdio};
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const ORIGIN: &str = "http://127.0.0.1:49731/";
const MAX_URL_BYTES: usize = 256;
const READY_TIMEOUT: Duration = Duration::from_secs(10);
const PROBE_TIMEOUT: Duration = Duration::from_secs(1);

fn main() {
    let no_browser = env::args_os().skip(1).any(|arg| arg == "--no-browser");
    if let Err(message) = run() {
        eprintln!("TLA+ Course: {message}");
        if !no_browser {
            show_error(&message);
        }
        process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let args: Vec<_> = env::args_os().skip(1).collect();
    let no_browser =
        match args.as_slice() {
            [] => false,
            [arg] if arg == "--no-browser" => true,
            _ => return Err(
                "Launch the app normally, or use --no-browser for a direct local-server session."
                    .into(),
            ),
        };
    let executable =
        env::current_exe().map_err(|error| format!("Cannot locate the installed app: {error}"))?;
    let macos = executable
        .parent()
        .ok_or("Cannot locate the app's MacOS folder.")?;
    let contents = macos
        .parent()
        .ok_or("Cannot locate the app's Contents folder.")?;
    let course = contents.join("Resources/course.html");
    let server = macos.join("course-server");
    if !course.is_file() || !server.is_file() {
        return Err("The installed app is incomplete. Rebuild it with mac-app/build.sh to restore the bundled course and server.".into());
    }
    let data = data_directory()?;
    fs::create_dir_all(&data).map_err(|error| {
        format!(
            "Cannot create the course data folder {}: {error}",
            data.display()
        )
    })?;
    fs::set_permissions(&data, fs::Permissions::from_mode(0o700)).map_err(|error| {
        format!(
            "Cannot secure the course data folder {}: {error}",
            data.display()
        )
    })?;
    let progress = data.join("progress.json");
    let runtime = data.join("server-url");

    if no_browser {
        let error = server_command(&server, &course, &progress).exec();
        return Err(format!("Cannot start the bundled course server: {error}"));
    }

    if let Some(url) = reusable_url(&runtime) {
        return open_browser(&url);
    }

    let log = data.join("server-error.log");
    let stderr = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .mode(0o600)
        .open(&log)
        .map_err(|error| format!("Cannot create the server error log: {error}"))?;
    stderr
        .set_permissions(fs::Permissions::from_mode(0o600))
        .map_err(|error| format!("Cannot secure the server error log: {error}"))?;
    let mut child = server_command(&server, &course, &progress)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::from(stderr))
        .spawn()
        .map_err(|error| format!("Cannot start the bundled course server: {error}"))?;
    let ready = wait_for_ready(&mut child);
    let url = match ready {
        Ok(url) if probe(&url) => url,
        Ok(_) => {
            stop_child(&mut child);
            return Err(launch_error(
                "The local server announced readiness but did not answer its progress endpoint.",
                &log,
            ));
        }
        Err(reason) => {
            stop_child(&mut child);
            return Err(launch_error(&reason, &log));
        }
    };
    if let Err(error) = atomic_write_url(&runtime, &url) {
        stop_child(&mut child);
        return Err(format!("Cannot save the local server address: {error}"));
    }
    if let Err(error) = open_browser(&url) {
        stop_child(&mut child);
        let _ = fs::remove_file(&runtime);
        return Err(error);
    }
    // Dropping Child does not stop the service. It is reparented after this
    // short-lived launcher exits and follows the browser-tab lifecycle itself.
    Ok(())
}

fn server_command(server: &Path, course: &Path, progress: &Path) -> Command {
    let mut command = Command::new(server);
    command
        .arg("--course")
        .arg(course)
        .arg("--progress")
        .arg(progress);
    command
}

fn data_directory() -> Result<PathBuf, String> {
    if let Some(path) = env::var_os("TLA_COURSE_DATA_DIR") {
        if path.is_empty() {
            return Err("TLA_COURSE_DATA_DIR is empty. Set it to a data-folder path or remove the variable.".into());
        }
        return Ok(PathBuf::from(path));
    }
    let home = env::var_os("HOME")
        .ok_or("Cannot locate your home folder. Set TLA_COURSE_DATA_DIR to a writable folder.")?;
    Ok(PathBuf::from(home).join("Library/Application Support/TLA+ Course"))
}

fn valid_url(value: &str) -> Option<&str> {
    if value.len() > MAX_URL_BYTES || !value.is_ascii() {
        return None;
    }
    let token = value.strip_prefix(ORIGIN)?.strip_suffix('/')?;
    if token.is_empty()
        || !token
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_')
    {
        return None;
    }
    Some(value)
}

fn reusable_url(path: &Path) -> Option<String> {
    let mut contents = String::new();
    File::open(path)
        .ok()?
        .take((MAX_URL_BYTES + 2) as u64)
        .read_to_string(&mut contents)
        .ok()?;
    let url = contents.strip_suffix('\n').unwrap_or(&contents);
    let url = valid_url(url)?;
    probe(url).then(|| url.to_owned())
}

fn probe(url: &str) -> bool {
    let Some(valid) = valid_url(url) else {
        return false;
    };
    let address: SocketAddr = "127.0.0.1:49731".parse().expect("fixed loopback address");
    let Ok(mut stream) = TcpStream::connect_timeout(&address, PROBE_TIMEOUT) else {
        return false;
    };
    if stream.set_read_timeout(Some(PROBE_TIMEOUT)).is_err()
        || stream.set_write_timeout(Some(PROBE_TIMEOUT)).is_err()
    {
        return false;
    }
    let path = &valid["http://127.0.0.1:49731".len()..];
    let request = format!(
        "GET {path}progress HTTP/1.1\r\nHost: 127.0.0.1:49731\r\nConnection: close\r\n\r\n"
    );
    if stream.write_all(request.as_bytes()).is_err() {
        return false;
    }
    let mut line = String::new();
    if BufReader::new(stream)
        .take(512)
        .read_line(&mut line)
        .is_err()
    {
        return false;
    }
    let mut fields = line.split_whitespace();
    matches!(fields.next(), Some("HTTP/1.1" | "HTTP/1.0")) && fields.next() == Some("200")
}

fn wait_for_ready(child: &mut Child) -> Result<String, String> {
    let stdout = child
        .stdout
        .take()
        .ok_or("The server did not provide a readiness pipe.")?;
    let (sender, receiver) = mpsc::sync_channel(1);
    let reader = thread::spawn(move || {
        let mut line = String::new();
        let result = BufReader::new(stdout)
            .take((MAX_URL_BYTES + 2) as u64)
            .read_line(&mut line);
        let _ = sender.send(result.map(|_| line));
    });
    let result = match receiver.recv_timeout(READY_TIMEOUT) {
        Ok(Ok(line)) => {
            let url = line.trim_end_matches(['\r', '\n']);
            valid_url(url)
                .map(str::to_owned)
                .ok_or_else(|| "The server returned an invalid local address.".to_owned())
        }
        Ok(Err(error)) => Err(format!("Cannot read the local server address: {error}")),
        Err(mpsc::RecvTimeoutError::Timeout) => {
            Err("The local server did not become ready within 10 seconds.".into())
        }
        Err(mpsc::RecvTimeoutError::Disconnected) => {
            Err("The local server stopped before announcing its address.".into())
        }
    };
    if result.is_err() {
        stop_child(child);
    }
    let _ = reader.join();
    result
}

fn atomic_write_url(path: &Path, url: &str) -> io::Result<()> {
    let stamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    let temporary = path.with_file_name(format!(".server-url-{}-{stamp}", process::id()));
    let result = (|| {
        let mut file = OpenOptions::new()
            .write(true)
            .create_new(true)
            .mode(0o600)
            .open(&temporary)?;
        writeln!(file, "{url}")?;
        file.sync_all()?;
        fs::rename(&temporary, path)
    })();
    if result.is_err() {
        let _ = fs::remove_file(temporary);
    }
    result
}

fn stop_child(child: &mut Child) {
    let _ = child.kill();
    let _ = child.wait();
}

fn launch_error(reason: &str, log: &Path) -> String {
    let mut message = format!("{reason}\n\nClose any other program using 127.0.0.1:49731, then reopen TLA+ Course. Your saved progress is not removed.");
    if let Ok(mut file) = File::open(log) {
        if let Ok(length) = file.metadata().map(|metadata| metadata.len()) {
            let _ = file.seek(SeekFrom::Start(length.saturating_sub(4096)));
        }
        let mut bytes = Vec::new();
        if file.take(4096).read_to_end(&mut bytes).is_ok() && !bytes.is_empty() {
            message.push_str("\n\nServer details:\n");
            message.push_str(String::from_utf8_lossy(&bytes).trim());
        }
    }
    message
}

fn open_browser(url: &str) -> Result<(), String> {
    let status = Command::new("/usr/bin/open").arg(url).stdin(Stdio::null()).stdout(Stdio::null()).stderr(Stdio::null())
        .status().map_err(|error| format!("Cannot open your default browser: {error}. Set a default browser in System Settings and reopen the course."))?;
    if status.success() {
        Ok(())
    } else {
        Err("macOS could not open your default browser. Set a default browser in System Settings and reopen the course.".into())
    }
}

fn show_error(message: &str) {
    let script = "on run argv\n display alert \"TLA+ Course could not open\" message (item 1 of argv) as critical buttons {\"OK\"} default button \"OK\"\nend run";
    let _ = Command::new("/usr/bin/osascript")
        .arg("-e")
        .arg(script)
        .arg(message)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

#[cfg(test)]
mod tests {
    use super::valid_url;

    #[test]
    fn accepts_only_tokenized_fixed_origin_urls() {
        assert!(valid_url("http://127.0.0.1:49731/abc-123_DEF/").is_some());
        for url in [
            "http://127.0.0.1:49731/",
            "http://localhost:49731/abc/",
            "https://127.0.0.1:49731/abc/",
            "http://127.0.0.1:49732/abc/",
            "http://127.0.0.1:49731/a/b/",
            "http://127.0.0.1:49731/../",
            "http://127.0.0.1:49731/abc/?x=1",
            "http://127.0.0.1:49731/abc/\n",
        ] {
            assert!(valid_url(url).is_none(), "accepted {url:?}");
        }
        assert!(valid_url(&format!("http://127.0.0.1:49731/{}/", "a".repeat(256))).is_none());
    }
}
