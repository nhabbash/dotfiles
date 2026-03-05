# Visual Testing & Interaction

Use Playwright MCP to visually verify any UI you build or modify — web apps, terminal apps, anything with a visual output.

## Web Apps

If the app runs on localhost (e.g. `localhost:3000`):

```
1. playwright browser_navigate → http://localhost:3000
2. playwright browser_take_screenshot → see the page
3. playwright browser_click / browser_type → interact
4. playwright browser_take_screenshot → verify changes
```

## Terminal Apps (TUI)

Use `ttyd` to bridge any terminal app to the browser, then use Playwright normally.

```bash
# 1. Build the binary
go build -o /tmp/myapp ./cmd/myapp

# 2. Serve it as a web page (--writable enables keyboard input)
ttyd --port 7681 --writable /tmp/myapp [args]
```

```
3. playwright browser_navigate → http://localhost:7681
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
Web app on localhost?     → playwright directly
Terminal/TUI app?         → ttyd --writable + playwright
Static HTML file?         → playwright browser_navigate file:///path
Need pixel-level detail?  → browser_take_screenshot (PNG)
Need DOM structure?       → browser_snapshot (accessibility tree)
```
