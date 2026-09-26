# Packaging Rein Player as a Flatpak

This document is the end‑to‑end guide for building, testing, and publishing
Rein Player as a Flatpak. It is written for someone new to Flatpak who already
knows Flutter and Linux fundamentals.

> **Heads up:** Flatpak only builds on **Linux**. You cannot build a Flatpak
> on macOS or Windows — use a Linux VM, a Linux CI runner, or a Linux box. Once
> built, the resulting `.flatpak` file runs on any modern Linux distro that has
> the `flatpak` runtime installed.

---

## 1. What Flatpak is, in one paragraph

Flatpak is a distribution-agnostic packaging system for Linux desktop
applications. Each app runs against a versioned **runtime** (a curated set of
libraries shipped by Flathub or freedesktop.org) inside a **bubblewrap (`bwrap`) sandbox**
that restricts filesystem, network, IPC, and device access. Your app declares
the permissions it actually needs (called *finish-args* / *portals*) in a
**manifest** YAML file. `flatpak-builder` reads that manifest, fetches sources,
compiles modules, and exports the result into a local **OSTree repo**. From
there you can either install it locally for testing, export a single-file
`.flatpak` bundle, or push the repo to Flathub.

Key vocabulary:

| Term | Meaning |
| --- | --- |
| **App ID** | Reverse-DNS identifier (we use `com.reinplayer.ReinPlayer`). Must match the desktop file, metainfo, and icon names. |
| **Runtime** | Versioned base layer providing glibc, GTK, Mesa, etc. We use `org.freedesktop.Platform//26.08`. |
| **SDK** | Build-time counterpart of the runtime (toolchain + headers). We use `org.freedesktop.Sdk//26.08`. |
| **Manifest** | YAML/JSON file describing the app — `com.reinplayer.ReinPlayer.yml` here. |
| **finish-args** | Permissions granted to the sandbox at install time (filesystem, sockets, DBus names, devices). |
| **Portals** | xdg-desktop-portal APIs (file chooser, screenshot, notifications) that punch out of the sandbox without needing broad permissions. |
| **Bundle** | A single-file `.flatpak` you can hand to a user or attach to a GitHub release. |

---

## 2. Why our manifest looks the way it does

Rein Player is a Flutter Linux app that uses **media_kit**. On Linux, its
video plugin links to the build host's `libmpv.so.2`; the Flutter bundle does
not include that library. That shapes the packaging strategy:

1. **This manifest packages a prebuilt Linux bundle.** We build with Flutter
   outside `flatpak-builder`, then copy the bundle into `/app`. This is suitable
   for a standalone `.flatpak` release. Flathub requires a separate source-build
   manifest for this open-source app.
2. **Bundle missing native libraries.** `dist/build.sh flatpak` inspects the
   packaged executable and plugins inside the Flatpak build sandbox. It copies
   `libmpv.so.2` and any other libraries missing from the runtime from the
   Linux build host into the app's `lib/` directory, then repeats the check.
   The launcher adds that directory to `LD_LIBRARY_PATH`.

The runtime is `org.freedesktop.Platform//26.08`. Native media libraries that
it does not provide are included in the application bundle.

---

## 3. File layout we ship in this repo

```
dist/flatpak/
├── com.reinplayer.ReinPlayer.yml             # manifest (the entrypoint)
├── com.reinplayer.ReinPlayer.desktop         # desktop entry (App ID prefix is required)
├── com.reinplayer.ReinPlayer.metainfo.xml    # AppStream metadata for stores
└── reinplayer.sh                          # launcher wrapper
```

At build time `dist/build.sh flatpak` assembles a staging directory:

```
build/flatpak/
├── com.reinplayer.ReinPlayer.yml
└── payload/                               # consumed by `type: dir` source
    ├── com.reinplayer.ReinPlayer.desktop
    ├── com.reinplayer.ReinPlayer.metainfo.xml
    ├── reinplayer.sh
    ├── LICENSE
    ├── icons/
    │   ├── 64x64/icon.png
    │   ├── 128x128/icon.png
    │   ├── 256x256/icon.png
    │   └── 512x512/icon.png
    └── bundle/                            # copy of build/linux/x64/release/bundle
```

