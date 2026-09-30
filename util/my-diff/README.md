# My Diff

A single-page text comparison tool: paste text on the left and right, get a
Monaco side-by-side diff, and click any line to see a word-level diff of that
line rendered as two rows in the bottom panel.

Everything lives in `index.html` (Monaco loads from a CDN, so the browser needs
internet). `server.js` is a dependency-free static server bound to `127.0.0.1`.

## Run it once

```powershell
node server.js 8777
```

Then open <http://localhost:8777/>.

## Install it so it starts at boot

From an **elevated** PowerShell:

```powershell
.\install-service.ps1            # installs on port 8777 and starts it
.\install-service.ps1 -Port 9000 # use a different port
.\install-service.ps1 -Status    # task state and endpoint check
.\install-service.ps1 -Uninstall # remove it
```

Node.js must be installed; nothing else is required. `node.exe` cannot be
registered with `sc.exe`, so the installer creates a **SYSTEM scheduled task**
with an *At startup* trigger instead — same effect as a service, no NSSM or
node-windows. The server listens on localhost only, so no firewall rule is
needed.
