# Chapter 04 — Understanding FPGA Project Structure

[← Previous Chapter](03-create-project.md) | [Back to README](../README.md)

---

## Introduction

As FPGA projects grow, project organization becomes increasingly important.

A small design may contain only one HDL file.

A real FPGA project may contain:

- RTL source files
- PCIe logic
- Clock and reset logic
- Constraints
- IP configuration
- Build scripts
- Simulation files
- Documentation
- Generated bitstreams

Without a clear structure, FPGA projects quickly become difficult to maintain.

In this chapter, we will organize the CAESAR tutorial repository into a clean and scalable FPGA project structure.

---

# 1. Recommended Repository Structure

Our repository will use the following structure:

```text
caesar-fpga-tutorial/
│
├── README.md
│
├── docs/
│   ├── 01-introduction.md
│   ├── 02-install-vivado.md
│   ├── 03-create-project.md
│   └── 04-project-structure.md
│
├── src/
│   ├── top.sv
│   └── modules/
│       ├── counter.sv
│       └── reset_sync.sv
│
├── constraints/
│   └── example.xdc
│
├── scripts/
│   └── build.tcl
│
└── images/
```

Each directory has a specific purpose.

---

# 2. The `src/` Directory

The `src/` directory contains the HDL source code that describes the FPGA logic.

Example:

```text
src/
├── top.sv
└── modules/
    ├── counter.sv
    └── reset_sync.sv
```

Common file extensions include:

```text
.v      Verilog
.sv     SystemVerilog
.vhd    VHDL
.vhdl   VHDL
```

For this tutorial, we will primarily use:

```text
SystemVerilog (.sv)
```

---

# 3. The Top-Level Module

Most FPGA projects have one top-level module.

In our project:

```text
src/top.sv
```

contains:

```systemverilog
module top (
    input  logic       clk,
    input  logic       reset_n,
    output logic [7:0] counter_out
);

    // FPGA logic

endmodule
```

The top-level module connects the major parts of the design together.

Conceptually:

```text
                    top.sv
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   Clock/Reset     User Logic     Interfaces
```

As the project grows, we should avoid putting all logic directly inside `top.sv`.

Instead, individual functions should be separated into modules.

---

# 4. Why Use Modules?

Imagine a larger FPGA project containing:

```text
PCIe
Registers
Memory
Clock Logic
Reset Logic
LED Control
Debug Logic
```

Putting everything into one file would make the design difficult to understand.

Instead, we can divide the design:

```text
top.sv
  │
  ├── reset_sync.sv
  │
  ├── counter.sv
  │
  ├── register_block.sv
  │
  ├── memory.sv
  │
  └── pcie_interface.sv
```

This is called:

```text
Hierarchical Design
```

Each module performs one specific function.

---

# 5. Moving the Counter Into a Module

In Chapter 03, our counter logic was directly inside `top.sv`.

Now we will move it into a separate module.

Create:

```text
src/modules/counter.sv
```

with the following code:

```systemverilog
module counter (
    input  logic       clk,
    input  logic       reset_n,
    output logic [7:0] count
);

    always_ff @(posedge clk) begin
        if (!reset_n)
            count <= 8'h00;
        else
            count <= count + 1'b1;
    end

endmodule
```

The counter is now an independent hardware module.

---

# 6. Update `top.sv`

Now replace the original counter logic in:

```text
src/top.sv
```

with:

```systemverilog
module top (
    input  logic       clk,
    input  logic       reset_n,
    output logic [7:0] counter_out
);

    counter u_counter (
        .clk     (clk),
        .reset_n (reset_n),
        .count   (counter_out)
    );

endmodule
```

The top module now creates an instance of the counter module.

The instance is named:

```text
u_counter
```

---

# 7. Understanding Module Instantiation

This code:

```systemverilog
counter u_counter (
    .clk     (clk),
    .reset_n (reset_n),
    .count   (counter_out)
);
```

