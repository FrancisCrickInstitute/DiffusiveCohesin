# DiffusiveCohesin

This repository contains the code used for the paper:

**"Symmetry and force response of cohesin loop extrusion are determined by diffusion of its motor and anchor domains"**

## Overview

This repository provides:

- four LAMMPS input scripts corresponding to the four simulation videos in the paper
- one LAMMPS data file for the initial simulation configuration
- custom LAMMPS source files required for the simulations
- one-command setup and run instructions for macOS and Linux

The simulations were developed for **LAMMPS 22Jul2025** on **Linux**.  
They require the custom LAMMPS source files in this repository to be compiled into LAMMPS.

## Repository contents

Main files in this repository include:

- `F0.005_600_604.data`  
  Initial system configuration

- `in.flow_328678_DD14p5_MD14p5.lam`
- `in.flow_328701_DD14p5_MD14p5.lam`
- `in.flow_328708_DD14p5_MD14p5.lam`
- `in.flow_329079_DD14p5_MD24p5.lam`  
  Example LAMMPS input scripts used for the simulations

- `compute_nearest_dna.cpp`
- `compute_nearest_dna.h`
- `pair_morse_dynamic_window.cpp`
- `pair_morse_dynamic_window.h`  
  Custom LAMMPS source files required by the input scripts

## Requirements

- Linux or macOS
- LAMMPS **22Jul2025**
- C++ compiler
- `make`
- `cmake`
- `git`

The commands below download LAMMPS 22Jul2025, copy the custom LAMMPS source files into the LAMMPS source tree, compile a serial single-core LAMMPS executable, and run the simulations.

The build step may use up to 8 CPU cores to speed up compilation.  
The simulation itself uses a serial LAMMPS executable and runs on one CPU core per simulation.

---

# One-command macOS setup and first full simulation

Copy and paste the full block below into a macOS Terminal.

This command will:

1. remove previous `DiffusiveCohesin_mac_run` folders
2. install/check basic build tools
3. download this repository
4. download LAMMPS `stable_22Jul2025`
5. copy the custom LAMMPS source files
6. compile serial LAMMPS
7. run the first full simulation
8. save a separate LAMMPS log file

