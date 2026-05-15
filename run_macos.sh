#!/usr/bin/env bash
set -e

MODE="${1:-first}"
CLEAN="${CLEAN:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

if [ ! -f "$REPO_DIR/compute_nearest_dna.cpp" ] && [ -f "$REPO_DIR/../compute_nearest_dna.cpp" ]
then
    REPO_DIR="$(cd "$REPO_DIR/.." && pwd)"
fi

if [ ! -f "$REPO_DIR/compute_nearest_dna.cpp" ]
then
    echo "ERROR: this script must be run from the DiffusiveCohesin repository."
    echo "Expected to find compute_nearest_dna.cpp."
    exit 1
fi

LOCAL_DIR="$REPO_DIR/.lammps_local"
LAMMPS_DIR="$LOCAL_DIR/lammps-22Jul2025"
BUILD_DIR="$LAMMPS_DIR/build_serial"
LAMMPS_EXE="$BUILD_DIR/lmp_serial"

check_input_files() {
    cd "$REPO_DIR"

    for f in F0.005_600_604.data in.flow_328678_DD14p5_MD14p5.lam in.flow_328701_DD14p5_MD14p5.lam in.flow_328708_DD14p5_MD14p5.lam in.flow_329079_DD14p5_MD24p5.lam compute_nearest_dna.cpp compute_nearest_dna.h pair_morse_dynamic_window.cpp pair_morse_dynamic_window.h
    do
        if [ ! -f "$f" ]
        then
            echo "ERROR: required file is missing: $f"
            exit 1
        fi
    done
}

check_macos_tools() {
    echo "Checking macOS Command Line Tools..."

    if ! xcode-select -p >/dev/null 2>&1
    then
        echo "macOS Command Line Tools are not installed."
        echo "The installer will open now. After installation finishes, run this command again."
        xcode-select --install
        exit 1
    fi

    echo "Checking Homebrew..."

    if [ -x /opt/homebrew/bin/brew ]
    then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if ! command -v brew >/dev/null 2>&1
    then
        if [ -x /usr/local/bin/brew ]
        then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    if ! command -v brew >/dev/null 2>&1
    then
        echo "Homebrew was not found. Installing Homebrew now..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if [ -x /opt/homebrew/bin/brew ]
    then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if ! command -v brew >/dev/null 2>&1
    then
        if [ -x /usr/local/bin/brew ]
        then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    if ! command -v brew >/dev/null 2>&1
    then
        echo "ERROR: Homebrew is still not available. Open a new Terminal window and run this script again."
        exit 1
    fi

    export HOMEBREW_NO_INSTALL_CLEANUP=1
    export HOMEBREW_NO_ENV_HINTS=1

    if ! command -v git >/dev/null 2>&1
    then
        brew install git
    fi

    if ! command -v cmake >/dev/null 2>&1
    then
        brew install cmake
    fi

    echo "git version:"
    git --version

    echo "cmake version:"
    cmake --version | head -n 1
}

build_lammps() {
    echo "Building serial LAMMPS stable_22Jul2025..."

    rm -rf "$LAMMPS_DIR"
    mkdir -p "$LOCAL_DIR"

    git clone --depth 1 --branch stable_22Jul2025 https://github.com/lammps/lammps.git "$LAMMPS_DIR"

    cp "$REPO_DIR/compute_nearest_dna.cpp" "$LAMMPS_DIR/src/"
    cp "$REPO_DIR/compute_nearest_dna.h" "$LAMMPS_DIR/src/"
    cp "$REPO_DIR/pair_morse_dynamic_window.cpp" "$LAMMPS_DIR/src/"
    cp "$REPO_DIR/pair_morse_dynamic_window.h" "$LAMMPS_DIR/src/"

    cmake -S "$LAMMPS_DIR/cmake" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DBUILD_MPI=no -DBUILD_OMP=no -DPKG_MOLECULE=yes -DLAMMPS_MACHINE=serial

    NCPU="$(sysctl -n hw.ncpu 2>/dev/null || echo 8)"

    case "$NCPU" in
        ''|*[!0-9]*)
            NCPU=8
            ;;
    esac

    if [ "$NCPU" -ge 8 ]
    then
        BUILD_JOBS=8
    else
        BUILD_JOBS="$NCPU"
    fi

    if [ "$BUILD_JOBS" -lt 1 ]
    then
        BUILD_JOBS=1
    fi

    echo "Detected CPU count: $NCPU"
    echo "Using build jobs: $BUILD_JOBS"

    cmake --build "$BUILD_DIR" -j "$BUILD_JOBS"
}

