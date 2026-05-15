# DiffusiveCohesin

This repository contains the simulation code used for the paper:

**"Symmetry and force response of cohesin loop extrusion are determined by diffusion of its motor and anchor domains"**

## Overview

This repository provides:

- four LAMMPS input scripts corresponding to the four simulation videos in the paper
- one LAMMPS data file for the initial simulation configuration
- custom LAMMPS source files required for the simulations
- two helper scripts for macOS and Linux setup, compilation, and simulation runs

The simulations were developed for **LAMMPS 22Jul2025** on **Linux**. The custom source files in this repository must be compiled into LAMMPS before the input scripts can be run.The simulations and analysis were run on a local workstation equipped with an Intel Core i9-14900K CPU (24 cores, 32 threads), 128 GB DDR5 RAM, and a 960 GB SSD, running Ubuntu 20.04.5 LTS (GNU/Linux 5.4.0-216-generic, x86_64).We also tested in Fedora41，12 × 13th Gen Intel® Core™ i7-1365U.For MacOS，the same seed will not duplicate the exact restults.

## Repository contents

Main files in this repository include:

- `F0.005_600_604.data`  
  Initial system configuration.

- `in.flow_328678_DD14p5_MD14p5.lam` - Video S6
- `in.flow_328701_DD14p5_MD14p5.lam` - Video S5
- `in.flow_328708_DD14p5_MD14p5.lam` - Video S4
- `in.flow_329079_DD14p5_MD24p5.lam` - Video S3


- `compute_nearest_dna.cpp`
- `compute_nearest_dna.h`  
  Custom LAMMPS compute for finding the nearest DNA bead to the cohesin unit in 3D space.

- `pair_morse_dynamic_window.cpp`
- `pair_morse_dynamic_window.h`  
  Custom LAMMPS pair style for calculating interactions with a dynamic DNA contour window.

- `run_macos.sh`  
  Helper script for macOS.

- `run_linux.sh`  
  Helper script for Linux.

## Requirements

-  Linux or MacOS
- `git`
- `cmake`
- C++ compiler
- `make`

The helper scripts download the LAMMPS `stable_22Jul2025` source code, copy the custom LAMMPS source files into the LAMMPS source tree, compile a serial LAMMPS executable, and run the simulations.

The build step may use up to 8 CPU cores to speed up compilation. Each simulation itself uses a serial LAMMPS executable and runs on one CPU core.

## Installation on macOS

Download this repository, then run:

```bash
git clone https://github.com/FrancisCrickInstitute/DiffusiveCohesin.git
cd DiffusiveCohesin
chmod +x run_macos.sh
bash run_macos.sh first
```

This builds LAMMPS and runs the first full simulation:

```bash
in.flow_328678_DD14p5_MD14p5.lam
```

To run all four simulations at the same time on macOS:

```bash
bash run_macos.sh all4
```

To force a clean LAMMPS re-download and rebuild:

```bash
CLEAN=1 bash run_macos.sh first
```

## Installation on Linux

Download this repository, then run:

```bash
git clone https://github.com/FrancisCrickInstitute/DiffusiveCohesin.git
cd DiffusiveCohesin
chmod +x run_linux.sh
bash run_linux.sh first
```

This builds LAMMPS and runs the first full simulation:

```bash
in.flow_328678_DD14p5_MD14p5.lam
```

To run all four simulations at the same time on Linux:

```bash
bash run_linux.sh all4
```

To force a clean LAMMPS re-download and rebuild:

```bash
CLEAN=1 bash run_linux.sh first
```

The macOS and Linux Installation procedures perform the same steps:

1. check or install basic build tools
2. download LAMMPS `stable_22Jul2025`
3. copy the custom `.cpp` and `.h` files into the LAMMPS `src` directory
4. compile serial LAMMPS with the MOLECULE package enabled
5. check that `morse/dynamic_window` and `nearest/dna` were compiled into LAMMPS
6. run either the first simulation or all four simulations
7. save log files and dump files in a run-specific output directory

The local LAMMPS source and build files are placed in:

```bash
.lammps_local/
```

Simulation outputs are placed in:

```bash
runs/
```

## Running modes

Run only the first full simulation:

```bash
bash run_macos.sh first
bash run_linux.sh first
```

Run all four simulations at the same time:

```bash
bash run_macos.sh all4
bash run_linux.sh all4
```

Build LAMMPS only, without running a simulation:

```bash
bash run_macos.sh build
bash run_linux.sh build
```

Force a fresh LAMMPS source download and rebuild:

```bash
CLEAN=1 bash run_macos.sh build
CLEAN=1 bash run_linux.sh build
```

## Output files

Each run creates a new directory under:

```bash
runs/
```

For the first simulation, the main trajectory file is named:

```bash
dump.flow_328678_DD14p5_MD14p5.all
```

LAMMPS log files are saved inside the corresponding run directory under:

```bash
logs/
```

For four simultaneous simulations, each simulation writes its own log and screen file.

## Changing simulation parameters

To remove the external flow, remove or comment out this line in the relevant input script:

```lammps
fix flow mobile addforce 0.0 0.0 0.005
```

To change the diffusion coefficient of the motor unit, edit:

```lammps
variable MD_D0 equal 14.5
```

For example, change `14.5` to another value such as `17.5`, `20.5`, `23.5`, or `24.5`.

To change the random seed, edit the seed line in the relevant input file, for example:

```lammps
variable seed equal 328678
```

## Reproducibility note

Using the same random seed is expected to reproduce the same trajectory only when using the same LAMMPS version, the same executable, the same compiler and compiler flags, the same operating system, the same CPU, and the same number of MPI processes.

Across different operating systems, CPUs, compilers, or compiler versions, the same seed should be interpreted as reproducing the same simulation protocol, not necessarily the exact same bead-by-bead trajectory.

For cross-platform reproduction, compare physical behavior and statistical outputs rather than requiring bitwise-identical trajectory files.

## Notes

- The custom pair style and compute must be compiled into LAMMPS before running the input scripts.
- Running one simulation uses one CPU core.
- Running four simulations at the same time starts four independent serial LAMMPS processes.
- The `-j8` build option speeds up compilation only. It does not make a single serial simulation use 8 CPU cores.
- A typical single simulation can take tens of minutes on a laptop, depending on hardware.
- The output trajectory file name is defined in each LAMMPS input script by the `runTag` variable.

## Contact

For questions about the code or simulations, please contact the repository author.