```bash
/bin/bash <<'EOF'
set -e

echo "Step 0: cleaning old DiffusiveCohesin macOS run directories..."

for d in "$HOME"/DiffusiveCohesin_mac_run "$HOME"/DiffusiveCohesin_mac_run_*
do
    if [ -d "$d" ]
    then
        echo "Removing: $d"
        rm -rf "$d"
    fi
done

echo "Step 1: checking macOS Command Line Tools..."

if ! xcode-select -p >/dev/null 2>&1
then
    echo "macOS Command Line Tools are not installed."
    echo "The installer will open now."
    echo "After the installation finishes, run this whole command block again."
    xcode-select --install
    exit 1
fi

echo "Step 2: checking Homebrew..."

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
    echo "ERROR: Homebrew is still not available."
    echo "Open a new Terminal window and run this command block again."
    exit 1
fi

export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ENV_HINTS=1

echo "Step 3: checking git and cmake..."

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

echo "Step 4: creating a clean working directory..."

RUN_ROOT="$HOME/DiffusiveCohesin_mac_run"
REPO_DIR="$RUN_ROOT/DiffusiveCohesin"
LAMMPS_DIR="$RUN_ROOT/lammps-22Jul2025"
BUILD_DIR="$LAMMPS_DIR/build_serial"

mkdir -p "$RUN_ROOT"
cd "$RUN_ROOT"

echo "Step 5: downloading DiffusiveCohesin source code..."

git clone https://github.com/FrancisCrickInstitute/DiffusiveCohesin.git "$REPO_DIR"

echo "Step 6: downloading LAMMPS stable_22Jul2025 source code..."

git clone --depth 1 --branch stable_22Jul2025 https://github.com/lammps/lammps.git "$LAMMPS_DIR"

echo "Step 7: copying custom LAMMPS source files into LAMMPS src directory..."

cp "$REPO_DIR/compute_nearest_dna.cpp" "$LAMMPS_DIR/src/"
cp "$REPO_DIR/compute_nearest_dna.h" "$LAMMPS_DIR/src/"
cp "$REPO_DIR/pair_morse_dynamic_window.cpp" "$LAMMPS_DIR/src/"
cp "$REPO_DIR/pair_morse_dynamic_window.h" "$LAMMPS_DIR/src/"

echo "Step 8: configuring serial single-core LAMMPS build..."

cmake -S "$LAMMPS_DIR/cmake" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DBUILD_MPI=no -DBUILD_OMP=no -DPKG_MOLECULE=yes -DLAMMPS_MACHINE=serial

echo "Step 9: compiling LAMMPS with up to 8 build jobs..."

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

LAMMPS_EXE="$BUILD_DIR/lmp_serial"

if [ ! -x "$LAMMPS_EXE" ]
then
    echo "ERROR: LAMMPS executable was not created:"
    echo "$LAMMPS_EXE"
    exit 1
fi

echo "Step 10: checking that the custom pair style and compute were compiled..."

HELP_FILE="$RUN_ROOT/lammps_serial_help.txt"

"$LAMMPS_EXE" -h > "$HELP_FILE" 2>&1

if ! grep -q "morse/dynamic_window" "$HELP_FILE"
then
    echo "ERROR: pair_style morse/dynamic_window was not found in the compiled LAMMPS executable."
    echo "Check this file:"
    echo "$HELP_FILE"
    exit 1
fi

if ! grep -q "nearest/dna" "$HELP_FILE"
then
    echo "ERROR: compute nearest/dna was not found in the compiled LAMMPS executable."
    echo "Check this file:"
    echo "$HELP_FILE"
    exit 1
fi

echo "Custom LAMMPS styles found successfully."

echo "Step 11: running the first full simulation on one CPU core."
echo "LAMMPS output will be printed directly in this Terminal."

cd "$REPO_DIR"

mkdir -p logs

RUN_ID="$(date +%Y%m%d_%H%M%S)"
INPUT_FILE="$REPO_DIR/in.flow_328678_DD14p5_MD14p5.lam"
LOG_FILE="$REPO_DIR/logs/in.flow_328678_DD14p5_MD14p5.full.$RUN_ID.log"

echo "Input file:"
echo "$INPUT_FILE"
echo "LAMMPS executable:"
echo "$LAMMPS_EXE"
echo "LAMMPS log file:"
echo "$LOG_FILE"

echo "Starting LAMMPS now..."

set +e
"$LAMMPS_EXE" -in "$INPUT_FILE" -log "$LOG_FILE"
LAMMPS_STATUS="$?"
set -e

echo "LAMMPS exit status: $LAMMPS_STATUS"
echo "Run directory:"
echo "$RUN_ROOT"
echo "LAMMPS log file:"
echo "$LOG_FILE"

if [ -f "$LOG_FILE" ]
then
    echo "Last 60 lines of the LAMMPS log file:"
    tail -n 60 "$LOG_FILE"
fi

if [ "$LAMMPS_STATUS" -ne 0 ]
then
    echo "ERROR: LAMMPS simulation did not finish successfully."
    exit "$LAMMPS_STATUS"
fi

echo "Simulation finished successfully."
EOF
```

---

# One-command Linux setup and first full simulation

Copy and paste the full block below into a Linux terminal.

This command will:

1. remove previous `DiffusiveCohesin_linux_run` folders
2. install/check basic build tools
3. download this repository
4. download LAMMPS `stable_22Jul2025`
5. copy the custom LAMMPS source files
6. compile serial LAMMPS
7. run the first full simulation
8. save a separate LAMMPS log file

