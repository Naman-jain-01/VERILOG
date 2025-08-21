# 🚀 RISC-V Pipelined Processor  

<p align="center">
  <img src="images/RISCV.png" alt="RISC-V Logo" width="300" />
</p>

## Overview  

This repository contains the design and implementation of a **32-bit, 5-stage pipelined RISC-V processor** in **Verilog**.  
The processor supports fundamental **RISC-V integer instructions** and integrates key performance-oriented features:  

- ✅ **5-stage pipeline architecture** (IF, ID, EX, MEM, WB)  
- ✅ **Hazard detection unit** to stall when required  
- ✅ **Data forwarding unit** to resolve read-after-write (RAW) hazards efficiently  
- ✅ **Synthesizable design** targeting FPGAs  
- ✅ **Comprehensive verification environment** with testbenches and waveform analysis  

---

## 🔹 Processor Architecture  

<p align="center">
  <img src="images/Processor.png" alt="Pipeline Diagram" width="600" />
</p>  

### Pipeline Stages:
1. **Instruction Fetch (IF)** – Fetches instruction from instruction memory  
2. **Instruction Decode (ID)** – Decodes instruction, reads registers  
3. **Execute (EX)** – Performs ALU operations and branch calculations  
4. **Memory Access (MEM)** – Reads/Writes data from/to data memory  
5. **Write Back (WB)** – Writes results back into register file  

### Pipeline Support Features:
- **Hazard Detection Unit**: Inserts pipeline stalls when hazards are unavoidable  
- **Data Forwarding Unit**: Forwards ALU/MEM results to dependent instructions in the pipeline  

---

## 🔹 Verification  

Verification environment developed in **SystemVerilog**:  

- Testbenches cover **all instruction types** (R-type, I-type, B-type, etc.)  
- **Icarus Verilog** used for compilation and simulation  
- **GTKWave** used to analyze generated `.vcd` waveform dumps  
- Achieved **100% code coverage** across modules  

<p align="center">
  <img src="images/Waveform.png" alt="GTKWave Output" width="650"/>
</p>

---

## 🔹 Synthesis & FPGA Deployment  

- **Target FPGA**: Xilinx Artix-7 (xc7a100t-csg324)  
- **Toolchain**: Xilinx Vivado  
- **Clock Frequency**: Optimized for **50 MHz** operation  
- Synthesized design maps cleanly with efficient resource utilization  

---

## 🛠️ Tools Used  

- [Icarus Verilog](https://github.com/steveicarus/iverilog) – Verilog compilation and simulation  
- [GTKWave](https://github.com/gtkwave/gtkwave) – Waveform viewing and debugging  
- [Xilinx Vivado](https://www.xilinx.com/products/design-tools/vivado.html) – Synthesis and FPGA implementation  

---

## 🔹 Running the Processor  

1. **Compile the testbench**
   ```sh
   iverilog -o processor_tb Processor_tb.v