The manifest's `sources: [{type: dir, path: payload}]` makes
`flatpak-builder` see everything under `payload/` and run the
`build-commands` against it.

---

## 3.1 Application ID and domain ownership

The Flatpak ID is `com.reinplayer.ReinPlayer`, based on `reinplayer.com`.
`linux/CMakeLists.txt` sets the same ID on the GTK application through
`linux/my_application.cc`. The manifest, desktop entry, AppStream metainfo,
icons, and Snap `common-id` also use it. `dist/build.sh flatpak` fails if the
GTK and Flatpak IDs diverge.

For Flathub verification, publish its token through a DNS TXT record or at
`https://reinplayer.com/.well-known/org.flathub.VerifiedApps.txt`. The domain
must also have a reachable HTTPS URL related to the project.

## 4. Prerequisites (Linux host)

```bash
# Debian / Ubuntu (also install the Flutter Linux build dependencies)
sudo apt update
sudo apt install flatpak flatpak-builder libgtk-3-dev libmpv-dev mpv

# Fedora
sudo dnf install flatpak flatpak-builder

# Arch
sudo pacman -S flatpak flatpak-builder
```

Icons ship at four sizes (64 / 128 / 256 / 512) by copying the prebuilt PNGs
from `macos/Runner/Assets.xcassets/AppIcon.appiconset/` — no ImageMagick
required.

Add Flathub for the runtimes (per-user install — no sudo needed):

```bash
flatpak remote-add --if-not-exists --user flathub \
    https://flathub.org/repo/flathub.flatpakrepo
```

You also need Flutter installed and able to run `flutter build linux --release`.
The build host must have `libmpv.so.2` and the other native libraries used by
the Flutter bundle. The CI build uses Ubuntu 24.04.

---

## 5. Building the Flatpak — the fast path

From the repo root on a Linux machine:

```bash
# 1. Produce the Flutter Linux bundle.
flutter build linux --release

# 2. Build the Flatpak (installs runtimes if missing, then bundles).
./dist/build.sh flatpak
```

`build.sh` will:

1. Verify `flatpak-builder` is installed.
2. Install `org.freedesktop.Platform//26.08` and `org.freedesktop.Sdk//26.08`
   from Flathub (per-user, idempotent).
3. Check that the latest AppStream release matches the `pubspec.yaml` version.
4. Stage the manifest, desktop, metainfo, license, wrapper, icon, and Flutter bundle
   under `build/flatpak/`.
5. Build with `flatpak-builder`, inspect library dependencies inside the
   build sandbox, and rebuild with any missing host libraries included.
6. Export a portable bundle to `build/ReinPlayer-<version>-x86_64.flatpak`.

---

## 6. Installing and testing a local build

```bash
# Build first with `./dist/build.sh flatpak` from the repository root.
# Install from the local repo for testing.
flatpak --user remote-add --no-gpg-verify --if-not-exists \
    reinplayer-local "$(realpath build/flatpak-repo)"
flatpak --user install -y reinplayer-local com.reinplayer.ReinPlayer

# Check that the launcher starts, then open a video and verify playback.
flatpak run com.reinplayer.ReinPlayer
```

To install a `.flatpak` bundle on a fresh machine:

```bash
flatpak install --user ./ReinPlayer-1.1.0-x86_64.flatpak
flatpak run com.reinplayer.ReinPlayer
```

---

## 7. Sandbox permissions, in plain English

Every line in `finish-args` is a permission the user grants by installing the
app. The Flathub review explicitly checks that you ask for the **minimum**
needed. Here's what each one buys us:

