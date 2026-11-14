# AGENTS.md

Fork of [yusiwen/kasm-core-minimal](https://github.com/yusiwen/kasm-core-minimal) (itself based on Kasm's `workspaces-core-images`). Image: `sernafa/kasm-openbox-minimal`. License: MIT (`LICENSE`, keeps Kasm's copyright notice).

## Build

```bash
docker buildx bake --load
```

The `default` group builds only the `kasm-core-minimal` target (1.4.1, Ubuntu). Current releases are the `*-1_5_1` targets, e.g. `kasm-core-minimal-1_5_1`, `kasm-core-minimal-systemd-1_5_1`, `kasm-core-minimal_trixie-1_5_1`, `kasm-core-minimal_trixie-systemd-1_5_1`. Targets are multi-arch (`linux/amd64`, `linux/arm64`) and `--no-cache` is forced in bake config. `--load` cannot load multi-arch images, so for a local build add `--set '*.platform=linux/amd64'`.

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

- `docker-bake.hcl` — defines build targets and tags (e.g. `sernafa/kasm-openbox-minimal:1.5.1`)
- `src/common/install/kasm_vnc/kasmvnc.yaml` — KasmVNC server config (SSL cert path, UDP public_ip)
- `src/ubuntu/systemd/kasmvnc.service` — systemd unit for the systemd variant
- `src/ubuntu/defaults/openbox/autostart` — openbox autostart (merges `~/.Xresources`, launches tint2)
- `src/ubuntu/defaults/tint2/tint2rc` — tint2 panel config (taskbar, systray, clock)
- `src/ubuntu/defaults/xterm/Xresources` — X resources merged by openbox autostart (xterm font: DejaVu Sans Mono)
- `src/ubuntu/defaults/openbox/menu.xml` — right-click desktop menu (needs `obamenu` package)

## Defaults

- Timezone `Europe/Madrid` (`ARG TZ`, override at runtime with `-e TZ=`). Language stays `en_US.UTF-8`; `es_ES.UTF-8` is generated and selectable with `-e LC_ALL=es_ES.UTF-8` (standard image only, see systemd note above).
- Desktop: Openbox + tint2 (`panel_items = TSC`); default Openbox window buttons, including minimize.
- xterm uses DejaVu Sans Mono 10 via `~/.Xresources`.
- The default profile in `/home/kasm-default-profile` is copied to `$HOME` only if `.bashrc` is missing; a persisted `$HOME` keeps old dotfiles and will not pick up changes to `autostart`, `tint2rc` or `.Xresources`.

## Version bump workflow

To add a new version target, add a new `target` block in `docker-bake.hcl` (copy a `*-1_5_1` block) with `KASMVNC_COMMIT_ID`, `KASMVNC_BRANCH`, `KASMVNC_VER`, `PROFILE_SYNC_V2_COMMIT_ID`, `PROFILE_SYNC_V2_BRANCH` and corresponding tags. The Dockerfiles accept these as build args to control which KasmVNC and profile-sync builds are downloaded by `install_kasm_vnc.sh` and `install_profile_sync.sh`. The older `1.4.1` targets still pass the removed `COMMIT_ID`/`BRANCH` args and are likely broken.

## Git

`origin` is `sernafa/kasm-openbox-minimal`, `upstream` is the original `yusiwen/kasm-core-minimal`. The git credential helper in this environment points to a non-existent `/opt/homebrew/bin/gh`; push with `git -c credential.helper= -c credential.helper='!gh auth git-credential' push` or run `gh auth setup-git`.

## No tests, no CI

This repo has no test suite, linter, or CI workflow. Changes are validated by building the image and running a container.
