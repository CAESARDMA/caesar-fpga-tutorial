# Chapter 03 — Creating Your First Vivado FPGA Project

[← Previous Chapter](02-install-vivado.md) | [Back to README](../README.md)

---

## Introduction

Now that Vivado is installed, we can create our first FPGA project.

In this chapter, we will create a simple RTL project and add our first SystemVerilog module.

The goal is to understand the basic Vivado project workflow before moving on to more advanced FPGA and PCIe designs.

By the end of this chapter, you will understand:

- How to create a Vivado RTL project
- How to select the target FPGA
- How to add SystemVerilog source files
- How Vivado organizes design sources
- How to select the top-level module
- How to run synthesis
- How to inspect the RTL design

---

# 1. Launch Vivado

Start:

```text
AMD Vivado
```

The Getting Started page should appear.

Under:

```text
Quick Start
```

click:

```text
Create Project
```

This opens the **New Project Wizard**.

---

<p align="center">
  <img src="../images/ch03/01-create-project.png" width="850">
</p>

<p align="center">
  <i>Figure 3.1 — Vivado Getting Started page.</i>
</p>

---

# 2. Create a New Project

Click:

```text
Next
```

You will now see the **Project Name** page.

For this tutorial, use:

```text
Project name:
caesar_fpga_demo

Project location:
C:\FPGA
```

Enable:

```text
Create project subdirectory
```

The resulting project directory will be:

```text
C:\FPGA\caesar_fpga_demo
```

Using a short project path is recommended, especially on Windows.

---

<p align="center">
  <img src="../images/ch03/02-project-name.png" width="800">
</p>

<p align="center">
  <i>Figure 3.2 — Setting the project name and location.</i>
</p>

Click:

```text
Next
```

---

# 3. Select RTL Project

Vivado supports several different project types.

For this tutorial select:

```text
RTL Project
```

RTL stands for:

```text
Register Transfer Level
```

This is the standard project type for designs written using HDL languages such as:

- Verilog
- SystemVerilog
- VHDL

For this example, enable:

```text
Do not specify sources at this time
```

We will add the source file manually after the project is created.

---

<p align="center">
  <img src="../images/ch03/03-rtl-project.png" width="800">
</p>

<p align="center">
  <i>Figure 3.3 — Selecting RTL Project.</i>
</p>

Click:

```text
Next
```

---

# 4. Select the Target FPGA

Vivado now asks which FPGA device the project should target.

You can normally select hardware using either:

```text
Boards
```

or:

```text
Parts
```

If your exact development board is available in the Vivado board database, the **Boards** tab can be convenient.

Otherwise, use:

```text
Parts
```

and select the exact FPGA installed on your hardware.

---

## Example

A board might contain an FPGA such as:

```text
XC7A35T
```

This identifies an AMD/Xilinx Artix-7 FPGA.

You can use the filters inside Vivado to narrow the device list.

For example:

```text
Family:
Artix-7
```

Then select the exact:

```text
Device
Package
Speed Grade
```

matching your FPGA.

> **Important**
>
> Do not select an FPGA only because the family name looks correct.
>
> Always verify the complete part number used by your hardware.

---

<p align="center">
  <img src="../images/ch03/04-select-part.png" width="900">
</p>

<p align="center">
  <i>Figure 3.4 — Selecting the target FPGA part.</i>
</p>

Click:

```text
Next
```

---

# 5. Review the Project

Vivado displays the:

```text
New Project Summary
```

Check that the following information is correct:

```text
Project Name
Project Location
Project Type
Target Device
```

Then click:

```text
Finish
```

Vivado will create the project.

---

<p align="center">
  <img src="../images/ch03/05-project-summary.png" width="800">
</p>

<p align="center">
  <i>Figure 3.5 — New Project Summary.</i>
</p>

---

# 6. Understanding the Vivado Interface

After the project opens, the main Vivado development environment appears.