| Flag | Why we need it |
| --- | --- |
| `--share=ipc` | X11/Wayland need a shared IPC namespace with the compositor. |
| `--socket=wayland` + `--socket=fallback-x11` | Display server. Wayland preferred, X11 fallback. |
| `--device=dri` | GPU access (`/dev/dri/*`) for hardware video decode. |
| `--socket=pulseaudio` | Audio out. Covers PipeWire too via its pulse compat layer. |
| `--share=network` | Opening remote URLs / streams. Remove if you decide the app is local-only. |
| `--filesystem=xdg-videos` (etc.) | Read user media folders without prompting. |
| `--filesystem=host:ro` | Read-only access for opening media from arbitrary folders and scanning neighboring files for playlists. Flathub requires an explanation for this broad permission. |
| `--filesystem=/run/media`, `/media`, `/mnt` | USB sticks and external drives — these paths sit outside `home`. |

### Tightening for Flathub

Flathub's linter flags `--filesystem=host:ro`; reviewers may grant an exception
with sufficient explanation. Rein Player currently scans folders and accepts
dragged paths, so removing this permission needs a verified replacement for
those flows. Test the file picker, drag-and-drop, playlists, and subtitle
loading before narrowing permissions.

---

## 8. Testing checklist

Before shipping, validate the build on a real Linux machine:

```bash
# Smoke test
flatpak run com.reinplayer.ReinPlayer

# Drag a video file from Files / Nautilus onto the window
# Open a video via File menu — should use the portal file chooser
# Verify audio plays (pulse/pipewire)
# Verify hardware decode (check `vainfo` host-side, then play a 4K file)
# Verify opening a media file through the installed desktop entry
# Verify the desktop entry appears in your launcher
# Verify the AppStream metainfo against the *source* file
# (the version that lives at /app/share/metainfo inside the sandbox isn't
# reachable from outside the app, so validate the source instead).
appstreamcli validate --pedantic dist/flatpak/com.reinplayer.ReinPlayer.metainfo.xml
# Don't have appstreamcli on the host? Run it from the SDK against the source:
flatpak-builder --run build/flatpak/build-dir \
    dist/flatpak/com.reinplayer.ReinPlayer.yml \
    appstreamcli validate --pedantic \
    /app/share/metainfo/com.reinplayer.ReinPlayer.metainfo.xml

# Verify the desktop file (path is the installed location for a --user flatpak):
desktop-file-validate \
    ~/.local/share/flatpak/app/com.reinplayer.ReinPlayer/current/active/files/share/applications/com.reinplayer.ReinPlayer.desktop
```

Common red flags:

- **Black video, audio works** → missing `--device=dri` or driver mismatch
  between host and runtime. `glxinfo` lives in the SDK, not the runtime, so
  run it via the devel form:
  `flatpak run --devel --command=glxinfo com.reinplayer.ReinPlayer | grep renderer`
  (or use `eglinfo`, which is present in the runtime).
- **`error while loading shared libraries: libmpv.so.2`** → wrapper script
  did not set `LD_LIBRARY_PATH`, or libmpv was not included in the bundle.
  Check `ls /app/lib/reinplayer/lib | grep mpv` from `flatpak run --command=sh com.reinplayer.ReinPlayer`.
