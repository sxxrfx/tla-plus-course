TLA+ Course is a macOS launcher for the bundled offline course. Lessons work offline; the embedded lecture videos stream from YouTube and need internet.

Run `./mac-app/build.sh` from the course directory to build, install in `~/Applications/TLA+ Course.app`, and register the app with Launch Services and Spotlight. You can pass another `.app` installation path as its first argument. The script replaces an existing target only when its bundle identifier is `local.tla.course`.

Building requires Rust/Cargo and Apple's command-line developer tools. Cargo uses the checked-in dependency lockfile; Swift builds the menu-bar app and draws the icon. The installed app runs without Rust, Cargo, Swift tooling, Python, Node, a package manager, or an internet connection.

Launch **TLA+ Course** from Spotlight. A **TLA+** item appears in the menu bar and stays there until you choose **Quit TLA+ Course**, including after the last course tab closes; opening the app again brings it back. Its menu has **Open Course**, **Uninstall…** and **Quit TLA+ Course**. Each open runs the small Rust launcher, which opens your default browser and exits. A separate Rust service serves the bundled page at `127.0.0.1:49731`. Opening again reuses a responding service after validating its tokenized address and probing its progress endpoint.

**Uninstall…** lists what it will remove and asks for confirmation. It stops the service, then moves the app, the data folder and (unless you untick them) the source files recorded in `Contents/Resources/uninstall-files.json` to the Trash. If a move fails, earlier moves are restored. Course tabs that are open clear their browser-saved copy of your progress; a browser with no open course tab keeps its copy until you clear that browser's data for `127.0.0.1:49731`.

Each course tab holds an event-stream connection. Closing the last course tab stops the service after a five-second grace period; refreshes and reconnections within that interval keep it running. If a browser never connects, the service stops after 90 seconds. Background tabs may keep their connection open, so closing a browser window is not equivalent to closing every course tab in every browser.

Progress is stored in `~/Library/Application Support/TLA+ Course/progress.json`, independently of browser storage. The data folder also contains the current tokenized address in `server-url` and a startup error log in `server-error.log`. The folder is private to your user, and the launcher writes the address and error-log files with mode `0600`. Rebuilding or replacing the app preserves this folder. You can override its location with `TLA_COURSE_DATA_DIR` for isolated testing.

The service listens only on this Mac's loopback interface. A per-run token scopes course and progress endpoints. If an unrelated process owns the fixed port, startup fails with a native alert instead of choosing another port. The app is locally ad-hoc signed, not an App Store or notarized distribution build.

`MenuBar.swift` and `Uninstall.swift` are the menu-bar app. `launcher.rs` starts or reuses the service and opens the browser. `server/` contains the standalone service. `Icon.swift` draws the app icon, and `UninstallManifest.swift` records the source files at build time. `build.sh` copies the latest `tla-plus-course.html` into the app before signing it; rebuild after editing the course.

For a direct server session without opening a browser:

```sh
TLA_COURSE_DATA_DIR="$(mktemp -d)" "$HOME/Applications/TLA+ Course.app/Contents/MacOS/course-launcher" --no-browser
```

This replaces the launcher process with the bundled service and prints its ready URL to standard output. It follows the same last-tab shutdown behavior and does not reuse another running service. For launcher checks, compile `launcher.rs` with `rustc --edition=2021 --test` and run the resulting temporary test binary.
