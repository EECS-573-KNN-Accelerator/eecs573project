# SpecNN: A Hardware Accelerator for k-Nearest Neighbors

## Overview

SpecNN is a hardware accelerator for the K-Nearest-Neighbors algorithm, which builds on the ideas presented in the [BitNN Paper (Han et. al 2024)](https://ieeexplore.ieee.org/document/10609723/).  We propose a domain-specific ASIC with minimal logic overhead that implements two optimizations, achieving a 10% speedup or more compared to BitNN in simulation with negligible additional cost.  To expand the scope of testing and to see even greater speedup, we aim to eventually integrate online data sets such as Waymo or KITTI into our verification pipeline.

SpecNN Architecture Diagram:  
  
![Architecture Diagram](images/specnn.drawio.png)

## Python Simulation Run Instructions

In order to characterize the optimizations that we implemented in the RTL, we wrote a cycle-accurate python simulator for both the BitNN baseline implementation and our accelerated SpecNN.  You can run these simulations to reproduce our results using the following commands.

**BitNN Python simulation model** - knn_accelerator/golden_model/bitnn.py  
**SpecNN Python simulation model** - knn_accelerator/golden_model/specnn.py  

1. Choose datasets (query point datatset and reference point dataset)
    - Default Query Point Dataset: verification/datasets synthetic_knn_query.csv, Default Reference Point Dataset: verification/datasets synthetic_knn_data.csv
    - Change the input dataset files in the BitNN Python model (via line 8, 9) and the SpecNN Python model (via line 10, 11)

2. Change the running mean threshold multiplier in the SpecNN Python simulation model (via line 9)
    - A larger multiplier number would relax the termination constraint more (resulting in more accuracy but less speedup)

3. Run the Python models with the following terminal commands to observe the speedup and accuracy difference:

```bash
$ cd knn_accelerator/golden_model/
$ python3 bitnn.py > bitnn_out.txt
$ python3 specnn.py > specnn_out.txt
$ python3 compare.py bitnn_out.txt specnn_out.txt
```

4. The output of compare.py illustrates the speedup of SpecNN over BitNN (for the given dataset), as well as the accuracy of top-K points in SpecNN. The simulation models also generate a set of graphs that provide some illustration on the simulation result. 

## Datasets

A comprehensive list of datasets is stored in the knn_accelerator/verification/datasets/ directory.

## RTL Simulation Run Makefile Instructions

The full backend of the pipeline is implemented, so you can run tests to verify the BDU and TopK units using the makefile with commands of the form make <module_name>.out

The Makefile is set up to be easily extended to accommodate further unit tests and system level tests under simulation and synthesis.  Future work can build on this repo to extend our testing pipeline to include full software pre-processing of online data sets as well as targeted cell libraries with tcl scripts in order to test the accelerators viability in a real world environment.  

There are many different memory interfaces that our accelerator could be plugged into. The current memory controller module is set up to simulate immediate accesses to SRAM, and this can be interchanged with any memory interface that suits the desired application.  

Modules that can be tested:

1. BDU (RTL: verilog/BDU.sv, testbench: test/BDU_test.sv)
    - Run make BDU.out

2. TopK Unit (RTL: verilog/topK.sv, testbench: test/topK_test.sv)
    - Run make topK.out

Other RTL modules:
- BDU Array (RTL: verilog/BDUArray.sv)
- Memory Controller  (RTL: verilog/memoryController.sv)
- Previous kNN cache (RTL: verilog/prev_kn_cache/sv)
- Distance Recompute (RTL: verilog/distRecompute.sv)
- Running Mean (RTL: verilog/running_mean.sv)
- Comparator (RTL: verilog/comparator.sv)




