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
| **App ID** | Reverse-DNS identifier (we use `one.ahurein.reinplayer`). Must match the desktop file, metainfo, and icon names. |
| **Runtime** | Versioned base layer providing glibc, GTK, Mesa, etc. We use `org.freedesktop.Platform//24.08`. |
| **SDK** | Build-time counterpart of the runtime (toolchain + headers). We use `org.freedesktop.Sdk//24.08`. |
| **Manifest** | YAML/JSON file describing the app — `one.ahurein.reinplayer.yml` here. |
| **finish-args** | Permissions granted to the sandbox at install time (filesystem, sockets, DBus names, devices). |
| **Portals** | xdg-desktop-portal APIs (file chooser, screenshot, notifications) that punch out of the sandbox without needing broad permissions. |
| **Bundle** | A single-file `.flatpak` you can hand to a user or attach to a GitHub release. |

---

## 2. Why our manifest looks the way it does

Rein Player is a Flutter Linux app that uses **media_kit**, which in turn
ships a prebuilt `libmpv` inside the Flutter Linux bundle (`build/linux/x64/release/bundle/lib/`).
That changes the packaging strategy in two important ways:

1. **We don't compile from source inside the sandbox.** Building Flutter inside
   `flatpak-builder` is painful (the SDK has no Dart toolchain). Instead we
   build the Linux bundle **outside** the sandbox with the regular Flutter
   toolchain, then have the manifest copy that prebuilt bundle into `/app`.
   This is the same pattern used by every Flutter app currently on Flathub.
2. **No `libmpv` module needed.** Because media_kit bundles its own libmpv,
   we don't pull mpv as a build dependency. The wrapper script just adds
   `/app/lib/reinplayer/lib` to `LD_LIBRARY_PATH` so the loader finds it.

The runtime is `org.freedesktop.Platform//24.08` rather than
`org.gnome.Platform`. Rein Player only needs GTK3 / Mesa / glibc — pulling in
the full GNOME platform would balloon the image for no gain.

---

## 3. File layout we ship in this repo

```
dist/flatpak/
├── one.ahurein.reinplayer.yml             # manifest (the entrypoint)
├── one.ahurein.reinplayer.desktop         # desktop entry (App ID prefix is required)
├── one.ahurein.reinplayer.metainfo.xml    # AppStream metadata for stores
└── reinplayer.sh                          # launcher wrapper
```

At build time `dist/build.sh flatpak` assembles a staging directory:

```
build/flatpak/
├── one.ahurein.reinplayer.yml
└── payload/                               # consumed by `type: dir` source
    ├── one.ahurein.reinplayer.desktop
    ├── one.ahurein.reinplayer.metainfo.xml
    ├── reinplayer.sh
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

## 3.1 Pre-flight: the GTK application-id must match the Flatpak App ID

`linux/CMakeLists.txt` currently has:

```cmake
set(APPLICATION_ID "com.example.rein_player")
```

That value is also baked into `linux/my_application.cc` via the `application-id`
property on the `GtkApplication`. For self-built Flatpaks the app runs fine
with the mismatch — but **Flathub will reject the submission** because it
breaks portal parenting, MPRIS routing, and DBus activation (the system uses
the GApplication ID to identify the app, and it must equal the Flatpak App ID
`one.ahurein.reinplayer`).

Before submitting to Flathub, change line 10 of `linux/CMakeLists.txt` to:

```cmake
set(APPLICATION_ID "one.ahurein.reinplayer")
```

`dist/build.sh flatpak` prints a warning when the IDs disagree so this
doesn't slip past you. (The snap manifest already uses
`one.ahurein.reinplayer` as `common-id`, so this is the value the rest of the
packaging already assumes.)

## 4. Prerequisites (Linux host)

```bash
# Debian / Ubuntu
sudo apt update
sudo apt install flatpak flatpak-builder

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
2. Install `org.freedesktop.Platform//24.08` and `org.freedesktop.Sdk//24.08`
   from Flathub (per-user, idempotent).
3. Stamp the current `pubspec.yaml` version into the AppStream metainfo.
4. Stage the manifest, desktop, metainfo, wrapper, icon, and Flutter bundle
   under `build/flatpak/`.
5. Run `flatpak-builder --repo=build/flatpak-repo build-dir manifest.yml`.
6. Export a portable bundle to `build/ReinPlayer-<version>-x86_64.flatpak`.

---

## 6. Building manually (so you understand what the script does)

