# caps-nav — CapsLock navigation layer (kanata)

Hold **CapsLock** as a momentary nav layer:

| Hold CapsLock + | Action |
|---|---|
| `h` `j` `k` `l` | Left / Down / Up / Right |
| `a` `e` | Home / End |
| `p` `n` | PageUp / PageDown |
| `g` `t` | `` ` `` / `~` |
| `Backspace` | Delete (forward) |

Arrows and Backspace fast-repeat after a short halt. Tune in `caps-nav.kbd`:
`$rr` (nav repeat gap ms), `$br` (backspace repeat gap ms), `$hh` (halt ms).

## Files
- `caps-nav.kbd` — the kanata config (the actual layer definition).
- `caps-nav.logon-task.xml` — Task Scheduler definition that auto-starts kanata
  at logon (elevated, in the interactive session).
- `caps-nav.ahk` — legacy AutoHotkey version (superseded by kanata; kept for reference).

## Engine
Runs on **kanata** using the **winIOv2 (LLHOOK)** build — a low-level keyboard
hook in the interactive session. No driver required.

> Why not a Windows service? A service runs in Session 0 and an LLHOOK there
> can't see your keystrokes. The Interception-driver service route was tried and
> failed (keys dead). The at-logon task below is the working approach.

## One-time setup on a new machine

1. Install kanata (winget): `winget install jtroo.kanata_gui`
2. Copy the LLHOOK GUI build to a stable path (so winget upgrades don't break the task):
   ```powershell
   $pkg = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\jtroo.kanata_gui_*\kanata_windows_gui_winIOv2_x64.exe"
   New-Item -ItemType Directory -Force C:\tools\kanata\bin | Out-Null
   Copy-Item (Resolve-Path $pkg) C:\tools\kanata\bin\kanata-gui.exe -Force
   ```
3. Validate the config:
   ```powershell
   C:\tools\kanata\bin\kanata-gui.exe --cfg "$HOME\dev\dot-files\win\caps-nav.kbd" --check
   ```
4. Register the logon task **from an elevated shell** (needed for RunLevel=Highest):
   ```powershell
   Register-ScheduledTask -TaskName 'kanata-caps-nav' `
     -Xml (Get-Content "$HOME\dev\dot-files\win\caps-nav.logon-task.xml" -Raw) -Force
   Start-ScheduledTask -TaskName 'kanata-caps-nav'
   ```

> The XML hardcodes `REDMOND\makev`, `C:\tools\kanata\bin\kanata-gui.exe`, and the
> config path. Edit `<UserId>`, `<Command>`, and `<Arguments>` for a new
> machine/user before registering. `RunLevel=HighestAvailable` runs it elevated
> at logon with no UAC prompt; 15s `<Delay>` lets Windows settle first.

## Manage

```powershell
Get-ScheduledTask     -TaskName 'kanata-caps-nav'   # State
Stop-ScheduledTask    -TaskName 'kanata-caps-nav'   # disable (kills kanata-gui)
Start-ScheduledTask   -TaskName 'kanata-caps-nav'   # enable
Unregister-ScheduledTask -TaskName 'kanata-caps-nav' -Confirm:$false

# reload after editing caps-nav.kbd: tray icon -> Reload, or:
Stop-ScheduledTask kanata-caps-nav; Start-ScheduledTask kanata-caps-nav

# confirm it runs in YOUR session (SessionId != 0):
Get-CimInstance Win32_Process -Filter "Name='kanata-gui.exe'" | Select ProcessId,SessionId
```

## Gotchas
- **Only one remapper at a time** — don't also auto-start `caps-nav.ahk`.
- Emergency-quit chord (physical keys): **LCtrl + Space + Esc**.
- LLHOOK misses a few apps' shortcuts; not active on the pre-login/UAC secure desktop.
- Defender may false-flag the **tty winIOv2** kanata variant; the **GUI** build used here is fine.
