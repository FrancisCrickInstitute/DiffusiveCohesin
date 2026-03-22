# DiffusiveCohesin

This repository contains the code used for the paper:

**"Symmetry and force response of cohesin loop extrusion are determined by diffusion of its motor and anchor domains"**

## Overview

This repository provides:

- four LAMMPS input scripts corresponding to the four simulation videos in the paper
- one LAMMPS data file for the initial configuration
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