```bash
# Stage payload directory (manual equivalent of build.sh's flatpak target)
mkdir -p build/flatpak/payload/bundle
cp dist/flatpak/one.ahurein.reinplayer.yml          build/flatpak/
cp dist/flatpak/one.ahurein.reinplayer.desktop      build/flatpak/payload/
cp dist/flatpak/one.ahurein.reinplayer.metainfo.xml build/flatpak/payload/
cp dist/flatpak/reinplayer.sh                       build/flatpak/payload/
for s in 64 128 256 512; do
  mkdir -p "build/flatpak/payload/icons/${s}x${s}"
  cp "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_${s}.png" \
     "build/flatpak/payload/icons/${s}x${s}/icon.png"
done
cp -r build/linux/x64/release/bundle/.              build/flatpak/payload/bundle/

# Build into a local OSTree repo
cd build/flatpak
flatpak-builder --user --force-clean \
    --repo=../flatpak-repo \
    build-dir \
    one.ahurein.reinplayer.yml

# Install into your user session for testing.
# (Pass an absolute path — some older flatpak versions reject relative ones.)
flatpak --user remote-add --no-gpg-verify --if-not-exists \
    reinplayer-local "$(realpath ../flatpak-repo)"
flatpak --user install -y reinplayer-local one.ahurein.reinplayer

# Run it
flatpak run one.ahurein.reinplayer

# Or export a single-file bundle to hand to a user
flatpak build-bundle ../flatpak-repo \
    ../ReinPlayer-1.1.0-x86_64.flatpak \
    one.ahurein.reinplayer
```

To install a `.flatpak` bundle on a fresh machine:

```bash
flatpak install --user ./ReinPlayer-1.1.0-x86_64.flatpak
flatpak run one.ahurein.reinplayer
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
| `--filesystem=host:ro` | Read-only access to the whole filesystem so users can open videos from anywhere. Drop to nothing and rely on the portal file chooser if you want a stricter sandbox; you'll lose drag-and-drop from `Files`. |
| `--filesystem=/run/media`, `/media`, `/mnt` | USB sticks and external drives — these paths sit outside `home`. |
| `--talk-name=org.freedesktop.ScreenSaver` (+ PowerManagement) | Inhibit screen sleep during playback. |
| `--own-name=org.mpris.MediaPlayer2.reinplayer` | MPRIS so GNOME / KDE media keys and the lock-screen widget can drive playback. |

### Tightening for Flathub

If you submit to Flathub, expect a reviewer to push back on `--filesystem=host:ro`.
The accepted alternative is to use the **file chooser portal** (Flutter's
`file_picker` package goes through xdg-desktop-portal automatically when
running in a Flatpak), and drop the broad filesystem permission. The trade-off
is that drag-and-drop from `Files` will only work for paths you already have
permission for.

---

## 8. Testing checklist

Before shipping, validate the build on a real Linux machine:

```bash
# Smoke test
flatpak run one.ahurein.reinplayer

# Drag a video file from Files / Nautilus onto the window
# Open a video via File menu — should use the portal file chooser
# Verify audio plays (pulse/pipewire)
# Verify hardware decode (check `vainfo` host-side, then play a 4K file)
# Verify the desktop entry appears in your launcher (after `update-desktop-database`)
# Verify the AppStream metainfo against the *source* file
# (the version that lives at /app/share/metainfo inside the sandbox isn't
# reachable from outside the app, so validate the source instead).
appstreamcli validate --pedantic dist/flatpak/one.ahurein.reinplayer.metainfo.xml
# Don't have appstreamcli on the host? Run it from the SDK against the source:
flatpak-builder --run build/flatpak/build-dir \
    dist/flatpak/one.ahurein.reinplayer.yml \
    appstreamcli validate --pedantic \
    /app/share/metainfo/one.ahurein.reinplayer.metainfo.xml

# Verify the desktop file (path is the installed location for a --user flatpak):
desktop-file-validate \
    ~/.local/share/flatpak/app/one.ahurein.reinplayer/current/active/files/share/applications/one.ahurein.reinplayer.desktop