```bash
/bin/bash <<'EOF'
set -e

echo "Step 0: cleaning old DiffusiveCohesin Linux run directories..."

for d in "$HOME"/DiffusiveCohesin_linux_run "$HOME"/DiffusiveCohesin_linux_run_*
do
    if [ -d "$d" ]
    then
        echo "Removing: $d"
        rm -rf "$d"
    fi
done

echo "Step 1: checking Linux build tools..."

if [ "$(id -u)" -eq 0 ]
then
    SUDO=""
else
    if command -v sudo >/dev/null 2>&1
    then
        SUDO="sudo"
    else
        SUDO=""
    fi
fi

NEED_INSTALL=0

for cmd in git cmake make c++
do
    if ! command -v "$cmd" >/dev/null 2>&1
    then
        NEED_INSTALL=1
    fi
done

if [ "$NEED_INSTALL" -eq 1 ]
then
    echo "Some build tools are missing. Trying to install them..."

    if command -v apt-get >/dev/null 2>&1
    then
        $SUDO apt-get update
        $SUDO apt-get install -y git cmake make g++
    elif command -v dnf >/dev/null 2>&1
    then
        $SUDO dnf install -y git cmake make gcc-c++
    elif command -v yum >/dev/null 2>&1
    then
        $SUDO yum install -y git cmake make gcc-c++
    elif command -v pacman >/dev/null 2>&1
    then
        $SUDO pacman -Sy --needed git cmake make gcc
    else
        echo "ERROR: could not detect a supported package manager."
        echo "Please install git, cmake, make, and a C++ compiler manually."
        exit 1
    fi
fi

echo "git version:"
git --version

echo "cmake version:"
cmake --version | head -n 1

echo "Step 2: creating a clean working directory..."

RUN_ROOT="$HOME/DiffusiveCohesin_linux_run"
REPO_DIR="$RUN_ROOT/DiffusiveCohesin"
LAMMPS_DIR="$RUN_ROOT/lammps-22Jul2025"
BUILD_DIR="$LAMMPS_DIR/build_serial"

mkdir -p "$RUN_ROOT"
cd "$RUN_ROOT"

echo "Step 3: downloading DiffusiveCohesin source code..."

git clone https://github.com/FrancisCrickInstitute/DiffusiveCohesin.git "$REPO_DIR"

echo "Step 4: downloading LAMMPS stable_22Jul2025 source code..."

git clone --depth 1 --branch stable_22Jul2025 https://github.com/lammps/lammps.git "$LAMMPS_DIR"

echo "Step 5: copying custom LAMMPS source files into LAMMPS src directory..."

cp "$REPO_DIR/compute_nearest_dna.cpp" "$LAMMPS_DIR/src/"
cp "$REPO_DIR/compute_nearest_dna.h" "$LAMMPS_DIR/src/"
cp "$REPO_DIR/pair_morse_dynamic_window.cpp" "$LAMMPS_DIR/src/"
cp "$REPO_DIR/pair_morse_dynamic_window.h" "$LAMMPS_DIR/src/"

echo "Step 6: configuring serial single-core LAMMPS build..."

cmake -S "$LAMMPS_DIR/cmake" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DBUILD_MPI=no -DBUILD_OMP=no -DPKG_MOLECULE=yes -DLAMMPS_MACHINE=serial

echo "Step 7: compiling LAMMPS with up to 8 build jobs..."

if command -v nproc >/dev/null 2>&1
then
    NCPU="$(nproc)"
else
    NCPU=8
fi

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

LAMMPS_EXE="$BUILD_DIR/lmp_serial"

if [ ! -x "$LAMMPS_EXE" ]
then
    echo "ERROR: LAMMPS executable was not created:"
    echo "$LAMMPS_EXE"
    exit 1
fi

echo "Step 8: checking that the custom pair style and compute were compiled..."

HELP_FILE="$RUN_ROOT/lammps_serial_help.txt"

"$LAMMPS_EXE" -h > "$HELP_FILE" 2>&1

if ! grep -q "morse/dynamic_window" "$HELP_FILE"
then
    echo "ERROR: pair_style morse/dynamic_window was not found in the compiled LAMMPS executable."
    echo "Check this file:"
    echo "$HELP_FILE"
    exit 1
fi

if ! grep -q "nearest/dna" "$HELP_FILE"
then
    echo "ERROR: compute nearest/dna was not found in the compiled LAMMPS executable."
    echo "Check this file:"
    echo "$HELP_FILE"
    exit 1
fi

echo "Custom LAMMPS styles found successfully."

echo "Step 9: running the first full simulation on one CPU core."
echo "LAMMPS output will be printed directly in this Terminal."

cd "$REPO_DIR"

mkdir -p logs

RUN_ID="$(date +%Y%m%d_%H%M%S)"
INPUT_FILE="$REPO_DIR/in.flow_328678_DD14p5_MD14p5.lam"
LOG_FILE="$REPO_DIR/logs/in.flow_328678_DD14p5_MD14p5.full.$RUN_ID.log"

echo "Input file:"
echo "$INPUT_FILE"
echo "LAMMPS executable:"
echo "$LAMMPS_EXE"
echo "LAMMPS log file:"
echo "$LOG_FILE"

echo "Starting LAMMPS now..."

set +e
"$LAMMPS_EXE" -in "$INPUT_FILE" -log "$LOG_FILE"
LAMMPS_STATUS="$?"
set -e

echo "LAMMPS exit status: $LAMMPS_STATUS"
echo "Run directory:"
echo "$RUN_ROOT"
echo "LAMMPS log file:"
echo "$LOG_FILE"

if [ -f "$LOG_FILE" ]
then
    echo "Last 60 lines of the LAMMPS log file:"
    tail -n 60 "$LOG_FILE"
fi

if [ "$LAMMPS_STATUS" -ne 0 ]
then
    echo "ERROR: LAMMPS simulation did not finish successfully."
    exit "$LAMMPS_STATUS"
fi

echo "Simulation finished successfully."
EOF
```

---

# Run four simulations at the same time on macOS

Run the macOS setup command above first.  
Then copy and paste the following block into Terminal.

