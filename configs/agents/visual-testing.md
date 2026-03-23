# Visual Testing & Interaction

Use Playwright MCP to visually verify any UI you build or modify — web apps, terminal apps, anything with a visual output.

## Docker networking (critical)

The playwright server in tbox runs **inside Docker** (Colima on macOS). This means `localhost` inside the container refers to the container itself — not your machine.

**Any service running on your host's localhost must be accessed via `host.docker.internal` from playwright.**

| What you want to reach | URL to use in browser_navigate |
|------------------------|-------------------------------|
| Host port 3000         | `http://host.docker.internal:3000` |
| ttyd on host port 7681 | `http://host.docker.internal:7681` |
| Static file on host    | Not accessible — serve it first |

Processes (ttyd, dev servers, TUI apps) run **on the host as normal** — no need to run them inside Docker. Docker can reach them via `host.docker.internal`.

The playwright-mcp container **must** be started with `--shared-browser-context`, otherwise each tool call (navigate, screenshot, click) gets a fresh browser context and page state is lost between calls:

```bash
docker run -d --name playwright-mcp --restart unless-stopped --entrypoint node \
  -p 8931:8931 mcr.microsoft.com/playwright/mcp \
  cli.js --headless --browser chromium --no-sandbox \
  --port 8931 --host 0.0.0.0 --shared-browser-context
```

## Web Apps

If the app runs on localhost (e.g. `localhost:3000`):

```
1. playwright browser_navigate → http://host.docker.internal:3000
2. playwright browser_take_screenshot → see the page
3. playwright browser_click / browser_type → interact
4. playwright browser_take_screenshot → verify changes
```

## Terminal Apps (TUI)

Use `ttyd` to bridge any terminal app to the browser, then use Playwright normally. ttyd runs on the host — playwright reaches it via `host.docker.internal`.

```bash
# 1. Build the binary
go build -o /tmp/myapp ./cmd/myapp

# 2. Serve it as a web page (--writable enables keyboard input)
ttyd --port 7681 --writable /tmp/myapp [args]
```

```
3. playwright browser_navigate → http://host.docker.internal:7681
4. playwright browser_take_screenshot → see the TUI rendered with full colors/styling
5. playwright browser_press_key → send keypresses (Enter, Down, Escape, q, etc.)
6. playwright browser_take_screenshot → verify the result
```

After fixing code, kill ttyd (`pkill -f ttyd`), rebuild, relaunch, re-screenshot.

### ttyd install

```bash
brew install ttyd       # macOS
apt install ttyd        # Debian/Ubuntu
```

## Feedback Loop

```
build → launch → screenshot → analyze → fix code → rebuild → relaunch → screenshot → verify
```

Do this iteratively until the UI matches expectations. This is visual backpressure — you see what's wrong and self-correct without needing human review.

## Decision Flow

```
Web app on localhost?     → playwright with http://host.docker.internal:<port>
Terminal/TUI app?         → ttyd --writable on host + playwright → http://host.docker.internal:7681
Static HTML file?         → playwright browser_navigate file:///path
Need pixel-level detail?  → browser_take_screenshot (PNG)
Need DOM structure?       → browser_snapshot (accessibility tree)
```
