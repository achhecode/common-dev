# BrowserPilot Debug Browser Manager

`browser.sh` is a single-file Bash utility that starts, stops, monitors and resets a **dedicated, isolated Chromium-based browser profile** with the Chrome DevTools Protocol (CDP) enabled. It is built for local development and browser automation, for example attaching Playwright or Puppeteer to a debugging browser without touching your everyday profile.

| | |
|---|---|
| **Version** | 2.0.0 |
| **Platform** | macOS (Bash 3.2+). Other Unix-like systems work with an explicit `BROWSER_PATH`. |
| **Browsers** | Brave, Google Chrome, Microsoft Edge, Chromium (any Chromium-based browser with CDP) |
| **Dependencies** | `curl`, `ps`, `kill`, `nohup` (all preinstalled on macOS). `lsof` is used if present. |

> **Security warning.** CDP gives full control of the browser, including open pages and signed-in sessions. The manager binds the endpoint to `127.0.0.1` and refuses extra arguments that would change this. Never expose the port to a network. See [Security](#security).

---

## Contents

1. [Quick start](#quick-start)
2. [Installation](#installation)
3. [Commands](#commands)
4. [Configuration](#configuration)
5. [Exit codes](#exit-codes)
6. [Usage guides](#usage-guides)
7. [Architecture](#architecture)
8. [Security](#security)
9. [Troubleshooting](#troubleshooting)
10. [Development](#development)
11. [Migrating from 1.x](#migrating-from-1x)

---

## Quick start

```sh
chmod +x browser.sh
./browser.sh start      # launch Brave with CDP on http://127.0.0.1:9222
./browser.sh status     # verify
./browser.sh stop       # shut down
```

Verify the endpoint manually:

```sh
curl --max-time 2 http://127.0.0.1:9222/json/version
```

A healthy instance returns JSON that includes the browser version and a `webSocketDebuggerUrl`.

## Installation

1. Copy `browser.sh` into your project root.
2. Make it executable: `chmod +x browser.sh`.
3. Ignore the runtime directory in version control. It contains cookies and session data:

   ```gitignore
   testing-browser/
   ```

The script creates the following layout beside itself on first `start`:

```text
your-project/
├── browser.sh
└── testing-browser/
    ├── browser-data/
    │   └── <browser>-<profile>/     # Dedicated profile
    └── runtime/
        ├── <browser>-<profile>.pid  # Saved process ID
        ├── <browser>-<profile>.log  # Browser stdout/stderr
        └── <browser>-<profile>.log.1  # Previous log (after rotation)
```

Nothing is created by `--help`, `status`, or other read-only commands.

---

## Commands

```text
browser.sh [options] <command>
```

| Command | Description |
|---|---|
| `start` | Launch the browser and wait until CDP responds. Idempotent: reports the running instance if one exists. |
| `stop` | Send `SIGTERM`, wait up to `STOP_TIMEOUT` seconds, then re-verify the process and send `SIGKILL` if needed. |
| `restart` | `stop`, then `start`. |
| `status` | Show state, PID, CDP health, profile and log paths. Exits `3` if not running. |
| `url` | Print only the CDP URL. Intended for scripting, e.g. `$(./browser.sh url)`. |
| `logs [N]` | Print the last `N` log lines (default `100`). |
| `log-tail` | Follow the log. `Ctrl+C` stops following, not the browser. |
| `reset` | Permanently delete the dedicated profile after confirmation. |

### Options

| Option | Description |
|---|---|
| `-b, --browser NAME` | Browser label: `brave`, `chrome`, `edge`, `chromium`, or a custom label. |
| `--browser-path PATH` | Absolute path to the browser executable. |
| `-p, --profile NAME` | Profile name. |
| `-P, --port PORT` | Local CDP port. |
| `--headless` | Run without a visible window (`--headless=new`). |
| `-y, --yes` | Skip the `reset` confirmation prompt. |
| `-h, --help` | Show help. |
| `-V, --version` | Show version. |

Options and their equivalent environment variables are interchangeable; command-line options take precedence.

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `BROWSER_NAME` | `brave` | Label used in profile, PID and log names. Also selects the default executable path. |
| `BROWSER_PATH` | *auto, by name* | Absolute path to the executable. Required for browsers without a built-in default. |
| `PROFILE_NAME` | `ar` | Profile identifier. Each name gets its own profile, PID file and log file. |
| `PORT` | `9222` | Local CDP port (1–65535). Must be free. |
| `START_TIMEOUT` | `15` | Seconds to wait for CDP readiness. |
| `STOP_TIMEOUT` | `10` | Seconds to wait for graceful shutdown before `SIGKILL`. |
| `MAX_LOG_BYTES` | `5242880` | Rotate the log to `.log.1` at startup if larger than this (5 MiB). |
| `HEADLESS` | `0` | Set to `1` to run headless. |
| `BROWSER_EXTRA_ARGS` | *empty* | Extra browser flags, space-separated. Cannot override the CDP port, address or profile. |
| `BROWSER_ROOT` | `<script dir>/testing-browser` | Base directory for profiles and runtime files. |
| `NO_COLOR` | *unset* | Disable coloured output. |

`BRAVE_PATH` from version 1.x is still accepted as an alias of `BROWSER_PATH`.

**Input validation.** `BROWSER_NAME` and `PROFILE_NAME` must start with a letter or digit and contain only letters, digits, `.`, `_` and `-`. This prevents path traversal in the profile path that `reset` deletes.

### Built-in browser paths

| `--browser` | Default executable |
|---|---|
| `brave` | `/Applications/Brave Browser.app/Contents/MacOS/Brave Browser` |
| `chrome` | `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` |
| `edge` | `/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge` |
| `chromium` | `/Applications/Chromium.app/Contents/MacOS/Chromium` |

Any other label requires `--browser-path`.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | General failure (for example, the browser exited during startup) |
| `2` | Invalid command line or configuration |
| `3` | `status`: the instance is not running |
| `4` | Browser executable not found or not executable |
| `5` | CDP port already in use |
| `6` | CDP did not become ready within `START_TIMEOUT` (the browser is terminated) |

Example use in CI:

```sh
./browser.sh start || { echo "browser failed (exit $?)"; exit 1; }
```

---

## Usage guides

### Choose a different browser

```sh
./browser.sh --browser chrome --profile automation --port 9223 start
./browser.sh --browser edge   --profile automation --port 9224 start
./browser.sh --browser chromium --browser-path "/path/to/Chromium.app/Contents/MacOS/Chromium" start
```

Use the **same** `--browser`, `--profile` and `--port` for every follow-up command (`status`, `stop`, `restart`, `reset`), because they identify the instance.

Firefox and Safari do not use the Chromium CDP launch workflow and are not supported.

### Run multiple independent instances

Give each instance a unique profile **and** a unique port:

```sh
./browser.sh start                              # brave-ar   on 9222
./browser.sh -p dev -P 9333 start               # brave-dev  on 9333
./browser.sh -b chrome -p qa -P 9444 start      # chrome-qa  on 9444

./browser.sh -p dev -P 9333 stop
```

PID and log files are keyed by browser and profile, not by port. Never run two instances with the same browser and profile name at the same time.

### Run headless (CI)

```sh
./browser.sh --headless --port 9222 start
```

### Attach Playwright

```javascript
import { chromium } from "playwright";

const browser = await chromium.connectOverCDP("http://127.0.0.1:9222");
const context = browser.contexts()[0];
const page = context.pages()[0] ?? (await context.newPage());
await page.goto("https://example.com");
```

Use the port configured for the instance. `connectOverCDP` is Chromium-specific; check your Playwright version's documentation for compatibility.

### Attach Puppeteer

```javascript
import puppeteer from "puppeteer-core";

const browser = await puppeteer.connect({ browserURL: "http://127.0.0.1:9222" });
```

### Reset a profile

```sh
./browser.sh stop
./browser.sh reset          # interactive confirmation
./browser.sh --yes reset    # non-interactive (CI/scripts)
```

`reset` deletes only the selected dedicated profile. It refuses to run if the instance is running or if anything is answering on the CDP port.

---

## Architecture

1. **Location-independent.** All paths derive from the script's own directory, so it can be invoked from any working directory.
2. **Lazy side effects.** Directories are created only by `start`. Help and read-only commands touch nothing.
3. **Validated configuration.** Names, ports, timeouts and flags are checked before any action is taken.
4. **Process identity verification.** `is_running` requires the saved PID to be alive *and* its command line to contain this instance's `--user-data-dir=<profile>`. This prevents signalling an unrelated process after PID reuse.
5. **Port pre-check.** Startup aborts with exit `5` if the port is already listening (`lsof`, falling back to `/dev/tcp`).
6. **Direct launch.** The executable is started with `nohup` so `$!` is the browser's own PID, with output appended to the log.
7. **Readiness polling.** `/json/version` is polled every 250 ms until CDP responds, the process exits, or `START_TIMEOUT` elapses. On timeout the launched browser is terminated and the PID file removed, so no half-started instance is left behind.
8. **Conservative shutdown.** `SIGTERM`, a bounded wait, then re-verification of identity before any `SIGKILL`.
9. **Single-generation log rotation.** At startup, a log larger than `MAX_LOG_BYTES` is moved to `.log.1`.
10. **Guarded deletion.** `reset` verifies the target is inside `<BROWSER_ROOT>/browser-data/` and requires confirmation or `--yes`. Without a TTY and without `--yes` it refuses.

Launch flags (fixed by the script):

```text
--remote-debugging-port=<PORT>
--remote-debugging-address=127.0.0.1
--user-data-dir=<dedicated profile>
--no-first-run
--no-default-browser-check
```

Recent Chrome versions ignore remote debugging when the default profile directory is used. The mandatory dedicated `--user-data-dir` is what makes CDP work reliably.

---

## Security

- **Keep CDP local.** The endpoint is bound to `127.0.0.1`. Do not tunnel or forward it. `BROWSER_EXTRA_ARGS` is rejected if it tries to change the port, address or profile.
- **Treat profile data as secret.** Cookies and signed-in sessions can grant access to personal or work accounts. Keep `testing-browser/` out of Git, shared drives and backups.
- **Use test accounts.** Avoid automating production or privileged accounts in a debug browser.
- **Never use broad kill commands.** Avoid `pkill -f "Brave Browser"`; it can terminate your normal browsing session. `stop` signals only the verified process.
- **Know what `reset` does.** It permanently deletes the selected dedicated profile. It never touches your regular browser profile.
- **No separate quit of your everyday browser is needed.** The manager uses its own `--user-data-dir` and launches the executable directly, so it runs alongside your normal browser.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Browser executable not found` (exit 4) | Point at the executable, not the `.app` bundle: `--browser-path "/Applications/X.app/Contents/MacOS/X"`. Check with `ls -l`. |
| `No default path for browser '<name>'` (exit 2) | Custom label: supply `--browser-path`. |
| `Port N is already in use` (exit 5) | Identify the listener: `lsof -nP -iTCP:N -sTCP:LISTEN`. Stop it or choose another `--port`. Do not kill it before identifying it; it may be another automation session. |
| `CDP not ready after Ns` (exit 6) | Check `./browser.sh logs 100`. Typical causes: unsupported flag, wrong executable, crash on startup, profile locked by another process. Raise `START_TIMEOUT` on slow machines. |
| `status` says STOPPED but the browser is open | The PID file is stale, the browser was started another way, or `--browser`/`--profile` differ from the original start. Inspect: `ps -p "$(cat testing-browser/runtime/<browser>-<profile>.pid)" -o pid=,command=`. |
| `WARNING: CDP responds ... not owned by this instance` | Another process holds the port. Find it with `lsof` and stop it deliberately. |
| `reset` refuses to run | The instance is running, or CDP answers on the port. Stop the owner, confirm the endpoint is silent, retry. |
| `reset` fails with "Not an interactive terminal" | Add `--yes` when running from scripts or CI. |
| Two browsers fight over a profile | Chromium browsers do not allow concurrent use of one profile. Never point the manager at your everyday browser data directory. |

---

## Development

Validate changes before committing:

```sh
bash -n browser.sh          # syntax check
shellcheck -s bash browser.sh   # static analysis (install via: brew install shellcheck)
```

Recommended checks after editing:

1. `./browser.sh start` and `./browser.sh status`.
2. `curl http://127.0.0.1:<PORT>/json/version` returns browser metadata.
3. `./browser.sh stop`, then `./browser.sh status` exits `3`.
4. `./browser.sh logs 100` shows no errors.

Conventions: Bash 3.2-compatible (no associative arrays, `mapfile`, or `${var,,}`), `set -euo pipefail`, all variables quoted, functions prefixed `cmd_` for commands, and `die <code> <message>` for fatal errors.

---

## Migrating from 1.x

| Change | Action required |
|---|---|
| Script is now genuinely browser-neutral (`BROWSER_NAME`, `BROWSER_PATH`). | None for Brave. `BRAVE_PATH` still works. Default profile `brave-ar` is unchanged. |
| New CLI options (`-b`, `-p`, `-P`, `--headless`, `-y`). | Optional. Environment variables behave as before. |
| `shell` command removed. | It did not manage the browser; use your own terminal. |
| `url` command and `STOP_TIMEOUT`, `HEADLESS`, `BROWSER_EXTRA_ARGS`, `BROWSER_ROOT` added. | Optional. |
| `start` now terminates the browser if CDP never becomes ready. | Previously a half-started browser was left running. |
| `reset` no longer recreates the empty profile; the next `start` does. | None. |
| `reset` requires `--yes` without a TTY. | Add `--yes` in scripts. |
| Names are validated; distinct exit codes (see above). | Update any script that parsed exit codes. |