check_lammps_styles() {
    if [ ! -x "$LAMMPS_EXE" ]
    then
        echo "ERROR: LAMMPS executable was not created:"
        echo "$LAMMPS_EXE"
        exit 1
    fi

    HELP_FILE="$LOCAL_DIR/lammps_serial_help.txt"
    "$LAMMPS_EXE" -h > "$HELP_FILE" 2>&1

    if ! grep -q "morse/dynamic_window" "$HELP_FILE"
    then
        echo "ERROR: pair_style morse/dynamic_window was not found in the compiled LAMMPS executable."
        echo "Check this file: $HELP_FILE"
        exit 1
    fi

    if ! grep -q "nearest/dna" "$HELP_FILE"
    then
        echo "ERROR: compute nearest/dna was not found in the compiled LAMMPS executable."
        echo "Check this file: $HELP_FILE"
        exit 1
    fi

    echo "Custom LAMMPS styles found successfully."
}

ensure_lammps() {
    if [ "$CLEAN" = "1" ]
    then
        echo "CLEAN=1 was set. Removing local LAMMPS build."
        rm -rf "$LOCAL_DIR"
    fi

    if [ ! -x "$LAMMPS_EXE" ]
    then
        build_lammps
    else
        echo "Using existing LAMMPS executable:"
        echo "$LAMMPS_EXE"
    fi

    check_lammps_styles
}

prepare_run_dir() {
    RUN_DIR="$1"
    mkdir -p "$RUN_DIR"
    mkdir -p "$RUN_DIR/logs"

    cp "$REPO_DIR/F0.005_600_604.data" "$RUN_DIR/"
    cp "$REPO_DIR/in.flow_328678_DD14p5_MD14p5.lam" "$RUN_DIR/"
    cp "$REPO_DIR/in.flow_328701_DD14p5_MD14p5.lam" "$RUN_DIR/"
    cp "$REPO_DIR/in.flow_328708_DD14p5_MD14p5.lam" "$RUN_DIR/"
    cp "$REPO_DIR/in.flow_329079_DD14p5_MD24p5.lam" "$RUN_DIR/"
}

run_first() {
    RUN_ID="$(date +%Y%m%d_%H%M%S)"
    RUN_DIR="$REPO_DIR/runs/first_flow_328678_DD14p5_MD14p5_$RUN_ID"
    INPUT_FILE="in.flow_328678_DD14p5_MD14p5.lam"
    LOG_FILE="$RUN_DIR/logs/in.flow_328678_DD14p5_MD14p5.full.log"

    prepare_run_dir "$RUN_DIR"
    cd "$RUN_DIR"

    echo "Running first full simulation on one CPU core."
    echo "Run directory: $RUN_DIR"
    echo "LAMMPS executable: $LAMMPS_EXE"
    echo "LAMMPS log file: $LOG_FILE"
    echo "LAMMPS output will be printed directly in this Terminal."

    set +e
    "$LAMMPS_EXE" -in "$INPUT_FILE" -log "$LOG_FILE"
    LAMMPS_STATUS="$?"
    set -e

    echo "LAMMPS exit status: $LAMMPS_STATUS"

    if [ -f "$LOG_FILE" ]
    then
        echo "Last 60 lines of the LAMMPS log file:"
        tail -n 60 "$LOG_FILE"
    fi

    echo "Generated dump files:"
    find "$RUN_DIR" -maxdepth 1 -name 'dump.*.all' -print

    if [ "$LAMMPS_STATUS" -ne 0 ]
    then
        echo "ERROR: LAMMPS simulation did not finish successfully."
        exit "$LAMMPS_STATUS"
    fi

    echo "Simulation finished successfully."
}

