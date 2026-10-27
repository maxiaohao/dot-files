# caps-nav — CapsLock navigation layer (Kanata)

Hold **CapsLock** as a momentary navigation layer:

- `h` `j` `k` `l`: Left / Down / Up / Right
- `a` `e`: Home / End
- `p` `n`: PageUp / PageDown
- `g` `t`: grave / tilde
- `Backspace`: Delete
- `c`: emit a real CapsLock keypress

Movement keys repeat after a 400 ms delay at 20 ms intervals. Adjust `hh` and
`rr` in `caps-nav.kbd`.

## Recommendation: user-level systemd

Use the included **user service**. Kanata runs as your login user rather than
root, starts with your desktop session, and stops when that session ends. The
one-time setup grants that user access to Linux input devices and `/dev/uinput`.

A system service is appropriate only if remapping must work before login or
without an active user session. It usually runs as root or needs a dedicated
service account with the same device permissions, so it adds privilege and
multi-user complexity without a benefit for a personal desktop.

Granting membership in the `input` group allows processes running as your user
to read keyboard input. Only do this on a trusted personal machine.

## Install

Install `kanata` with your distribution's package manager or with Cargo and
make sure `kanata` is on `PATH`. Then run:

```bash
./setup-kanata.sh
```

The script:

- creates the system `uinput` group if needed;
- adds the current user to `input` and `uinput`;
- loads `uinput` now and at boot;
- installs the `/dev/uinput` udev rule;
- validates the config;
- links the config and unit into `~/.config`; and
- enables the systemd user service.

After the first setup, log out and back in so the new group memberships apply.

## Manage

```bash
systemctl --user status kanata-caps-nav.service
systemctl --user restart kanata-caps-nav.service
systemctl --user stop kanata-caps-nav.service
systemctl --user disable --now kanata-caps-nav.service
journalctl --user -u kanata-caps-nav.service -f
```

Emergency quit chord (physical keys): **Left Ctrl + Space + Escape**.

## XRDP sessions

XRDP injects keyboard input directly into X11 instead of exposing an evdev
keyboard, so the Kanata service cannot intercept remote keystrokes. The
`start-xrdp-caps-nav.sh` launcher applies the same bindings directly in the X11
keymap using `xmodmap`.

Link the launcher, watcher, and service template:

```bash
mkdir -p ~/.local/bin ~/.config/systemd/user
ln -sfn "$PWD/xrdp/start-xrdp-caps-nav.sh" ~/.local/bin/start-xrdp-caps-nav
ln -sfn "$PWD/xrdp/watch-xrdp-caps-nav.sh" ~/.local/bin/watch-xrdp-caps-nav
ln -sfn "$PWD/xrdp/xrdp-caps-nav@.service" \
  ~/.config/systemd/user/xrdp-caps-nav@.service
systemctl --user daemon-reload
```

For this dot-files repository, `.xinitrc` starts an
`xrdp-caps-nav@DISPLAY.service` instance for every XRDP display. The service
checks the X11 keymap every two seconds and reapplies it if XRDP or LXDE resets
the map during a reconnect.

The X11 implementation uses the session's normal key-repeat timing. The
Kanata-specific per-key `rr` and `hh` timings apply only to physical keyboards.