```

Common red flags:

- **Black video, audio works** → missing `--device=dri` or driver mismatch
  between host and runtime. `glxinfo` lives in the SDK, not the runtime, so
  run it via the devel form:
  `flatpak run --devel --command=glxinfo one.ahurein.reinplayer | grep renderer`
  (or use `eglinfo`, which is present in the runtime).
- **`error while loading shared libraries: libmpv.so.2`** → wrapper script
  did not set `LD_LIBRARY_PATH`, or libmpv was not included in the bundle.
  Check `ls /app/lib/reinplayer/lib | grep mpv` from `flatpak run --command=sh one.ahurein.reinplayer`.
- **File picker opens but selection silently fails** → you're hitting the
  portal but the selected file lives somewhere the sandbox can't read. Either
  widen `--filesystem=` or rely on portal-mediated transient access (which
  Flutter's `file_picker` will do for you).
- **App icon missing in launcher** → the icon filename must exactly match the
  App ID, i.e. `one.ahurein.reinplayer.png`, installed under
  `/app/share/icons/hicolor/<size>/apps/`.

---

## 9. Versioning and releases

Source of truth is `pubspec.yaml` (`version: 1.1.0+2`). `dist/build.sh`
extracts the major.minor.patch portion and substitutes it into:

- the `<release>` element of the AppStream metainfo (the latest release
  becomes the current version, dated today)
- the output bundle filename

When you cut a new release:

1. Bump `pubspec.yaml`.
2. Add a new `<release>` entry at the **top** of the `<releases>` list in
   `dist/flatpak/one.ahurein.reinplayer.metainfo.xml`, with real changelog
   notes. The build script rewrites only the first `<release version="..."
   date="...">` element it finds (using awk, not sed-global), so any older
   entries below are preserved verbatim. If you forget to add a placeholder
   entry, you'll see a `warning: no <release ...> element found` from the
   build and the metainfo will ship with stale version info.
3. Tag the commit and let CI build a fresh `.flatpak` for the GitHub release.

---

## 10. Publishing to Flathub

Flathub is the de facto Linux app store. Submission is a separate repo on
their GitHub org.

### 10.1 Prepare a submission-grade manifest

Flathub has stricter rules than self-hosted Flatpaks. The biggest deltas:

1. **No prebuilt blobs.** Flathub builds everything from upstream sources
   inside their CI. For a Flutter app this means either:
   - Vendoring the Flutter SDK as a build module (very slow but pure), **or**
   - Using an "extra-data" pattern that downloads a release artifact at install
     time. Several Flutter apps on Flathub do this — see `dev.bnyro.tomato`
     or `io.github.zaedus.spider` for examples.
2. **`--filesystem=host` is normally rejected.** Use the portal file chooser
   and drop the broad permission.
3. **AppStream metainfo must validate cleanly** with
   `appstreamcli validate --strict --pedantic` (the legacy
   `appstream-util validate-strict` is also still accepted but is being phased
   out in favor of `appstreamcli`).
4. **Screenshots must be hosted on a stable URL** (Flathub will mirror them).
5. **No `grade: devel`** style markers — release builds only.

### 10.2 Submission procedure

```bash
# 1. Fork https://github.com/flathub/flathub
# 2. From the `new-pr` branch of your fork, add a directory:
#    one.ahurein.reinplayer/
#      ├── one.ahurein.reinplayer.yml      # submission-flavored manifest
#      └── flathub.json                    # CI config
# 3. Open a PR against flathub:new-pr
```

After the PR opens, Flathub's bot builds it on `x86_64` and `aarch64`, and
posts a download link to a test repo so reviewers can install it. Expect a
review cycle that focuses on permissions, metainfo correctness, and the
mechanism you use to ship binaries.

A skeleton `flathub.json`:

```json
{
  "only-arches": ["x86_64", "aarch64"]
}
```

---

## 11. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `error: org.freedesktop.Platform/x86_64/24.08 not installed` | runtime missing | `flatpak install --user flathub org.freedesktop.Platform//24.08` |
| `flatpak-builder: command not found` | builder missing | `sudo apt install flatpak-builder` (or distro equivalent) |
| `Failed to setup mount /newroot/dev/dri` on launch | running in a VM without DRI | add `--allow=devel` for testing, or run on bare metal |
| `appstream-glib: failed to validate` during build | metainfo error | run `appstreamcli validate --pedantic dist/flatpak/one.ahurein.reinplayer.metainfo.xml` and fix what it reports |
| `Permission denied` opening any file | over-tight sandbox | use the file chooser portal, or temporarily add `--filesystem=host` and re-test |
| App launches then crashes immediately | wrapper `LD_LIBRARY_PATH` wrong | `flatpak run --command=sh one.ahurein.reinplayer` then `ldd /app/lib/reinplayer/rein_player` |
| `Could not load shared library libmpv.so.2` | media_kit's libmpv wasn't copied | verify `build/linux/x64/release/bundle/lib/` is non-empty before running `build.sh flatpak` |
| MPRIS controls don't work | DBus name wrong | confirm `--own-name=org.mpris.MediaPlayer2.reinplayer` is in `finish-args` and the app actually registers it |

