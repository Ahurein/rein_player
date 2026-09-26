# ReinPlayer 🎬

**A modern, intuitive video player for Linux inspired by PotPlayer.**

![ReinPlayer Display Image](assets/images/reinplayer_view.png)

---

## 🚀 Introduction

### Why ReinPlayer?

As a developer transitioning fully to Linux, I faced a surprising barrier: my favorite tools weren't available. Two of them kept me tied to Windows:

- Internet Download Manager (IDM)
- PotPlayer

I eventually found a good alternative to IDM, but PotPlayer remained unmatched. Tools like VLC and SMPlayer are powerful, yet they lack the seamless and intuitive experience PotPlayer offers, especially with playlist management.

#### Key Missing Features in Other Players:

- Playlists are saved as files and don't persist between sessions.
- Doesn't auto-load all similar files in a folder when opening a video (e.g., play next episode automatically)
- Must manually open playlist files, unlike PotPlayer's built-in view.
- Doesn't resume playback from the last played video
- Interfaces can feel clunky or unintuitive etc

I decided to build only what I need. **ReinPlayer** captures the essential experience I missed on Linux.

---

## 🛠️ Solutions I Explored

Before building ReinPlayer, I attempted a few alternatives:

- Searched for Linux players with similar playlist behavior.
- Tried installing PotPlayer with Wine.
- Attempted Steam-based installation (unsuccessful due to constant crashes).

---

## 💡 Why Flutter?

With a background in **Java** and **C#**, you might ask why I chose Flutter over something like Avalonia or JavaFX.

The answer is simple: I plan to build cross-platform mobile apps in the future, and Flutter is my tool of choice. ReinPlayer was a perfect opportunity to deepen my Flutter experience.

---

## 🧩 Architecture

ReinPlayer follows the **MVVM** architecture along with a hybrid **feature + layered** approach.

- `common` – Shared widgets, logic, helpers.
- `playback` – Playback screen, video/audio controls.
- `playlist` – Album and playlist management.
- `settings` – User preferences and configuration.
- `player_frame` – Window actions (minimize, maximize, fullscreen, etc.)
- `developer` – Developer tools and logs.

📚 Read more about the architecture here: [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide)

---

## 🎉 What's New in v1.1.0

This release brings powerful new features and significant improvements:

- 🎯 **Context-Aware Keyboard Shortcuts** - Arrow keys intelligently switch between player and playlist control
- 🔖 **Bookmark Management** - Save and navigate multiple timestamps per video
- 🔁 **A-B Loop Segments** - PotPlayer-compatible loop system for practice and learning
- 👁️ **Seek Preview** - Visual timestamp overlay when seeking
- 🎨 **Enhanced Subtitle Customization** - Full control over fonts, colors, and positioning
- ⏯️ **Resume Playback** - Pick up right where you left off with timestamp memory
- 🍎 **macOS Enhancements** - Set as default player, improved Finder integration
- 📋 **Rich Playlist Context Menu** - Delete, copy, show in file manager, and more
- ⚙️ **Global Keyboard Shortcuts Toggle** - Enable/disable all shortcuts instantly

[View Full Changelog →](CHANGELOG.md)

---

## ⚙️ Features

### 🖥️ Player