run_all4() {
    RUN_ID="$(date +%Y%m%d_%H%M%S)"
    RUN_DIR="$REPO_DIR/runs/parallel4_$RUN_ID"
    prepare_run_dir "$RUN_DIR"
    cd "$RUN_DIR"

    INPUT1="in.flow_328678_DD14p5_MD14p5.lam"
    INPUT2="in.flow_328701_DD14p5_MD14p5.lam"
    INPUT3="in.flow_328708_DD14p5_MD14p5.lam"
    INPUT4="in.flow_329079_DD14p5_MD24p5.lam"

    BASE1="${INPUT1%.lam}"
    BASE2="${INPUT2%.lam}"
    BASE3="${INPUT3%.lam}"
    BASE4="${INPUT4%.lam}"

    echo "Starting four serial LAMMPS simulations on macOS."
    echo "Each simulation uses one CPU core."
    echo "Run directory: $RUN_DIR"

    "$LAMMPS_EXE" -in "$INPUT1" -log "$RUN_DIR/logs/$BASE1.log" -screen "$RUN_DIR/logs/$BASE1.screen" &
    PID1="$!"

    "$LAMMPS_EXE" -in "$INPUT2" -log "$RUN_DIR/logs/$BASE2.log" -screen "$RUN_DIR/logs/$BASE2.screen" &
    PID2="$!"

    "$LAMMPS_EXE" -in "$INPUT3" -log "$RUN_DIR/logs/$BASE3.log" -screen "$RUN_DIR/logs/$BASE3.screen" &
    PID3="$!"

    "$LAMMPS_EXE" -in "$INPUT4" -log "$RUN_DIR/logs/$BASE4.log" -screen "$RUN_DIR/logs/$BASE4.screen" &
    PID4="$!"

    echo "Process IDs:"
    echo "$INPUT1 PID $PID1"
    echo "$INPUT2 PID $PID2"
    echo "$INPUT3 PID $PID3"
    echo "$INPUT4 PID $PID4"

    STATUS1=0
    STATUS2=0
    STATUS3=0
    STATUS4=0

    wait "$PID1" || STATUS1="$?"
    wait "$PID2" || STATUS2="$?"
    wait "$PID3" || STATUS3="$?"
    wait "$PID4" || STATUS4="$?"

    echo "Simulation exit statuses:"
    echo "$INPUT1 status $STATUS1"
    echo "$INPUT2 status $STATUS2"
    echo "$INPUT3 status $STATUS3"
    echo "$INPUT4 status $STATUS4"

    echo "Generated dump files:"
    find "$RUN_DIR" -maxdepth 1 -name 'dump.*.all' -print

    echo "Log directory: $RUN_DIR/logs"

    if [ "$STATUS1" -ne 0 ] || [ "$STATUS2" -ne 0 ] || [ "$STATUS3" -ne 0 ] || [ "$STATUS4" -ne 0 ]
    then
        echo "ERROR: at least one simulation did not finish successfully."
        exit 1
    fi

    echo "All four simulations finished successfully."
}

check_input_files
check_macos_tools
ensure_lammps

case "$MODE" in
    first)
        run_first
        ;;
    all4)
        run_all4
        ;;
    build)
        echo "LAMMPS build finished."
        echo "$LAMMPS_EXE"
        ;;
    *)
        echo "Usage: bash run_macos.sh [first|all4|build]"
        echo "Use CLEAN=1 bash run_macos.sh build to force a clean rebuild."
        exit 1
        ;;
esac
