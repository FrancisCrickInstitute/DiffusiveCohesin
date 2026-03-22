# DiffusiveCohesin

This repository contains the code used for the paper:

**"Symmetry and force response of cohesin loop extrusion are determined by diffusion of its motor and anchor domains"**

## Overview

This repository provides:

- four LAMMPS input scripts corresponding to the four simulation videos in the paper
- one LAMMPS data file for the initial simulation configuration
- custom LAMMPS source files required for the simulations

The simulations were developed for **LAMMPS 22Jul2025** on **Linux**.

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

- Linux system
- LAMMPS **22Jul2025**
- C++ compiler
- `make`
- optional: MPI if you want to build the MPI version

## Installation

### 1. Download and unpack LAMMPS

Place the LAMMPS 22Jul2025 source archive in your local working directory and unpack it:

```bash
tar -xzf lammps-22Jul2025.tar.gz
````

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

## Running a simulation

Open any simulation subdirectory or use any input file in this repository.

For example, to run a simulation on a **single CPU core**:

```bash
/your/local/path/lammps-22Jul2025/src/lmp_serial -in in.flow_328678_DD14p5_MD14p5.lam
```

To save the output to a log file:

```bash
/your/local/path/lammps-22Jul2025/src/lmp_serial -in in.flow_328678_DD14p5_MD14p5.lam | tee run.log
```

## Notes

* Replace all example paths with your local paths.
* The custom pair style and compute must be compiled into LAMMPS before running the input scripts.
* For testing and reproduction, running on **1 CPU core** is sufficient.
* Using **1 or 2 CPU cores** is recommended for simple runs.

## Reproducibility

To reproduce the simulations:

1. install LAMMPS 22Jul2025
2. copy the custom source files into the LAMMPS `src` folder
3. compile LAMMPS
4. run one of the provided `in.*.lam` scripts with the provided data file

## Contact

For questions about the code or simulations, please contact the repository author.

````

A slightly more polished title line would also be:

```markdown
**"Symmetry and force response of cohesin loop extrusion are determined by diffusion of its motor and anchor domains"**
````
