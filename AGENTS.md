# AGENTS.md

Fork of [yusiwen/kasm-core-minimal](https://github.com/yusiwen/kasm-core-minimal) (itself based on Kasm's `workspaces-core-images`). Image: `sernafa/kasm-openbox-minimal`. License: MIT (`LICENSE`, keeps Kasm's copyright notice).

## Build

```bash
docker buildx bake --load
```

The `default` group builds only the `openbox` target (standard Ubuntu image). The `all` group builds every variant: `openbox`, `openbox-systemd`, `openbox-trixie`, `openbox-trixie-systemd`. Targets build for `linux/amd64` only and `--no-cache` is forced in bake config; `--load` loads the images into the local Docker store. Target names are stable across versions: the image name and version live in the `IMAGE`/`VERSION` HCL variables of `docker-bake.hcl` (overridable via environment), which is how CI publishes to GHCR. Variant suffixes (`-systemd`, `-trixie`, `-trixie-systemd`) are part of each target's `tags` in the bake file.

The image version (e.g. `1.0.0`) is the project's own versioning and is independent of the bundled upstream component versions set via build args (KasmVNC `1.5.1`, profile-sync `release_2.1.1`).

## Variants

- **`Dockerfile`** — standard image. Runtime stage copies from `scratch` for minimal size. `vnc_startup.sh` is PID 1 and runs as `kasm-user`; the user has passwordless sudo.
- **`Dockerfile.systemd`** — runs systemd as PID 1. Uses `antmelekhin/docker-systemd:ubuntu-24.04` as base image. Requires `--privileged`, `--cgroupns=host`, and `-v=/sys/fs/cgroup:/sys/fs/cgroup:rw` at runtime. Only the variables listed in `PassEnvironment` of `kasmvnc.service` reach KasmVNC (e.g. `TZ` does, `LC_ALL` does not). The `kasm-user` has no sudo here.

## Architecture

- Two-stage Docker build: `base_layer` (FROM ubuntu:24.04) installs everything, then copies into `scratch`.
- Source tree:
  - `src/common/` — shared startup scripts, profile sync, kasmvnc.yaml
  - `src/ubuntu/` — Ubuntu-specific install scripts, systemd unit, openbox defaults
- Container entrypoint chain (applies to both variants):
  1. `kasm_default_profile.sh` — copies default profile to `$HOME` if `.bashrc` missing, sets up symlinks
  2. `vnc_startup.sh` — full VNC lifecycle: cert gen, Xvnc launch, openbox, websocket proxy
  3. `kasm_startup.sh` — (not in this repo; expected at `/dockerstartup/kasm_startup.sh`)
  CMD is `--wait` which keeps the container alive.

## Key files

- `docker-bake.hcl` — defines build targets and tags (e.g. `sernafa/kasm-openbox-minimal:1.0.0`)
- `src/common/install/kasm_vnc/kasmvnc.yaml` — KasmVNC server config (SSL cert path, UDP public_ip, clipboard DLP tuned for xfce4-clipman: both directions enabled, X PRIMARY selection excluded to avoid flooding clipman's history with mere selections)
- `src/ubuntu/systemd/kasmvnc.service` — systemd unit for the systemd variant
- `src/ubuntu/defaults/openbox/autostart` — openbox autostart (merges `~/.Xresources`, launches tint2, xfconfd and xfce4-clipman)
- `src/ubuntu/defaults/openbox/rc.xml` — shipped openbox config: stock Debian `rc.xml` plus rofi keybindings (`W-w` window switcher, `W-s` SSH, `C-space` run dialog, all with the bundled `Arc-Dark` theme)
- `src/ubuntu/defaults/tint2/tint2rc` — tint2 config from the `kasm-core-minimal` theme: dark panel (`#1d1f21`) at the top with tasks/systray/clock (`LTSC`)
- `src/ubuntu/defaults/xterm/Xresources` — X resources merged by openbox autostart (xterm font: Noto Mono)
- `src/ubuntu/defaults/openbox/menu.xml` — right-click desktop menu (needs `obamenu` package)

## Defaults

- Timezone `Europe/Madrid` (`ARG TZ`, override at runtime with `-e TZ=`). Language stays `en_US.UTF-8`; `es_ES.UTF-8` is generated and selectable with `-e LC_ALL=es_ES.UTF-8` (standard image only, see systemd note above).
- Desktop: Openbox + tint2 (`panel_items = LTSC`, top panel, dark theme from `kasm-core-minimal`); default Openbox window buttons, including minimize.
- rofi installed and bound to `W-w` (window switcher), `W-s` (SSH) and `C-space` (run dialog), using the bundled `Arc-Dark` theme. `feh` (image viewer) and `pcmanfm` (file manager) are also installed; both are reachable from rofi and the applications menu. For pcmanfm, `/etc/xdg/libfm/libfm.conf` sets terminator as its terminal and `libfm-modules` is deliberately not installed (it triggers GLib-GIO CRITICAL storms on this GLib; an empty `libfm/modules` dir silences the startup warning instead) — the only pcmanfm noise left is its own upstream "deprecated style property" theme warnings.
- terminator is installed and registered as the default `x-terminal-emulator` alternative (`update-alternatives --set` in `install_openbox.sh`), so the Openbox root menu's Terminal entry launches it. A system config is written to `/etc/xdg/terminator/config` (Noto Mono profile; without the file terminator logs a read error on startup) and `gir1.2-keybinder-3.0`/`gir1.2-notify-0.7` are installed explicitly (Recommends that `--no-install-recommends` would skip; without them the `hide_window` shortcut and notification plugins are unavailable). xterm remains installed and uses Noto Mono via `~/.Xresources`.
- `elementary-xfce-icon-theme` + `hicolor-icon-theme` provide systray/app icons (e.g. xfce4-clipman); without a theme GTK falls back to a dark glyph invisible on the dark tint2 panel. `/etc/gtk-3.0/settings.ini` selects the theme — there is no XSettings manager, so GTK reads that file directly.
- xfce4-clipman is installed and autostarted with the session (line in `src/ubuntu/defaults/openbox/autostart`); its icon lives in the tint2 systray. The autostart launches `xfconfd` (symlinked onto PATH by `install_openbox.sh`) before it: without the daemon, clipman spams GLib CRITICAL logs and cannot persist its settings.
- System font is Noto (`fonts-noto-core`): fontconfig prefers Noto Sans/Serif/Mono for the generic families via `/etc/fonts/conf.d/59-noto-defaults.conf` (written by `install_openbox.sh`; numbered to load before Debian's `60-latin.conf`, which otherwise wins with DejaVu Sans Mono for monospace). tint2 and xterm use Noto explicitly; xterm size 10 via `~/.Xresources`. `fonts-dejavu-core` stays installed as fallback.
- `zsh` is installed (`install_tools.sh`) and is the login shell of `kasm-user` (`useradd -s /usr/bin/zsh`); without an explicit shell the passwd entry defaulted to `/bin/sh`. The default profile ships a `.zshrc` that sources `generate_container_user` and re-exports `PS1` with zsh escapes (`%~`), since bash's `\w` never expands in zsh. `.bashrc` is still provisioned for when bash is used explicitly.
- The default profile in `/home/kasm-default-profile` is copied to `$HOME` only if `.bashrc` is missing; a persisted `$HOME` keeps old dotfiles and will not pick up changes to `autostart`, `tint2rc` or `.Xresources`.
- Home ownership: runtime-stage `COPY`s create the shipped dotfiles root-owned (COPY ignores `USER`), which broke writes under `$HOME` (xfconfd's backend died with `configuration directory "(null)"`, clipman-settings could not save its actions XML). Both Dockerfiles `chown -R 1000:0 $HOME` after the COPYs, the default profile itself is chowned at build time (the startup `cp -rp` preserves ownership), and `XDG_CONFIG_HOME=$HOME/.config` is set via ENV because the image ships the variable empty, which xfconfd cannot handle.

## Version bump workflow

To add a new version, bump the `VERSION` variable in `docker-bake.hcl` (target names never change, so neither the `default`/`all` groups nor the workflows need edits). When adopting new upstream component versions, update the `KASMVNC_COMMIT_ID`, `KASMVNC_BRANCH`, `KASMVNC_VER`, `PROFILE_SYNC_V2_COMMIT_ID` and `PROFILE_SYNC_V2_BRANCH` args in the same file; the Dockerfiles accept these as build args to control which KasmVNC and profile-sync builds are downloaded by `install_kasm_vnc.sh` and `install_profile_sync.sh`.

## Git

`origin` is `sernafa/kasm-openbox-minimal`, `upstream` is the original `yusiwen/kasm-core-minimal`. Git authentication works out of the box (`gh` is installed at `/opt/homebrew/bin/gh` and logged in); plain `git push` is enough. Pushing a `v*` tag triggers the release workflow; note that the very first tag push after adding CI may not fire the workflow — re-pushing the tag triggers it.

## CI

Two GitHub Actions workflows publish images to GHCR as `ghcr.io/<owner>/<repo>`:

- `release.yml` — on push of a `v*` tag; builds the `default` bake target and publishes it as `:<version>` (tag without the `v`).
- `manual-build.yml` — `workflow_dispatch`; pick a bake target (`all` included) and a version tag.

Both simply set `IMAGE` (ghcr.io form, derived from the repository name) and `VERSION` as environment variables; `docker-bake.hcl` consumes them and applies the variant suffixes, so no tag rewriting happens in CI and the four variants never collide on the same tag.

## No tests

This repo has no test suite or linter. Changes are validated by building the image and running a container.
