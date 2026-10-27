# XRDP optimisation on Arch Linux

This directory captures the known-good XRDP configuration used for a 4K
Microsoft Remote Desktop (`mstsc.exe`) session on Arch Linux.

The working stack is:

- XRDP with `xorgxrdp-glamor`;
- LXDE with Openbox and no compositor;
- H.264 GFX at up to 60 fps, with RemoteFX as fallback;
- 144 DPI and a 72-pixel cursor;
- PulseAudio XRDP audio redirection; and
- Chrome using GPU compositing with software video decoding.

No certificates, private keys, passwords or browser profile data are included.

## Files

Server configuration:

- `xrdp.ini` -> `/etc/xrdp/xrdp.ini`
- `gfx.toml` -> `/etc/xrdp/gfx.toml`
- `sesman.ini` -> `/etc/xrdp/sesman.ini`
- `xorg.conf` -> `/etc/X11/xrdp/xorg.conf`
- `pulse-default.pa` -> `/etc/xrdp/pulse/default.pa`

Desktop configuration:

- `xinitrc` -> `~/.xinitrc`
- `Xresources` -> `~/.Xresources`
- `lxde-desktop.conf` -> `~/.config/lxsession/LXDE/desktop.conf`
- `lxde-autostart` -> `~/.config/lxsession/LXDE/autostart`
- `openbox-lxde-rc.xml` -> `~/.config/openbox/lxde-rc.xml`
- `picom-disabled.desktop` -> `~/.config/autostart/picom.desktop`
- `gtk3-settings.ini` -> `~/.config/gtk-3.0/settings.ini`
- `gtk3.css` -> `~/.config/gtk-3.0/gtk.css`
- `gtk4-settings.ini` -> `~/.config/gtk-4.0/settings.ini`
- `gtk2rc` -> `~/.gtkrc-2.0.mine`
- `chrome-flags.conf` -> `~/.config/chrome-flags.conf`

XRDP CapsLock navigation:

- `start-xrdp-caps-nav.sh`
- `watch-xrdp-caps-nav.sh`
- `xrdp-caps-nav.Xmodmap`
- `xrdp-caps-nav@.service`

The general Kanata files remain one directory above because they apply to
physical keyboards, not specifically to XRDP.

## Packages

Install the desktop and audio server from the Arch repositories:

```bash
sudo pacman -S --needed \
  lxde-common lxsession openbox lxpanel pcmanfm lxappearance \
  lxde-icon-theme pulseaudio
```

Install the XRDP packages from the AUR:

```bash
yay -S --needed xrdp xorgxrdp-glamor pulseaudio-module-xrdp
```

`pulseaudio-module-xrdp` installs the sink/source modules and
`/etc/xdg/autostart/pulseaudio-xrdp.desktop`. Without it, Chrome can buffer and
decode YouTube frames but remain stuck at `0:00` because the only audio sink is
a suspended physical speaker.

## Restore the server configuration

Run these commands from this directory:

```bash
sudo install -Dm0644 xrdp.ini /etc/xrdp/xrdp.ini
sudo install -Dm0644 gfx.toml /etc/xrdp/gfx.toml
sudo install -Dm0644 sesman.ini /etc/xrdp/sesman.ini
sudo install -Dm0644 xorg.conf /etc/X11/xrdp/xorg.conf
sudo install -Dm0644 pulse-default.pa /etc/xrdp/pulse/default.pa
```

Enable the service:

```bash
sudo systemctl enable --now xrdp.service
```

Restarting XRDP disconnects current remote sessions:

```bash
sudo systemctl restart xrdp.service xrdp-sesman.service
```

## Restore the desktop configuration

These are full snapshots. Review and merge them if the target account already
has unrelated desktop customisation.

```bash
install -Dm0755 xinitrc ~/.xinitrc
install -Dm0644 Xresources ~/.Xresources
install -Dm0644 lxde-desktop.conf ~/.config/lxsession/LXDE/desktop.conf
install -Dm0644 lxde-autostart ~/.config/lxsession/LXDE/autostart
install -Dm0644 openbox-lxde-rc.xml ~/.config/openbox/lxde-rc.xml
install -Dm0644 picom-disabled.desktop ~/.config/autostart/picom.desktop
install -Dm0644 gtk3-settings.ini ~/.config/gtk-3.0/settings.ini
install -Dm0644 gtk3.css ~/.config/gtk-3.0/gtk.css
install -Dm0644 gtk4-settings.ini ~/.config/gtk-4.0/settings.ini
install -Dm0644 gtk2rc ~/.gtkrc-2.0.mine
install -Dm0644 chrome-flags.conf ~/.config/chrome-flags.conf
```