means:

```text
Create one instance
        │
        ▼
counter module
        │
        ▼
Name it u_counter
```

Then connect its ports:

```text
top.clk
   │
   ▼
u_counter.clk


top.reset_n
   │
   ▼
u_counter.reset_n


u_counter.count
   │
   ▼
top.counter_out
```

The hierarchy now becomes:

```text
top
 │
 └── u_counter
       │
       └── counter logic
```

This is the basic concept behind hierarchical FPGA design.

---

# 8. The `constraints/` Directory

HDL describes the FPGA logic.

Constraints describe how that logic interacts with the physical FPGA and board.

We will store constraints in:

```text
constraints/
```

The most common Xilinx constraint format is:

```text
.xdc
```

For example:

```text
constraints/example.xdc
```

---

# 9. What Is an XDC File?

XDC stands for:

```text
Xilinx Design Constraints
```

Constraints can define things such as:

- Physical FPGA pins
- Clock frequencies
- I/O standards
- Timing requirements

Example:

```tcl
create_clock -period 10.000 [get_ports clk]
```

This describes a clock with a period of:

```text
10 ns
```

which corresponds to:

```text
100 MHz
```

---

# 10. Pin Constraints

A physical FPGA pin can also be assigned using XDC.

Example syntax:

```tcl
set_property PACKAGE_PIN <PIN> [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
```

However:

> Never copy FPGA pin numbers from another development board without checking the hardware schematic.

Different boards may use completely different pins even when they use the same FPGA family.

We will therefore keep the example constraints hardware-independent until a specific board is selected.

---

# 11. The `scripts/` Directory

Vivado can be controlled using Tcl scripts.

We will store automation scripts in:

```text
scripts/
```

Example:

```text
scripts/build.tcl
```

Tcl scripts can automate operations such as:

```text
Create Project
Add Sources
Add Constraints
Run Synthesis
Run Implementation
Generate Bitstream
```

This is extremely useful because it allows an FPGA project to be reproduced without manually clicking through the Vivado GUI every time.

---

# 12. Why Build Scripts Matter

Imagine another developer clones the repository.

Without automation, they may need to manually:

```text
Open Vivado
Create Project
Select FPGA
Add Sources
Add Constraints
Configure Settings
Run Synthesis
Run Implementation
```

A build script can eventually reduce this to something conceptually similar to:

```text
Vivado
   │
   ▼
build.tcl
   │
   ▼
Create Project
   │
   ▼
Add Sources
   │
   ▼
Build FPGA
```

This makes the project easier to reproduce.

---

# 13. The `docs/` Directory

Documentation is stored separately from FPGA source code.

Our documentation structure currently looks like:

```text
docs/
├── 01-introduction.md
├── 02-install-vivado.md
├── 03-create-project.md
└── 04-project-structure.md
```

Later chapters will cover:

```text
Verilog / SystemVerilog
PCIe Endpoint
PCIe BAR
PCIe TLP
Clock and Reset
Constraints
Synthesis
Implementation
Timing
Bitstream Generation
Hardware Programming
ILA Debugging
```

Keeping documentation separate makes the repository easier to navigate.

---

# 14. The `images/` Directory

Tutorial screenshots and diagrams belong in:

```text
images/
```

For example:

```text
images/
├── caesar-logo.jpg
│
├── ch02/
│   ├── 01-amd-download.png
│   └── 02-installer.png
│
├── ch03/
│   ├── 01-create-project.png
│   └── 02-project-name.png
│
└── ch04/
```

Organizing images by chapter prevents the image directory from becoming difficult to manage.

---

# 15. Generated Vivado Files

Vivado generates many temporary and intermediate files.

For example, a local Vivado project may contain directories such as:

```text
.cache/
.gen/
.hw/
.ip_user_files/
.runs/
.sim/
.srcs/
```

and project files such as:

```text
*.xpr
```