Several areas are especially important.

---

## Flow Navigator

The **Flow Navigator** controls the main FPGA development workflow.

You will frequently use:

```text
PROJECT MANAGER
     │
     ├── Add Sources
     ├── IP Catalog
     │
     ▼
RTL ANALYSIS
     │
     ▼
SYNTHESIS
     │
     ▼
IMPLEMENTATION
     │
     ▼
PROGRAM AND DEBUG
```

---

## Sources Window

The Sources window contains the files that make up the FPGA design.

Typical source categories include:

```text
Design Sources
Constraints
Simulation Sources
```

Later our project will contain files such as:

```text
top.sv
example.xdc
```

---

# 7. Add Our First Design Source

Now we will create our first SystemVerilog module.

In the Flow Navigator select:

```text
Add Sources
```

Then choose:

```text
Add or create design sources
```

Click:

```text
Next
```

---

<p align="center">
  <img src="../images/ch03/06-add-sources.png" width="800">
</p>

<p align="center">
  <i>Figure 3.6 — Adding a design source.</i>
</p>

Click:

```text
Create File
```

Select:

```text
File type:
SystemVerilog

File name:
top
```

Vivado will create:

```text
top.sv
```

Click:

```text
OK
```

and then:

```text
Finish
```

---

# 8. Create the Top-Level Module

Our first design will be a simple counter.

The module receives a clock signal and continuously increments an internal counter.

Replace the contents of `top.sv` with:

```systemverilog
module top (
    input  logic        clk,
    input  logic        reset_n,
    output logic [7:0]  counter_out
);

    logic [7:0] counter;

    always_ff @(posedge clk) begin
        if (!reset_n)
            counter <= 8'h00;
        else
            counter <= counter + 1'b1;
    end

    assign counter_out = counter;

endmodule
```

---

# 9. What Does This Code Do?

Let's examine the design.

Our module is called:

```systemverilog
module top
```

It has two inputs:

```text
clk
reset_n
```

and one output:

```text
counter_out
```

The internal register:

```systemverilog
logic [7:0] counter;
```

creates an 8-bit counter.

The counter can represent values from:

```text
0
```

to:

```text
255
```

---

## Clocked Logic

The following block runs whenever the clock has a rising edge:

```systemverilog
always_ff @(posedge clk)
```

This describes sequential hardware.

Conceptually:

```text
Clock Rising Edge
       │
       ▼
Check Reset
       │
       ├── Reset Active → Counter = 0
       │
       └── Reset Inactive → Counter + 1
```

---

# 10. Understanding reset_n

The signal:

```text
reset_n
```

uses an active-low naming convention.

The `_n` suffix indicates that the signal is active when it is:

```text
LOW
```

Therefore:

```text
reset_n = 0
```

means:

```text
Reset Active
```

and:

```text
reset_n = 1
```

means:

```text
Normal Operation
```

---

# 11. Set the Top Module

Vivado normally detects the top-level module automatically.

In the Sources window you should see:

```text
top
└── top.sv
```

If Vivado does not automatically select it:

1. Find `top.sv`
2. Right-click the module
3. Select:

```text
Set as Top
```

The top module represents the highest level of the FPGA design hierarchy.

---

# 12. Open Elaborated Design

Before synthesis, Vivado can analyze the RTL design.

In the Flow Navigator select:

```text
RTL Analysis
```

then:

```text
Open Elaborated Design
```

Vivado will elaborate the SystemVerilog source and build a logical representation of the design.

You can then open:

```text
Schematic
```

to inspect the generated RTL structure.

---

<p align="center">
  <img src="../images/ch03/07-rtl-schematic.png" width="950">
</p>

<p align="center">
  <i>Figure 3.7 — RTL schematic generated from our SystemVerilog design.</i>
</p>

This is one of the most important concepts in FPGA development:

```text
SystemVerilog
      │
      ▼
RTL Description
      │
      ▼
Digital Hardware
```