- **File picker opens but selection silently fails** → you're hitting the
  portal but the selected file lives somewhere the sandbox can't read. Either
  widen `--filesystem=` or rely on portal-mediated transient access (which
  Flutter's `file_picker` will do for you).
- **App icon missing in launcher** → the icon filename must exactly match the
  App ID, i.e. `com.reinplayer.ReinPlayer.png`, installed under
  `/app/share/icons/hicolor/<size>/apps/`.

---

## 9. Versioning and releases

Source of truth is `pubspec.yaml` (`version: 1.1.0+2`). `dist/build.sh`
extracts the major.minor.patch portion for the output bundle filename and
requires the latest AppStream `<release>` version to match. It leaves the
authored release date unchanged.

When you cut a new release:

1. Bump `pubspec.yaml`.
2. Add a new `<release>` entry at the **top** of the `<releases>` list in
   `dist/flatpak/com.reinplayer.ReinPlayer.metainfo.xml`, with real changelog
   notes and the actual release date. The build fails if this version does
   not match `pubspec.yaml`.
3. Run the Linux Flatpak build and smoke test before publishing the bundle.

---

## 10. Publishing to Flathub

Flathub is the de facto Linux app store. Submission is a separate repo on
their GitHub org.

### 10.1 Prepare a source-build manifest

The manifest in this repo copies a prebuilt Flutter bundle from `build/`.
Flathub's current requirements say source-available applications must build
from source, with dependencies declared in the manifest and no network access
during the build. This manifest cannot be submitted as-is. A Flathub submission
needs a separate manifest that builds the Flutter app and its dependencies
inside the Flatpak build environment. The app's metadata must validate, and
reviewers will assess the `--filesystem=host:ro` permission.
The metainfo declares GPL-3.0-only, matching the repository's `LICENSE` file.
Flathub also needs a reachable HTTPS page for `reinplayer.com` that connects
the domain to the project.

### 10.2 Submission procedure

```bash
# 1. Fork https://github.com/flathub/flathub
# 2. From the `new-pr` branch of your fork, add a source-build manifest
#    named com.reinplayer.ReinPlayer.yml and flathub.json if needed.
# 3. Open a PR against flathub:new-pr
```

After the PR opens, Flathub's bot builds the architectures allowed by
`flathub.json` and posts a download link to a test repo. Expect review of
permissions, metainfo, and the source build.

A skeleton `flathub.json` for the current x86_64-only build:

```json
{
  "only-arches": ["x86_64"]
}
```

---

## 11. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `error: org.freedesktop.Platform/x86_64/26.08 not installed` | runtime missing | `flatpak install --user flathub org.freedesktop.Platform//26.08` |
| `flatpak-builder: command not found` | builder missing | `sudo apt install flatpak-builder` (or distro equivalent) |
| `Failed to setup mount /newroot/dev/dri` on launch | running in a VM without DRI | add `--allow=devel` for testing, or run on bare metal |
| `appstream-glib: failed to validate` during build | metainfo error | run `appstreamcli validate --pedantic dist/flatpak/com.reinplayer.ReinPlayer.metainfo.xml` and fix what it reports |
| `Permission denied` opening any file | over-tight sandbox | use the file chooser portal, or temporarily add `--filesystem=host` and re-test |
| App launches then crashes immediately | wrapper `LD_LIBRARY_PATH` wrong | `flatpak run --command=sh com.reinplayer.ReinPlayer` then `ldd /app/lib/reinplayer/rein_player` |
| `Could not load shared library libmpv.so.2` | the host libmpv was not packaged | verify `build/flatpak/payload/bundle/lib/libmpv.so.2` exists after running `build.sh flatpak` |

Useful debug commands:

```bash
# Drop into a shell inside the sandbox
flatpak run --command=sh com.reinplayer.ReinPlayer

# Show the effective sandbox permissions
flatpak info --show-permissions com.reinplayer.ReinPlayer

# Tail logs
journalctl --user -f -t flatpak-session-helper
```

---

## 12. CI build

`.github/workflows/ci-fast.yaml` includes a `build-linux-flatpak` job on PRs
to `dev`, tag pushes, and manual workflow runs. It builds the Flutter Linux bundle on
`ubuntu-24.04`, validates the desktop and AppStream files, then runs
`./dist/build.sh flatpak`, installs the bundle, and checks its shared libraries
against the installed runtime. The resulting `.flatpak` is uploaded
as a workflow artifact and attached to tagged
GitHub releases.

This CI job builds the standalone bundle described above. It does not submit
to Flathub or replace the Linux installation and playback smoke test.

---

## 13. Further reading

- Flatpak docs — <https://docs.flatpak.org/>
- Flathub submission guide — <https://docs.flathub.org/docs/for-app-authors/submission>
- AppStream metainfo reference — <https://www.freedesktop.org/software/appstream/docs/>
- xdg-desktop-portal — <https://flatpak.github.io/xdg-desktop-portal/>
- Flutter on Flathub example — <https://github.com/flathub/dev.bnyro.tomato>
