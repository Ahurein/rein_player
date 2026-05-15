#!/bin/bash

set -e

PLATFORM=$1
CURRENT_DIR="$(dirname "$0")"
PROJECT_DIR="${CURRENT_DIR}/.."

function extract_version() {
  local raw_version
  raw_version=$(grep "^version:" "${PROJECT_DIR}/pubspec.yaml" | awk '{print $2}' | tr -d '"')
  echo "${raw_version}" | sed 's/+.*//'
}

function validate_version() {
  local version="$1"
  if ! [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format: ${version}"
    exit 1
  fi
}

function build_deb_package() {
    PACKAGE_DIR="${PROJECT_DIR}/build/deb_package"
    rm -rf "${PACKAGE_DIR}"
    VERSION="$(extract_version)"
    validate_version "${VERSION}"
    sed -i "s/^Version:.*/Version: ${VERSION}/" "${CURRENT_DIR}/deb/DEBIAN/control"
    cp -fr "${CURRENT_DIR}/deb/." "${PACKAGE_DIR}"
    mkdir -p "${PACKAGE_DIR}/usr/bin"
    mkdir -p "${PACKAGE_DIR}/usr/lib/reinplayer"
    for library in "${PROJECT_DIR}/build/linux/x64/release/bundle/lib/"*.so; do
      strip "$library"
    done
    cp -fr "${PROJECT_DIR}/build/linux/x64/release/bundle/." "${PACKAGE_DIR}/usr/lib/reinplayer"
    ln -sf "../lib/reinplayer/rein_player" "${PACKAGE_DIR}/usr/bin/reinplayer"
    dpkg-deb --build --root-owner-group "${PACKAGE_DIR}" "${PROJECT_DIR}/build/reinplayer_${VERSION}_linux_amd64.deb"
}

function build_snap_package() {
    PACKAGE_DIR="${CURRENT_DIR}/snap/rein_player"
    rm -rf "${PACKAGE_DIR}"
    VERSION="$(extract_version)"
    validate_version "${VERSION}"
    mkdir -p "${PACKAGE_DIR}"
    sed -i "s/^version:.*/version: ${VERSION}/" "${CURRENT_DIR}/snap/snap/snapcraft.yaml"
    cp -fr "${PROJECT_DIR}/build/linux/x64/release/bundle/." "${PACKAGE_DIR}"
    # Copy GUI files to the package directory
    mkdir -p "${PACKAGE_DIR}/gui"
    cp "${CURRENT_DIR}/snap/snap/gui/reinplayer.desktop" "${PACKAGE_DIR}/gui/"
    cp "${CURRENT_DIR}/snap/snap/gui/reinplayer.png" "${PACKAGE_DIR}/gui/"
    for library in "${PACKAGE_DIR}/lib/"*.so; do
        strip "$library"
    done
    echo "Snap package prepared. The snapcraft build will include version ${VERSION} in the filename."
}

function build_appimage_package() {
    APP_IMAGE_TOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    PACKAGE_DIR="${PROJECT_DIR}/build/ReinPlayer.AppDir"
    VERSION="$(extract_version)"
    validate_version "${VERSION}"
    if ! command -v appimagetool &> /dev/null; then
      wget -O appimagetool "${APP_IMAGE_TOOL_URL}"
      chmod +x appimagetool
      mv appimagetool /usr/local/bin/appimagetool
    fi
    rm -rf "${PACKAGE_DIR}"
    cp -fr "${CURRENT_DIR}/appimage/." "${PACKAGE_DIR}"
    cp -fr "${PROJECT_DIR}/build/linux/x64/release/bundle/." "${PACKAGE_DIR}"
    mv "${PACKAGE_DIR}/rein_player" "${PACKAGE_DIR}/reinplayer"
    for library in "${PACKAGE_DIR}/lib/"*.so; do
        strip "$library"
    done
    appimagetool "${PACKAGE_DIR}"
    mv "./ReinPlayer-x86_64.AppImage" "${PROJECT_DIR}/build/ReinPlayer-${VERSION}-x86_64.AppImage"
}
function build_flatpak_package() {
    PACKAGE_DIR="${PROJECT_DIR}/build/flatpak"
    PAYLOAD_DIR="${PACKAGE_DIR}/payload"
    REPO_DIR="${PROJECT_DIR}/build/flatpak-repo"
    BUNDLE_OUT="${PROJECT_DIR}/build"
    APP_ID="one.ahurein.reinplayer"
    VERSION="$(extract_version)"
    validate_version "${VERSION}"

    # Flatpak only builds on Linux.
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "Error: Flatpak builds require Linux (detected $(uname -s))."
        echo "Use a Linux VM, container, or CI runner."
        exit 1
    fi

    # Cross-check: Flathub rejects apps whose GTK application-id doesn't match
    # the Flatpak App ID. Warn loudly if the runner is still on the default.
    LINUX_APP_ID="$(grep -E '^set\(APPLICATION_ID' "${PROJECT_DIR}/linux/CMakeLists.txt" \
        | sed -E 's/.*"([^"]+)".*/\1/')"
    if [[ "${LINUX_APP_ID}" != "${APP_ID}" ]]; then
        echo "warning: linux/CMakeLists.txt APPLICATION_ID is '${LINUX_APP_ID}'"
        echo "         but the Flatpak App ID is '${APP_ID}'."
        echo "         Flathub will reject this mismatch — change APPLICATION_ID"
        echo "         to '${APP_ID}' before submission."
    fi

    if ! command -v flatpak-builder &> /dev/null; then
        echo "Error: flatpak-builder is not installed."
        echo "  Ubuntu/Debian: sudo apt install flatpak flatpak-builder"
        echo "  Fedora:        sudo dnf install flatpak flatpak-builder"
        echo "  Arch:          sudo pacman -S flatpak flatpak-builder"
        exit 1
    fi

    # Ensure required runtimes are present from Flathub.
    flatpak remote-add --if-not-exists --user flathub \
        https://flathub.org/repo/flathub.flatpakrepo
    flatpak install --user --noninteractive flathub \
        org.freedesktop.Platform//24.08 \
        org.freedesktop.Sdk//24.08

    # Stage manifest + supporting files
    rm -rf "${PACKAGE_DIR}"
    mkdir -p "${PAYLOAD_DIR}/icons"
    cp "${CURRENT_DIR}/flatpak/one.ahurein.reinplayer.yml"            "${PACKAGE_DIR}/"
    cp "${CURRENT_DIR}/flatpak/one.ahurein.reinplayer.desktop"        "${PAYLOAD_DIR}/"
    cp "${CURRENT_DIR}/flatpak/one.ahurein.reinplayer.metainfo.xml"   "${PAYLOAD_DIR}/"
    cp "${CURRENT_DIR}/flatpak/reinplayer.sh"                         "${PAYLOAD_DIR}/"

    # Stamp version + release date into the FIRST <release> element only,
    # preserving any older entries below it. (sed would rewrite all of them.)
    TODAY="$(date -u +%Y-%m-%d)"
    METAINFO="${PAYLOAD_DIR}/one.ahurein.reinplayer.metainfo.xml"
    awk -v ver="${VERSION}" -v today="${TODAY}" '
        !done && match($0, /<release[[:space:]]+version="[^"]*"[[:space:]]+date="[^"]*">/) {
            prefix = substr($0, 1, RSTART - 1)
            suffix = substr($0, RSTART + RLENGTH)
            print prefix "<release version=\"" ver "\" date=\"" today "\">" suffix
            done = 1
            next
        }
        { print }
        END {
            if (!done) {
                print "warning: no <release version=\"...\" date=\"...\"> element found to stamp" > "/dev/stderr"
            }
        }
    ' "${METAINFO}" > "${METAINFO}.tmp" && mv "${METAINFO}.tmp" "${METAINFO}"

    # Copy the prebuilt hicolor icons. The macOS asset catalog ships icons
    # at every size we want, designed from a single source so they look
    # consistent across launcher render sizes.
    ICON_SRC="${PROJECT_DIR}/macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for size in 64 128 256 512; do
        if [[ ! -f "${ICON_SRC}/app_icon_${size}.png" ]]; then
            echo "Error: icon source not found at ${ICON_SRC}/app_icon_${size}.png"
            exit 1
        fi
        mkdir -p "${PAYLOAD_DIR}/icons/${size}x${size}"
        cp "${ICON_SRC}/app_icon_${size}.png" \
            "${PAYLOAD_DIR}/icons/${size}x${size}/icon.png"
    done

    # Copy the Flutter Linux bundle into the payload
    if [[ ! -d "${PROJECT_DIR}/build/linux/x64/release/bundle" ]]; then
        echo "Error: Flutter Linux bundle not found."
        echo "Run: flutter build linux --release"
        exit 1
    fi
    mkdir -p "${PAYLOAD_DIR}/bundle"
    cp -fr "${PROJECT_DIR}/build/linux/x64/release/bundle/." "${PAYLOAD_DIR}/bundle/"
    for library in "${PAYLOAD_DIR}/bundle/lib/"*.so; do
        [[ -e "$library" ]] && strip "$library" || true
    done

    # Build and export the Flatpak
    rm -rf "${REPO_DIR}" "${PACKAGE_DIR}/.flatpak-builder" "${PACKAGE_DIR}/build-dir"
    (
        cd "${PACKAGE_DIR}"
        flatpak-builder --user --force-clean \
            --repo="${REPO_DIR}" \
            build-dir \
            one.ahurein.reinplayer.yml
    )

    BUNDLE_FILE="${BUNDLE_OUT}/ReinPlayer-${VERSION}-x86_64.flatpak"
    flatpak build-bundle "${REPO_DIR}" "${BUNDLE_FILE}" "${APP_ID}"
    echo "Flatpak bundle written to: ${BUNDLE_FILE}"
}

function build_dmg_package() {
    VERSION="$(extract_version)"
    validate_version "${VERSION}"

    APP_PATH="${PROJECT_DIR}/build/macos/Build/Products/Release/rein_player.app"
    OUTPUT_DIR="${PROJECT_DIR}/dist/dmg"
    DMG_NAME="ReinPlayer-v${VERSION}.dmg"
    DMG_PATH="${OUTPUT_DIR}/${DMG_NAME}"

    # Make sure output dir exists
    mkdir -p "${OUTPUT_DIR}"

    # Check if create-dmg is installed
    if ! command -v create-dmg &> /dev/null; then
        echo "'create-dmg' not found. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install create-dmg
        else
            echo "Homebrew not found. Please install create-dmg manually."
            exit 1
        fi
    fi

    # Prepare a staging folder that contains the app bundle for the DMG
    STAGING_DIR="${OUTPUT_DIR}/staging"
    rm -rf "${STAGING_DIR}"
    mkdir -p "${STAGING_DIR}"
    cp -R "${APP_PATH}" "${STAGING_DIR}/"

    # Remove old DMG if exists
    if [ -f "${DMG_PATH}" ]; then
        echo "Removing existing DMG: ${DMG_PATH}"
        rm "${DMG_PATH}"
    fi

    echo "Creating DMG ${DMG_NAME}..."

    create-dmg \
        --volname "Rein Player" \
        --icon "rein_player.app" 200 190 \
        --app-drop-link 600 185 \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --hide-extension "rein_player.app" \
        "${DMG_PATH}" \
        "${STAGING_DIR}"

    echo "DMG created at: ${DMG_PATH}"
}

# Dispatch by platform
if [[ "$PLATFORM" == "deb" ]]; then
  build_deb_package
elif [[ "$PLATFORM" == "snap" ]]; then
  build_snap_package
elif [[ "$PLATFORM" == "appimage" ]]; then
  build_appimage_package
elif [[ "$PLATFORM" == "flatpak" ]]; then
  build_flatpak_package
elif [[ "$PLATFORM" == "macos" ]]; then
  build_dmg_package
else
  echo "Unknown platform: $PLATFORM"
  exit 1
fi