This launches four serial LAMMPS simulations at the same time.  
Each simulation uses one CPU core.  
The four simulations save separate log and screen files.

```bash
/bin/bash <<'EOF'
set -e

RUN_ROOT="$HOME/DiffusiveCohesin_mac_run"
REPO_DIR="$RUN_ROOT/DiffusiveCohesin"
LAMMPS_EXE="$RUN_ROOT/lammps-22Jul2025/build_serial/lmp_serial"

if [ ! -x "$LAMMPS_EXE" ]
then
    echo "ERROR: LAMMPS executable was not found:"
    echo "$LAMMPS_EXE"
    echo "Run the macOS one-command setup first."
    exit 1
fi

if [ ! -d "$REPO_DIR" ]
then
    echo "ERROR: DiffusiveCohesin repository was not found:"
    echo "$REPO_DIR"
    echo "Run the macOS one-command setup first."
    exit 1
fi

cd "$REPO_DIR"

RUN_ID="$(date +%Y%m%d_%H%M%S)"
PARALLEL_LOG_DIR="$REPO_DIR/logs/parallel4_$RUN_ID"

mkdir -p "$PARALLEL_LOG_DIR"

INPUT1="in.flow_328678_DD14p5_MD14p5.lam"
INPUT2="in.flow_328701_DD14p5_MD14p5.lam"
INPUT3="in.flow_328708_DD14p5_MD14p5.lam"
INPUT4="in.flow_329079_DD14p5_MD24p5.lam"

for input in "$INPUT1" "$INPUT2" "$INPUT3" "$INPUT4"
do
    if [ ! -f "$input" ]
    then
        echo "ERROR: input file was not found:"
        echo "$REPO_DIR/$input"
        exit 1
    fi
done

echo "Starting four serial LAMMPS simulations on macOS."
echo "Each simulation uses one CPU core."
echo "Logs will be saved in:"
echo "$PARALLEL_LOG_DIR"

BASE1="${INPUT1%.lam}"
BASE2="${INPUT2%.lam}"
BASE3="${INPUT3%.lam}"
BASE4="${INPUT4%.lam}"

"$LAMMPS_EXE" -in "$INPUT1" -log "$PARALLEL_LOG_DIR/$BASE1.log" -screen "$PARALLEL_LOG_DIR/$BASE1.screen" &
PID1="$!"

"$LAMMPS_EXE" -in "$INPUT2" -log "$PARALLEL_LOG_DIR/$BASE2.log" -screen "$PARALLEL_LOG_DIR/$BASE2.screen" &
PID2="$!"

"$LAMMPS_EXE" -in "$INPUT3" -log "$PARALLEL_LOG_DIR/$BASE3.log" -screen "$PARALLEL_LOG_DIR/$BASE3.screen" &
PID3="$!"

"$LAMMPS_EXE" -in "$INPUT4" -log "$PARALLEL_LOG_DIR/$BASE4.log" -screen "$PARALLEL_LOG_DIR/$BASE4.screen" &
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

echo "Log directory:"
echo "$PARALLEL_LOG_DIR"

if [ "$STATUS1" -ne 0 ] || [ "$STATUS2" -ne 0 ] || [ "$STATUS3" -ne 0 ] || [ "$STATUS4" -ne 0 ]
then
    echo "ERROR: at least one simulation did not finish successfully."
    exit 1
fi

echo "All four simulations finished successfully."
EOF
```

---

# Run four simulations at the same time on Linux

Run the Linux setup command above first.  
Then copy and paste the following block into Terminal.

This launches four serial LAMMPS simulations at the same time.  
Each simulation uses one CPU core.  
The four simulations save separate log and screen files.