Useful debug commands:

```bash
# Drop into a shell inside the sandbox
flatpak run --command=sh one.ahurein.reinplayer

# Show the effective sandbox permissions
flatpak info --show-permissions one.ahurein.reinplayer

# Tail logs
journalctl --user -f -t flatpak-session-helper
```

---

## 12. CI recipe (GitHub Actions sketch)

The repo already has a custom Linux build container at
`ghcr.io/ahurein/flutter-gtk-mpv:latest` (defined in
`.github/DOCKER_GUIDE.md`). It inherits from `ghcr.io/cirruslabs/flutter:latest`
and adds `clang ninja-build cmake libgtk-3-dev libmpv-dev mpv` — i.e. Flutter
plus every Linux build dep our app needs. The existing `ci-fast.yaml` uses it
to produce the `.deb`. We can reuse it for Flatpak too; the only things it
doesn't have are `flatpak` and `flatpak-builder` themselves.

```yaml
name: flatpak
on:
  push:
    tags: ['v*']
jobs:
  build-linux-flatpak:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/ahurein/flutter-gtk-mpv:latest
      # flatpak-builder runs bubblewrap to set up user namespaces; that
      # requires CAP_SYS_ADMIN, which `--privileged` grants.
      options: --privileged
    steps:
      - uses: actions/checkout@v4

      # The image doesn't ship Flatpak tooling — install it here.
      # (Keep apt recommends: flatpak-builder pulls elfutils that way,
      # which it needs for debug-symbol extraction during export.)
      - name: Install Flatpak + flatpak-builder
        run: |
          apt-get update
          apt-get install -y flatpak flatpak-builder

      - name: Build Flutter Linux bundle
        run: |
          flutter pub get
          flutter build linux --release

      - name: Build Flatpak
        run: ./dist/build.sh flatpak

      - uses: actions/upload-artifact@v4
        with:
          name: reinplayer-flatpak
          path: build/ReinPlayer-*-x86_64.flatpak

      - name: Upload to GitHub release
        if: startsWith(github.ref, 'refs/tags/v')
        uses: svenstaro/upload-release-action@v2
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          file: build/ReinPlayer-*-x86_64.flatpak
          file_glob: true
          tag: ${{ github.ref }}
          overwrite: true
```

Notes:

- **`options: --privileged` is mandatory.** Without it `flatpak-builder`
  fails with `bwrap: setting up uid map: Permission denied` because it
  can't create user namespaces from inside an unprivileged container.
- **The container is Debian-based**, so `apt-get` is correct — no `sudo`
  (we're already root in the container) and no Fedora package names.
- **First-run cost.** `build.sh flatpak` will pull `org.freedesktop.Platform`
  and `org.freedesktop.Sdk` (~500 MB total) from Flathub on each run. Cache
  `~/.local/share/flatpak` between runs with `actions/cache@v4` keyed on the
  runtime version (`freedesktop-24.08`) if you want to keep the job under a
  minute.

### Want it even faster? Bake `flatpak-builder` into the image

If you'd rather not apt-install on every run, add two lines to the
`Dockerfile` documented in `.github/DOCKER_GUIDE.md`:

```dockerfile
RUN apt-get update && \
    apt-get install -y \
        flatpak flatpak-builder && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

Rebuild and push:

```bash
docker build -t ghcr.io/ahurein/flutter-gtk-mpv:latest .
docker push ghcr.io/ahurein/flutter-gtk-mpv:latest
```

Then drop the `Install Flatpak + flatpak-builder` step from the workflow.
Pre-pulling the freedesktop runtime inside the image would shave another
~30 s but adds ~500 MB to the image — usually not worth it.

---

## 13. Further reading

- Flatpak docs — <https://docs.flatpak.org/>
- Flathub submission guide — <https://docs.flathub.org/docs/for-app-authors/submission>
- AppStream metainfo reference — <https://www.freedesktop.org/software/appstream/docs/>
- xdg-desktop-portal — <https://flatpak.github.io/xdg-desktop-portal/>
- Flutter on Flathub example — <https://github.com/flathub/dev.bnyro.tomato>
