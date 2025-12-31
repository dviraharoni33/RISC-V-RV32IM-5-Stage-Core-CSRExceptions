# RV32I Single-Cycle Processor

## 1. Introduction

### What is this project?

This project implements a **Single-Cycle RISC-V Processor** based on the **RV32I** (Integer) Instruction Set Architecture. Designed and implemented in **SystemVerilog**, the processor is capable of executing one instruction per clock cycle.
The core is designed for educational clarity and modularity, featuring a complete datapath that handles instruction fetching, decoding, register file operations, ALU computations, and memory access. This design serves as a fundamental building block for understanding computer architecture and hardware description languages (HDL).

### Key Features

* **RV32I Support:** Implements essential integer instructions including R-type, I-type, S-type, B-type, and J-type.
* **Single-Cycle Execution:** Every instruction, from fetch to writeback, is completed within a single clock period.
* **Modular Architecture:** Clear logical separation between the Datapath (execution units) and the Control Logic (decoding and routing).
* **External Memory Interface:** Synchronous interface for Instruction Memory (IMEM) and Data Memory (DMEM).
* **JAL & Branch Support:** Includes dedicated hardware for calculating jump and branch targets, including a `PC+4` link register path for JAL.
* **Modern SystemVerilog:** Written with clean, synthesizable SystemVerilog code for robust simulation and implementation.

## 2. Architecture & Block Diagram

The system is organized into a modular hierarchy. The `rv32_core` acts as the top-level entity, coordinating the flow of data between the following functional units:

<img width="601" height="575" alt="דיאגרמת מלבנים" src="https://github.com/user-attachments/assets/a97c0cda-1fad-4a94-a3ed-7af63bd50032" />


### Color Coding (As shown in Diagram)

* **Green Modules:** Control and Sequencing logic (Control_Logic, pc_unit, Imm_Gen).
* **Blue Modules:** Computation units (ALU, Branch_Addr).
* **Yellow Modules:** Storage and Memory interfaces (Regfile, Instruction/Data Memory).
* **Red Lines:** Control Signals (Write Enables, Mux Selectors).
* **Black Lines:** 32-bit Datapath (Addresses, Instructions, Data).

### Module Descriptions

**pc_unit (Program Counter)**
Manages the current instruction address. It handles sequential execution (`PC+4`) and jumps/branches based on the `branch_taken` signal.

**Control_Logic**
The "brain" of the processor. It decodes the opcode from the `imem_data` and generates all necessary control signals (e.g., `alu_src_imm`, `mem_to_reg`, `reg_write_en`).

**regfile (Register File)**
Contains 32 general-purpose registers. It supports dual asynchronous reads (`rs1`, `rs2`) and a synchronous write (`rd`) on the rising clock edge.

**alu (Arithmetic Logic Unit)**
Performs the core computations (ADD, SUB, AND, OR, SLT). It also generates a `zero_flag` used for branch decisions.

**Imm_Gen (Immediate Generator)**
Extracts and sign-extends immediate values from various instruction formats (I, S, B, J) to 32-bit values.

## 3. Design Details

### Datapath & JAL Logic

To support the `JAL` (Jump and Link) instruction, the design includes a specialized path. While the `Branch_Addr` calculates the target destination, a dedicated `+4` adder circuit feeds the `JAL Mux`. This ensures that the address of the *next* instruction is saved back to the register file, allowing for subroutine returns.

### Writeback Selection

The processor utilizes a two-stage multiplexing system for the writeback data:

1. **Writeback Mux:** Chooses between the ALU result (calculation) and Data Memory output (Load instructions).
2. **JAL Mux:** Final selection between the standard writeback data and the `PC+4` return address.

## 4. Verification

The design is verified using a comprehensive SystemVerilog testbench:

<img width="1833" height="235" alt="דיאגרמת גלים" src="https://github.com/user-attachments/assets/7a485634-111a-409d-89a6-8b7fdd11c73c" />

* **Instruction Loading:** Hexadecimal machine code is loaded into the Instruction Memory.
* **Execution Tracking:** The testbench monitors the `PC`, `ALU_Result`, and `Regfile` updates to ensure protocol compliance.
* **Data Integrity:** Validates that `Store` (SW) and `Load` (LW) operations correctly interact with the Data Memory.
* **Branch/Jump Validation:** Ensures the `pc_current` correctly updates to non-sequential addresses when jump conditions are met.

## 5. File Descriptions

* **rv32_core.sv:** The top-level wrapper integrating all modules.
* **control_logic.sv:** Opcode decoder and control signal generator.
* **regfile.sv:** 32x32-bit register file implementation.
* **alu.sv:** Combinational logic for arithmetic and logical operations.
* **pc_unit.sv:** Synchronous logic for the Program Counter and reset handling.
* **imm_gen.sv:** Immediate value extraction logic.
* **branch_addr.sv:** Dedicated adder for calculating jump/branch targets.

## 6. Tools Used

* **Language:** SystemVerilog (IEEE 1800)
* **Simulation:** Aldec Riviera-PRO (via EDA Playground)
* **Waveform Viewing:** EPWave
* **Diagram:** draw.io