```bash
/bin/bash <<'EOF'
set -e

RUN_ROOT="$HOME/DiffusiveCohesin_linux_run"
REPO_DIR="$RUN_ROOT/DiffusiveCohesin"
LAMMPS_EXE="$RUN_ROOT/lammps-22Jul2025/build_serial/lmp_serial"

if [ ! -x "$LAMMPS_EXE" ]
then
    echo "ERROR: LAMMPS executable was not found:"
    echo "$LAMMPS_EXE"
    echo "Run the Linux one-command setup first."
    exit 1
fi

if [ ! -d "$REPO_DIR" ]
then
    echo "ERROR: DiffusiveCohesin repository was not found:"
    echo "$REPO_DIR"
    echo "Run the Linux one-command setup first."
    exit 1
fi

cd "$REPO_DIR"

RUN_ID="$(date +%Y%m%d_%H%M%S)"
PARALLEL_LOG_DIR="$REPO_DIR/logs/parallel4_$RUN_ID"

mkdir -p "$PARALLEL_LOG_DIR"

INPUT1="in.flow_328678_DD14p5_MD14p5.lam"
INPUT2="in.flow_328701_DD14p5_MD14p5.lam"
INPUT3="in.flow_328708_DD14p5_MD14p5.lam"
INPUT4="in.flow_329079_DD14p5_MD24p5.lam"

for input in "$INPUT1" "$INPUT2" "$INPUT3" "$INPUT4"
do
    if [ ! -f "$input" ]
    then
        echo "ERROR: input file was not found:"
        echo "$REPO_DIR/$input"
        exit 1
    fi
done

echo "Starting four serial LAMMPS simulations on Linux."
echo "Each simulation uses one CPU core."
echo "Logs will be saved in:"
echo "$PARALLEL_LOG_DIR"

BASE1="${INPUT1%.lam}"
BASE2="${INPUT2%.lam}"
BASE3="${INPUT3%.lam}"
BASE4="${INPUT4%.lam}"

"$LAMMPS_EXE" -in "$INPUT1" -log "$PARALLEL_LOG_DIR/$BASE1.log" -screen "$PARALLEL_LOG_DIR/$BASE1.screen" &
PID1="$!"

"$LAMMPS_EXE" -in "$INPUT2" -log "$PARALLEL_LOG_DIR/$BASE2.log" -screen "$PARALLEL_LOG_DIR/$BASE2.screen" &
PID2="$!"

"$LAMMPS_EXE" -in "$INPUT3" -log "$PARALLEL_LOG_DIR/$BASE3.log" -screen "$PARALLEL_LOG_DIR/$BASE3.screen" &
PID3="$!"

"$LAMMPS_EXE" -in "$INPUT4" -log "$PARALLEL_LOG_DIR/$BASE4.log" -screen "$PARALLEL_LOG_DIR/$BASE4.screen" &
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

echo "Log directory:"
echo "$PARALLEL_LOG_DIR"

if [ "$STATUS1" -ne 0 ] || [ "$STATUS2" -ne 0 ] || [ "$STATUS3" -ne 0 ] || [ "$STATUS4" -ne 0 ]
then
    echo "ERROR: at least one simulation did not finish successfully."
    exit 1
fi

echo "All four simulations finished successfully."
EOF
```

---

## Manual Linux installation

The commands below describe a manual Linux installation.

### 1. Download and unpack LAMMPS

Download LAMMPS 22Jul2025 from the LAMMPS website, place the source archive in your local working directory, and unpack it:

```bash
tar -xzf lammps-22Jul2025.tar.gz
```

### 2. Copy the custom source files into the LAMMPS source directory

Copy all custom `.cpp` and `.h` files from this repository into the `src` directory of LAMMPS:

```bash
cp *.cpp *.h /your/local/path/lammps-22Jul2025/src/
```

Replace `/your/local/path/` with your local path.

### 3. Compile LAMMPS

Go to the LAMMPS source directory:

```bash
cd /your/local/path/lammps-22Jul2025/src
```

Clean old build files:

```bash
rm -rf Obj_mpi Obj_serial
rm -f lmp_mpi lmp_serial
```

Enable the required package:

```bash
make yes-molecule
```

Build the serial executable:

```bash
make serial -j8
```

Optionally, also build the MPI executable:

```bash
make mpi -j8
```

---

## Running a single simulation manually

For example, to run a simulation on a single CPU core:

```bash
/your/local/path/lammps-22Jul2025/src/lmp_serial -in in.flow_328678_DD14p5_MD14p5.lam
```

To save the output to a log file:

```bash
mkdir -p logs
/your/local/path/lammps-22Jul2025/src/lmp_serial -in in.flow_328678_DD14p5_MD14p5.lam -log logs/in.flow_328678_DD14p5_MD14p5.full.log
```

---

## Notes

- Replace all example paths with your local paths.
- The custom pair style and compute must be compiled into LAMMPS before running the input scripts.
- For testing and reproduction, running on one CPU core is sufficient.
- The `-j8` option speeds up compilation only. It does not make a serial simulation use 8 CPU cores.
- Running four simulations at the same time starts four separate serial LAMMPS processes.
- Each full simulation writes a LAMMPS log file.
- The output trajectory file name is defined in each LAMMPS input script.

## Reproducibility

To reproduce the simulations:

1. install or build LAMMPS 22Jul2025
2. copy the custom source files into the LAMMPS `src` folder
3. compile LAMMPS
4. run one of the provided `in.*.lam` scripts with the provided data file

## Contact

For questions about the code or simulations, please contact the repository author.