Log out of the existing desktop session and reconnect to start LXDE.

## Restore CapsLock navigation

From `linux/`, link the XRDP-specific helpers:

```bash
mkdir -p ~/.local/bin ~/.config/systemd/user
ln -sfn "$PWD/xrdp/start-xrdp-caps-nav.sh" \
  ~/.local/bin/start-xrdp-caps-nav
ln -sfn "$PWD/xrdp/watch-xrdp-caps-nav.sh" \
  ~/.local/bin/watch-xrdp-caps-nav
ln -sfn "$PWD/xrdp/xrdp-caps-nav@.service" \
  ~/.config/systemd/user/xrdp-caps-nav@.service
systemctl --user daemon-reload
```

`xinitrc` starts one `xrdp-caps-nav@DISPLAY.service` instance for each XRDP
display. The watcher reapplies the X11 mapping if a reconnect resets it.

## Why these settings are fast

### XRDP graphics

`gfx.toml` prefers H.264 over RemoteFX:

```toml
order = [ "H.264", "RFX" ]
```

The x264 profile uses:

- `ultrafast`;
- `zerolatency`;
- 60 fps;
- two encoder threads; and
- no LAN bitrate cap.

`xrdp.ini` captures H.264 frames every 16 ms. The LAN connection retains bitmap
cache, bitmap compression, bulk compression and fast-path support.

RemoteFX Progressive caused menus and context windows to appear to fade while
tiles were refined. H.264 removed that effect and performed well on the
six-core Ryzen host.

### MSTSC client

Set the Windows client colour depth to **Highest Quality (32-bit)**. Lower
colour depth causes XRDP to reject the GFX pipeline and fall back to slower
normal bitmap capture.

For a LAN connection:

- select the LAN experience profile;
- retain persistent bitmap caching; and
- disable wallpaper, animations, desktop composition, full-window drag and
  unused device redirection.

### Xorg and desktop

`xorg.conf` gives `xorgxrdp` access to `/dev/dri/renderD128`, DRI3 and glamor.
Confirm the Xorg log reports hardware acceleration for the installed GPU.

LXDE/Openbox replaces XFCE for lower overhead. The configuration:

- disables Openbox iconify animation and desktop-switch popups;
- uses wireframe resize rather than repainting full 4K windows;
- disables GTK2, GTK3 and GTK4 animation;
- prevents the system Picom autostart entry from launching; and
- starts no compositor from LXSession.

Picom must not be running. It was the source of menu and Chrome context-menu
fades even when XFWM compositing was disabled.

### DPI and cursor

The server and desktop use 144 DPI:

- `sesman.ini` launches Xorg with `-dpi 144`;
- LXSession publishes `iXft/DPI=147456` (`144 * 1024`); and
- `Xresources` contains `Xft.dpi: 144`.

The cursor is 72 pixels (`4 *` LXDE's original 18-pixel size).

### Chrome and YouTube

Chrome uses ANGLE/OpenGL compositing but software video decoding. AMD VA-API
successfully decoded frames under Xorgxrdp, but decoded surfaces were not
presented reliably. Fully disabling the GPU also stalled after a few frames.

The working combination is:

- ANGLE/OpenGL compositing;
- `--disable-accelerated-video-decode`;
- no UI animation;
- autoplay without a local user-gesture requirement;
- the existing AdBlock extension explicitly loaded to bypass a pre-roll stream
  which stalled before the main video; and
- `xrdp-sink` as the PulseAudio default sink.

If the AdBlock extension version changes, update its versioned path in
`chrome-flags.conf`.

## Validate

Confirm H.264 negotiation after reconnect:

```bash
journalctl -u xrdp -b --no-pager |
  grep -E 'Codec search order|Matched .* mode|starting .* codec'
```

Expected:

```text
Codec search order is H264, RFX
Matched H264 mode
xrdp_encoder_create: starting h264 codec session gfx
```

Confirm capture timing:

```bash
grep -Ei 'got (H264|RFX|normal) capture|msFrameInterval' \
  ~/.xorgxrdp.*.log | tail
```

Expected H.264 interval:

```text
got H264 capture
msFrameInterval 16
```

Confirm DPI:

```bash
xdpyinfo | grep -E 'dimensions:|resolution:'
xrdb -query | grep -E 'Xft.dpi|Xcursor.size'
```

Confirm no compositor:

```bash
pgrep -af 'picom|compton|xcompmgr'
```

Confirm XRDP audio:

```bash
pactl get-default-sink
pactl list short modules | grep module-xrdp
```

Expected default sink:

```text
xrdp-sink
```
