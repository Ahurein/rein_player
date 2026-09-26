#!/bin/bash
# Launcher for Rein Player inside the Flatpak sandbox.
# Adds the bundled lib/ directory to the loader path so the Flutter engine
# and bundled libmpv resolve at runtime, then execs the real binary.

set -e

APP_ROOT="/app/lib/reinplayer"
if [ -n "${LD_LIBRARY_PATH:-}" ]; then
    export LD_LIBRARY_PATH="${APP_ROOT}/lib:${LD_LIBRARY_PATH}"
else
    export LD_LIBRARY_PATH="${APP_ROOT}/lib"
fi

exec "${APP_ROOT}/rein_player" "$@"
