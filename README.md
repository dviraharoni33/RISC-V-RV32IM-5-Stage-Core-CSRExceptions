# RV32IM 5-Stage Pipelined Processor

## 1. Introduction

### What is this project?

This project implements a fully functional **5-Stage Pipelined RISC-V Processor** based on the **RV32IM** Instruction Set Architecture. Unlike a basic Single-Cycle processor, this core splits instruction execution into five distinct stages (Fetch, Decode, Execute, Memory, Writeback) to optimize throughput and clock efficiency.

Written in **SystemVerilog**, the design tackles advanced computer architecture challenges such as **Data Hazards**, **Control Hazards**, and **Multi-Cycle Operations**. It includes a dedicated `hazard_unit` for Forwarding and Stalling, an `iterative_alu` for multiplication/division, and a `csr_unit` for handling interrupts and exceptions.

### Key Features

* **5-Stage Pipeline:** Implements IF, ID, EX, MEM, WB stages with pipeline registers.
* **RV32IM ISA:** Supports standard Integer instructions plus **Multiplication and Division** (M-Extension).
* **Advanced Hazard Handling:**
* **Full Forwarding:** Solves Read-After-Write (RAW) hazards by bypassing data from MEM and WB stages back to EX.
* **Load-Use Detection:** Automatically inserts "bubbles" (Stalls) when a Load instruction is immediately followed by a dependent instruction.
* **Branch Prediction:** Uses a "Predict Not Taken" strategy with automatic flushing upon misprediction.


* **Iterative ALU:** A state-machine-based unit that handles MUL/DIV operations over multiple cycles, stalling the pipeline only when necessary.
* **Privileged Architecture (CSRs):** Supports `ecall`, `mret`, and external Interrupts (IRQ) with precise trap handling via `mtvec`, `mepc`, and `mcause`.

## 2. Architecture & Block Diagram

<img width="1371" height="491" alt="דיאגרמת מלבנים" src="https://github.com/user-attachments/assets/2dfc1b4c-9a59-4087-938a-153440537e2f" />

### Color Coding 

* **Blue Modules (Storage & Memory):** Components that store state (`RegFile`, `I-MEM`, `D-MEM`, `PC Unit`).
* **Green Modules (Processing):** Units performing calculations (`ALU`, `Iterative ALU`, `Branch Comp`, `Imm Gen`).
* **Red/Pink Modules (Control):** The logic governing data flow and hazards (`Control Unit`, `Hazard Unit`, `CSR Unit`).
* **Yellow Modules (Multiplexers):** Routing logic (`Forwarding Muxes`, `PC Mux`, `WB Mux`).
* **Grey/Orange Blocks:** Pipeline Registers isolating the five stages (`IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB`).
* **Red Lines:** Control Signals (e.g., `reg_write`, `stall`, `forward`).
* **Black/Blue Lines:** 32-bit Datapath (Addresses, Data values).

The processor is organized hierarchically with `rv32_core` as the top-level entity. The data flows through the pipeline registers (`if_id`, `id_ex`, `ex_mem`, `mem_wb`), controlled by global stall/flush signals.

### Module Descriptions

* **`pc_unit` (Fetch):** Manages the Program Counter. It handles sequential execution (+4), Branch/Jump targets (`pc_target_ex`), and Trap vectors (`trap_vector`).
* **`hazard_unit` (The "Traffic Cop"):** The most complex control block. It monitors dependencies between stages to generate:
* `forward_a` / `forward_b`: Select signals for ALU operands.
* `stall_global`: Freezes the PC and IF/ID stage (Load-Use or MUL/DIV busy).
* `flush_ex` / `flush_branch`: Clears pipeline registers on jumps or traps.


* **`iterative_alu` (Execute):** Handles `MUL`, `DIV`, `REM` operations. It uses a `busy/ready` handshake interface to pause the pipeline during calculation.
* **`csr_unit` (Execute):** Manages Control and Status Registers. It detects Interrupts (`irq_i`) and Exceptions, updates the `mcause` register, and redirects the PC to the trap handler.
* **`regfile` (Decode):** 32x32-bit register file with internal error checking (assertions) for reading `x0`.
* **`control_unit` (Decode):** Decodes the opcode and generates control signals for the pipeline (ALU Op, MemWrite, RegWrite, etc.).

## 3. Design Details

### Datapath & Hazard Resolution

To maintain data integrity in a pipelined environment, the design employs three main strategies:

1. **Forwarding (Bypassing):**
When an instruction in the **EX** stage needs a result that is currently in the **MEM** or **WB** stage, the `hazard_unit` activates the forwarding multiplexers.
* *Logic:* If `rs1` matches `rd_mem` or `rd_wb`, the data is routed directly to the ALU, skipping the register file read.


2. **Stalling (Load-Use):**
If a `LOAD` instruction is detected in the **EX** stage and the next instruction in **ID** needs that data, forwarding is impossible (data is still in memory).
* *Action:* The `hazard_unit` asserts `stall_global`. The PC holds its value, and the ID stage is frozen for one cycle.


3. **Flushing (Control Hazards):**
When a Branch is taken (`branch_condition_met`) or a Jump occurs, the instructions currently in IF and ID are invalid.
* *Action:* The `flush_branch` signal clears the pipeline registers, effectively converting the fetched instructions into NOPs.



### Interrupt Handling Flow

1. **Trigger:** An external IRQ (`irq_i`) or internal Exception (`ecall`) is detected.
2. **Trap:** The `csr_unit` asserts `trap_taken`.
3. **Context Save:** The current PC is saved to `mepc`.
4. **Jump:** The PC is forced to the value in `mtvec` (Trap Vector).
5. **Return:** Execution of `mret` restores the PC from `mepc`.

## 4. Verification

The design is verified using a system-level Testbench (`tb_rv32_core`) that simulates real memory and instruction execution.

### Verification Scenarios (Waveform Analysis)

<img width="1827" height="312" alt="דיאגרמת גלים" src="https://github.com/user-attachments/assets/64be846b-9779-4e2d-be12-04bfffc28b26" />

* **Forwarding Check:** Verified by executing `ADD` immediately after `ADDI` to the same register. Waveforms confirm `forward_a/b` signals toggling.
* **Load-Use Hazard:** Verified by `LW` followed by usage. The `stall_global` signal freezes the PC for one cycle.
* **Branching:** Verified via a loop structure (`BNE`), observing the `pc_src_ex` signal and PC discontinuity.
* **Interrupts:** Verified by toggling the `irq` line during execution. The PC jumps to the handler address (`0x80`), executes the handler, and returns via `mret`.

### Automatic Checking

The testbench includes a `check_reg` task that compares the Register File contents against expected values after execution, printing `[PASS]` or `[FAIL]` messages to the console.

## 5. File Descriptions

* `rv32_core.sv`: Top-level wrapper integrating all stages.
* `hazard_unit.sv`: Forwarding, Stalling, and Flushing logic.
* `iterative_alu.sv`: Multi-cycle arithmetic unit.
* `csr_unit.sv`: Trap and CSR register logic.
* `control_unit.sv`: Main decoder.
* `regfile.sv`: Register file implementation.
* `alu.sv`: Combinational arithmetic logic.
* `pc_unit.sv`: Program Counter logic.
* `rv32_pkg.sv`: SystemVerilog package with Enums and Typedefs.
* `rv32_assertions.sv`: Runtime assertion checker for debug.

## 6. Tools Used

* **Language:** SystemVerilog (IEEE 1800)
* **Simulation:** Aldec Riviera-PRO, via EDA Playground
* **Waveform Viewing:** EPWave
* **Diagrams:** draw.io 