Some generated artifacts may be useful locally, but they generally should not become the primary source of truth for a clean source-controlled FPGA project.

Our GitHub repository should focus on the files required to understand and reproduce the design.

---

# 16. Source Files vs Generated Files

A useful rule is:

```text
SOURCE FILES
     │
     ├── HDL
     ├── Constraints
     ├── Scripts
     ├── IP configuration
     └── Documentation

          ↓ BUILD ↓

GENERATED FILES
     │
     ├── Synthesis results
     ├── Implementation results
     ├── Reports
     ├── Temporary files
     └── Bitstreams
```

The source files describe how the project is built.

Generated files are produced from those sources.

---

# 17. Using `.gitignore`

Git allows us to exclude unnecessary generated files using:

```text
.gitignore
```

A basic Vivado-oriented `.gitignore` may include:

```gitignore
# Vivado generated directories
*.cache/
*.gen/
*.hw/
*.ip_user_files/
*.runs/
*.sim/

# Vivado logs and journals
*.jou
*.log
*.str

# Temporary files
*.tmp
*.backup.*

# OS files
.DS_Store
Thumbs.db
```

The exact `.gitignore` policy may change depending on whether a project intentionally tracks generated IP products or project metadata.

---

# 18. A More Scalable FPGA Architecture

As our tutorial progresses, the source tree may grow into something like:

```text
src/
│
├── top.sv
│
├── modules/
│   ├── counter.sv
│   ├── reset_sync.sv
│   └── register_block.sv
│
├── pcie/
│   ├── pcie_wrapper.sv
│   └── bar_controller.sv
│
└── debug/
    └── debug_logic.sv
```

The design hierarchy could then look like:

```text
                         top
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
      Reset Logic     PCIe Logic      User Logic
                          │
                    ┌─────┴─────┐
                    │           │
                    ▼           ▼
                 BAR Logic   Registers
```

This structure is much easier to understand than a single large HDL file.

---

# 19. Repository vs Vivado Project

There is an important distinction between:

```text
Git Repository
```

and:

```text
Vivado Project
```

They are related, but they do not need to be identical.

A clean Git repository might contain:

```text
src/
constraints/
scripts/
docs/
```

Then a Tcl script can create the actual Vivado project from those source files.

Conceptually:

```text
Git Repository
      │
      ▼
build.tcl
      │
      ▼
Vivado Project
      │
      ▼
Synthesis
      │
      ▼
Implementation
      │
      ▼
Bitstream
```

This approach makes the source repository portable and reproducible.

---

# 20. Our Project After This Chapter

After completing this chapter, the CAESAR tutorial repository should look similar to:

```text
caesar-fpga-tutorial/
│
├── README.md
│
├── .gitignore
│
├── docs/
│   ├── 01-introduction.md
│   ├── 02-install-vivado.md
│   ├── 03-create-project.md
│   └── 04-project-structure.md
│
├── src/
│   ├── top.sv
│   └── modules/
│       └── counter.sv
│
├── constraints/
│   └── example.xdc
│
├── scripts/
│   └── build.tcl
│
└── images/
```

We now have the foundation of a real FPGA development repository.

---

# 21. What We Learned

In this chapter we learned how to organize:

```text
FPGA Repository
      │
      ├── RTL Source
      │
      ├── Modules
      │
      ├── Constraints
      │
      ├── Build Scripts
      │
      ├── Documentation
      │
      └── Images
```

We also learned the difference between:

```text
Source Files
```

and:

```text
Generated Vivado Files
```

Good project organization becomes increasingly important as FPGA designs grow in complexity.

---

# Next Chapter

Continue to:

**[Chapter 05 — Verilog & SystemVerilog Basics](05-verilog-basics.md)**

In the next chapter we will begin studying HDL in more detail, including:

```text
Modules
Ports
logic
wire
Registers
Combinational Logic
Sequential Logic
always_comb
always_ff
Counters
Finite State Machines
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