- Modern, intuitive UI with right-click context menu
- Supports all FFmpeg-compatible video formats ([see full list](https://www.ffmpeg.org/general.html#Video-Codecs))
- Context-aware keyboard shortcuts - Arrow keys dynamically control volume/seeking (player mode) or navigate playlist (playlist mode) based on focus
- Customizable keyboard shortcuts with visual configuration interface:

| Default Key         | Action                        | Customizable |
| ------------------- | ----------------------------- | ------------ |
| Spacebar            | Pause / Play                  | ✅           |
| m                   | Mute / Unmute                 | ✅           |
| Ctrl + h            | Show / Hide Subtitles         | ✅           |
| Esc                 | Exit Fullscreen               | ✅           |
| Enter               | Enter Fullscreen              | ✅           |
| Right Arrow         | Seek Forward                  | ✅           |
| Left Arrow          | Seek Backward                 | ✅           |
| Shift + Right Arrow | Big Seek Forward              | ✅           |
| Shift + Left Arrow  | Big Seek Backward             | ✅           |
| Up Arrow            | Volume Up                     | ✅           |
| Down Arrow          | Volume Down                   | ✅           |
| Ctrl + b            | Add Bookmark                  | ✅           |
| b                   | Jump to Next Bookmark         | ✅           |
| Shift + b           | Jump to Previous Bookmark     | ✅           |
| Ctrl + Shift + b    | Toggle Bookmark List          | ✅           |
| Ctrl + p            | Toggle Playlist               | ✅           |
| Ctrl + l            | Add A-B Loop Segment          | ✅           |
| l                   | Toggle A-B Loop Overlay       | ✅           |
| Ctrl + Shift + l    | Start/Stop A-B Loop Playback  | ✅           |
| [                   | Jump to Previous A-B Segment  | ✅           |
| ]                   | Jump to Next A-B Segment      | ✅           |
| Ctrl + Shift + e    | Export A-B Loops to PBF File  | ✅           |
| Ctrl + k            | Toggle Keyboard Bindings      | ✅           |
| Ctrl + d            | Toggle Developer Log          | ✅           |
| x                   | Decrease Playback Speed       | ✅           |
| c                   | Increase Playback Speed       | ✅           |
| Page Up             | Goto Previous Video           | ✅           |
| Page Down           | Goto Next Video               | ✅           |
| Shift + Delete      | Delete Video and Skip to Next | ✅           |
| s                   | Shuffle Playlist              | ✅           |

- Enhanced fullscreen mode with edge-hover menu display and auto-hide functionality
- Mouse wheel volume control - scroll over video to adjust volume
- Window actions (Always-on-top, minimize, maximize, fullscreen, close)
- Player controls: Play, Pause, Stop, Open, Next, Previous
- Drag-and-drop support for files and folders
- Playlist panel with folder highlighting for current video path
- Right-click context menu with quick access to settings and features
- Settings menu with customizable preferences
- Seek preview overlay - Visual timestamp preview when seeking through video
- Configurable seek intervals:
  - Adaptive mode: Percentage-based seeking (1% and 5% default)
  - Fixed mode: Fixed seconds seeking (5s and 30s default)
  - Customize both regular and big seek values
  - Tooltip shows time info during seek operations
- Enhanced volume control (0-200%) with persistent settings - Because my PC speakers are not that loud 🤣
- Integrate with GNOME to show as default video player if installed with the install script
- Command-line interface support:
  - `reinplayer --version` or `-v`: Display version information
  - `reinplayer --help` or `-h`: Show help and usage information
  - `reinplayer <file>`: Open and play a video file directly
- About dialog accessible from right-click menu showing version, description, and GitHub link
- Configurable double-click behavior:
  - Maximize/Minimize window (default)
  - Play/Pause video (PotPlayer style)

---

### 🎵 Audio & Subtitles

- Multi-audio track support with automatic detection and manual selection
- Audio track switching via context menu or settings
- Auto-load subtitles from the same folder as the video
- Manual subtitle loading (SRT, VTT formats)
- Enable / Disable subtitles with customizable shortcuts
- **Comprehensive subtitle customization**:
  - Font family selection (12+ fonts available)
  - Adjustable font size (8-72pt)
  - Position controls (Up/Down/Left/Right)
  - Text alignment options (left, center, right)
  - Text and background color pickers
  - Adjustable outline width
  - Real-time preview
  - Settings persist across sessions

---

### 🎵 Playlist

- Create and manage playlists with configurable playlist types:
  - Default: Standard playlist behavior
  - PotPlayer Style: Mimics PotPlayer's playlist behavior
- Persistent playlists without needing to save/import manually
- Resume playback from the last played video
- Auto-load all videos in a dropped folder into a default album
- Auto-load all similar files in a folder when opening a video (e.g., play next episode automatically)
- Smart folder highlighting - folders containing the current video are highlighted for easy navigation
- Natural sorting for better file organization
- Shuffle playlist - Randomize playlist order via keyboard shortcut (S) or context menu
- Delete & Skip - Quickly delete current video permanently and skip to next
- Rich context menu - Right-click playlist items for quick actions:
  - Delete from disk
  - Copy file path
  - Show in Finder/Nautilus/File Explorer
  - Get file properties
  - Remove from playlist
- Configurable playlist load behavior:
  - Clear and Replace: New files clear the playlist (default)
  - Append to Existing: New files are added to current playlist
- Configurable playlist end behavior:
  - Show Home Screen: Display ReinPlayer logo on black background when playlist ends (default)
  - Shutdown Application: Automatically close the app when playlist ends
- Video duration display with lazy loading and auto-formatting (MM:SS or HH:MM:SS)

---

### 🔖 Bookmarks

- Save multiple timestamps per video with custom names
- Quick navigation between bookmarks using keyboard shortcuts
- Persistent bookmarks that survive app restarts
- Visual bookmark manager overlay
- Bookmark actions available via context menu and keyboard:
  - Add bookmark at current position (Ctrl+B)
  - Jump to next bookmark (B)
  - Jump to previous bookmark (Shift+B)
  - Toggle bookmark list overlay (Ctrl+Shift+B)
- Edit bookmark names inline
- Delete individual or clear all bookmarks
- Automatic sorting by timestamp
- Wrap-around navigation (loops to first/last)

---

### 🔁 A-B Loop Segments (PBF Support)

**Advanced practice tool with full PotPlayer compatibility!**

- **PotPlayer Bookmark File (.pbf) support**:
  - Auto-load .pbf files when opening videos
  - Import existing PotPlayer bookmark files
  - Export segments back to .pbf format (fully compatible)
- **Create multiple A-B loop segments per video**:
  - Set start time and duration for each segment
  - Configure loop count (how many times to repeat)
  - Optional repeat delay (pause between loops)
  - Add titles/labels to organize segments
- **Intelligent playback engine**:
  - Automatically loops each segment the specified number of times
  - Moves to next segment after completing all loops
  - Wraps around to first segment when sequence completes
  - Pause on last frame between loops (configurable delay)
- **Full CRUD operations**:
  - Create segments with configuration modal
  - Edit existing segments (all parameters)
  - Delete individual or clear all segments
  - Visual segment manager overlay
- **Perfect for**:
  - Language learning (loop dialogue sections)
  - Music practice (repeat difficult passages)
  - Dance/choreography (master specific moves)
  - Sports analysis (study techniques frame-by-frame)
  - Any scenario requiring repeated playback
- **Coexists with simple bookmarks** - use both features independently
- All segments persist between sessions and sync with storage

---

### ⚙️ Customization

- Custom keyboard bindings - reassign any shortcut to your preference
- Global keyboard shortcuts toggle - enable/disable all shortcuts with one click
- Playlist type configuration - choose between Default and PotPlayer-style behavior
- Playlist load behavior - choose between clearing or appending when loading files
- Playlist end behavior - choose between showing home screen or shutting down when playlist ends
- Double-click action - choose between window maximize/minimize or play/pause
- Seek interval preferences - choose between adaptive (percentage) or fixed (seconds) seeking
- Volume preferences - enhanced 0-200% volume range with persistent settings
- Subtitle preferences - auto-enable/disable settings
- All settings are automatically saved and restored between sessions

---

## 🎯 Challenges & Future Improvements

### Challenges Overcome

- **Packaging Complexity**: Working on packaging for Flatpak - work in progress

- **Menu Architecture**: Implementing a player menu with unlimited nesting capability required significant effort. While the current implementation supports unlimited depth, there's still room for optimization and refinement.
- **Cross-platform Compatibility**: Successfully added macOS build support alongside existing Linux and Windows support.
- I'm not a professional Flutter developer, so I'm sure there are many things that could be improved.

### Current Challenges

**Code**

- As a personal project, documentation wasn't the primary focus
- Code could benefit from:
  - A lot of refactoring 😂
  - Better documentation of complex logic
  - Clearer naming conventions
  - Additional inline documentation

## 📦 Downloads

All builds are available in the [releases page](https://github.com/Ahurein/rein_player/releases).

### 🔥 Recommended Installation

**Snap Package (Recommended)**

- ✅ Easy installation
- ✅ Sandboxed security
- ✅ All dependencies included
- ✅ Automatic desktop integration

| Version | Format                                   | Download URL                                                       |
| ------- | ---------------------------------------- | ------------------------------------------------------------------ |
| v1.1.0  | Snap, Windows, macOS, Debian, Portable | [GitHub Releases](https://github.com/Ahurein/rein_player/releases) |

Download player icon: [Download](https://github.com/Ahurein/rein_player/raw/main/assets/images/reinplayer.png)

![ReinPlayer Icon](assets/images/reinplayer.png)

### ✅ Supported Platforms

| OS          | Supported | Notes                                                                                          |
| ----------- | --------- | ---------------------------------------------------------------------------------------------- |
| **Linux**   | ✅        | Fully supported                                                                                |
| **Windows** | ✅        | Fully supported (But honestly use PotPlayer instead unless you are just trying out ReinPlayer) |
| **macOS**   | ✅        | Fully supported with native builds, default player integration, and Finder support             |
| **Android** | ❌        | Not supported – designed for desktop use                                                       |
| **iOS**     | ❌        | Not supported – designed for desktop use                                                       |

---

## 💻 Command-Line Usage

ReinPlayer supports standard CLI flags for version information and help:

```bash
# Display version information
reinplayer --version
reinplayer -v

# Show help and usage information
reinplayer --help
reinplayer -h

# Play a video file
reinplayer /path/to/video.mp4
reinplayer ~/Videos/movie.mkv
```

**Example output:**

```bash
$ reinplayer --version
ReinPlayer 1.1.0
A modern video player for Linux and macOS

Repository: https://github.com/Ahurein/rein_player
```

---

## 📥 Installation Guide

### 🥇 Method 1: Snap Package (Recommended)

**Download the snap file from the release page and install from local file:**

```bash
sudo snap install --dangerous reinplayer_linux_amd64.snap
```

**Benefits:**

- ✅ All dependencies included
- ✅ Sandboxed security
- ✅ Perfect desktop integration
- ✅ No additional setup required

---

### 🥈 Method 2: Debian Package

**For other installation methods (Portable or Debian), sometimes you need to install these dependencies first:**

```bash
sudo apt install zenity libmpv-dev libmpv2

# Create compatibility symlinks (choose one that works for your system)
sudo ln -s /usr/lib/x86_64-linux-gnu/libmpv.so.2 /usr/lib/x86_64-linux-gnu/libmpv.so.1
# OR
sudo ln -s /usr/lib/x86_64-linux-gnu/libmpv.so /usr/lib/libmpv.so.1
```

**Then install package:**

```bash
sudo dpkg -i reinplayer_linux_amd64.deb
sudo apt-get install -f  # Fix any dependency issues
```

---

### 🥉 Method 3: Portable Bundle

**Install dependencies first (Linux only):**

```bash
sudo apt install zenity libmpv-dev libmpv2

# Create compatibility symlinks
sudo ln -s /usr/lib/x86_64-linux-gnu/libmpv.so.2 /usr/lib/x86_64-linux-gnu/libmpv.so.1
# OR
sudo ln -s /usr/lib/x86_64-linux-gnu/libmpv.so /usr/lib/libmpv.so.1
```

**Then extract and run:**

```bash
tar -xzf reinplayer_linux_amd64_portable.tar.gz
cd reinplayer_linux_amd64_portable
./rein_player
```

---

### Method 4: Flatpak Bundle

Download the `.flatpak` file from the release page, then install it with:

```bash
flatpak install --user ./ReinPlayer-1.1.0-x86_64.flatpak
flatpak install --user flathub org.freedesktop.Platform.GL.default//26.08
flatpak run com.reinplayer.ReinPlayer
```

The GL extension is required for Flutter rendering on Intel/AMD systems and
may not be downloaded with the app. See [Flatpak troubleshooting](docs/FLATPAK.md#11-troubleshooting)
if the window reports a pixel format error or you use NVIDIA graphics.

---

### 🗑️ Uninstall

**Snap:**

```bash
sudo snap remove reinplayer
```

**Debian Package:**

```bash
sudo apt remove reinplayer
```

---

### ⚠️ Troubleshooting

1. **Install missing packages (Linux):**

   ```bash
   sudo apt update
   sudo apt install libmpv2 libmpv-dev zenity
   ```

2. **macOS Security**: If macOS blocks the app, go to System Preferences > Security & Privacy and allow the application to run.

**Note:** Snap package users don't need any additional setup - all dependencies are included!

---

## 🤝 Contributing

Although this started as a personal project, contributions are welcome! Whether it's a bug fix, UI improvement, or new feature — feel free to open a PR or issue.

---

## 📧 Contact

Have suggestions or want to collaborate? Reach out via [LinkedIn](https://www.linkedin.com/in/ebenezer-ahurein/)