We are describing hardware, not writing instructions for a CPU.

---

# 13. Run Synthesis

Now we can synthesize the design.

In the Flow Navigator click:

```text
Run Synthesis
```

Vivado will analyze the HDL and convert it into FPGA logic.

The process looks like:

```text
top.sv
   │
   ▼
HDL Parsing
   │
   ▼
RTL Elaboration
   │
   ▼
Logic Optimization
   │
   ▼
Technology Mapping
   │
   ▼
Synthesized Netlist
```

When synthesis finishes, Vivado should display:

```text
Synthesis Completed
```

---

# 14. Open Synthesized Design

After synthesis completes select:

```text
Open Synthesized Design
```

You can now inspect how Vivado mapped the RTL design into FPGA resources.

For a simple counter, the synthesized design will primarily contain:

```text
Flip-Flops
Logic
Clock Connections
I/O Ports
```

This demonstrates the relationship between HDL and physical FPGA resources.

---

# 15. Why We Are Not Generating a Bitstream Yet

At this point you may notice that we have not added an:

```text
XDC
```

constraints file.

An XDC file tells Vivado important hardware-specific information such as:

```text
Clock frequency
Pin assignments
I/O standards
Timing constraints
```

For example, our HDL contains:

```systemverilog
input logic clk;
```

but Vivado does not yet know which physical FPGA pin carries that clock.

Likewise:

```systemverilog
output logic [7:0] counter_out;
```

does not yet specify physical output pins.

Because pin assignments depend on the actual development board, we will not blindly copy pin numbers from another FPGA board.

Later we will create hardware-specific constraints.

---

# 16. Project Structure

Our simple project now conceptually looks like:

```text
caesar_fpga_demo/
│
├── top.sv
│
└── Vivado Project Files
```

Inside the CAESAR GitHub repository, however, we will keep reusable source code separate from Vivado-generated project files:

```text
caesar-fpga-tutorial/
│
├── docs/
│
├── src/
│   └── top.sv
│
├── constraints/
│
├── scripts/
│
└── images/
```

This keeps the repository clean.

---

# 17. What We Learned

We have now completed our first basic Vivado project.

You should understand the following workflow:

```text
Launch Vivado
      │
      ▼
Create RTL Project
      │
      ▼
Select FPGA
      │
      ▼
Create top.sv
      │
      ▼
Write SystemVerilog
      │
      ▼
Elaborate RTL
      │
      ▼
Run Synthesis
      │
      ▼
Inspect Synthesized Design
```

This workflow forms the foundation for much larger FPGA projects.

---

# 18. From Simple Logic to PCIe

Our current design is intentionally simple.

It contains only:

```text
Clock
Reset
Counter
Output
```

Later, the same project structure can grow into something more complex:

```text
                 ┌──────────────┐
                 │  Clock/Reset │
                 └──────┬───────┘
                        │
                        ▼
┌──────────┐     ┌──────────────┐
│ PCIe IP  │────▶│  User Logic  │
└──────────┘     └──────┬───────┘
                        │
                ┌───────┴───────┐
                │               │
                ▼               ▼
          Registers          Memory
```

This is why understanding the basic RTL project workflow is important before introducing PCIe.

---

# Source Code

The example source used in this chapter is available at:

```text
src/top.sv
```

---

# Next Chapter

Continue to:

**[Chapter 04 — Understanding FPGA Project Structure](04-project-structure.md)**

In the next chapter we will examine how a real FPGA project should organize:

```text
RTL Sources
Modules
Constraints
IP
Build Scripts
Generated Files
Documentation
```

---

## Official References

AMD Vivado Design Suite User Guide — Using the Vivado IDE (UG893)

AMD Vivado Design Suite User Guide — System-Level Design Entry (UG895)

AMD Vivado Design Suite User Guide — Synthesis (UG901)

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
