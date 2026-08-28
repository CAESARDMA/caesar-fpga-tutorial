# Chapter 11 — Synthesis and Implementation

[← Previous Chapter](10-xdc-constraints.md) | [Back to README](../README.md)

---

## Introduction

Writing RTL is only the beginning of an FPGA project.

Vivado must transform your SystemVerilog design into actual FPGA resources.

The main stages are:

```text
RTL
 │
 ▼
Elaboration
 │
 ▼
Synthesis
 │
 ▼
Optimization
 │
 ▼
Placement
 │
 ▼
Routing
 │
 ▼
Timing Analysis
 │
 ▼
Bitstream
```

In this chapter, we will study how Vivado converts source code into a real FPGA implementation.

We will cover:

- RTL elaboration
- Synthesis
- Netlists
- Technology mapping
- FPGA resources
- Optimization
- Placement
- Routing
- Utilization
- Timing
- Critical paths
- Implementation
- Reports
- Common warnings and failures

---

# 1. RTL Is Not Yet Hardware Placement

When you write:

```systemverilog
always_ff @(posedge clk) begin
    counter <= counter + 1'b1;
end
```

you are describing hardware behavior.

At this stage, you have not yet decided:

```text
Which LUTs are used

Which flip-flops are used

Where those resources are located

How signals are physically routed
```

Vivado determines those details during synthesis and implementation.

---

# 2. The Complete Vivado Build Flow

A simplified build flow is:

```text
Source Files
     │
     ▼
Elaboration
     │
     ▼
Synthesis
     │
     ▼
Synthesized Design
     │
     ▼
Implementation
     │
     ├── Optimization
     ├── Placement
     └── Routing
     │
     ▼
Implemented Design
     │
     ▼
Timing Analysis
     │
     ▼
Bitstream Generation
```

Each stage performs a different job.

---

# 3. Elaboration

Elaboration is the stage where Vivado interprets the HDL hierarchy.

It determines:

- Top-level module
- Module instances
- Parameters
- Signal widths
- Generate blocks
- Connections
- Hierarchy

For example:

```text
top
 │
 ├── counter
 ├── reset_sync
 └── register_block
```

Vivado builds an internal representation of this structure.

---

# 4. Open Elaborated Design

Vivado provides:

```text
Open Elaborated Design
```

This can be useful before synthesis.

You can inspect:

- RTL hierarchy
- Ports
- Signals
- Schematic
- Module connections

This helps catch structural mistakes early.

---

# 5. RTL Schematic

The elaborated schematic provides a graphical representation of the HDL.

For example:

```text
clk
 │
 ▼
Counter Logic
 │
 ▼
counter_out
```

This is especially useful for beginners because it shows how Vivado interprets the RTL.

---

# 6. What Is Synthesis?

Synthesis converts RTL into a hardware netlist.

Conceptually:

```text
SystemVerilog
     │
     ▼
Synthesis
     │
     ▼
Logic Netlist
```

The netlist describes hardware elements and their connections.

---

# 7. Example Synthesis

Consider:

```systemverilog
assign y = a & b;
```

Vivado may map this logic into:

```text
LUT
```

Conceptually:

```text
a ───┐
     LUT ─── y
b ───┘
```

---

# 8. Sequential Logic Mapping

Consider:

```systemverilog
always_ff @(posedge clk) begin
    q <= d;
end
```

Vivado recognizes this as a register.

Conceptually:

```text
d
│
▼
Flip-Flop
│
▼
q
```

---

# 9. Technology Mapping

During synthesis, generic HDL logic is mapped into resources available in the selected FPGA.

Examples include:

```text
LUTs
Flip-Flops
Carry Chains
Block RAM
Distributed RAM
DSP Blocks
Clock Buffers
I/O Resources
```

The selected FPGA family determines what resources are available.

---

# 10. LUTs

LUT stands for:

```text
Look-Up Table
```

LUTs are one of the primary combinational logic resources inside an FPGA.

They can implement functions such as:

```text
AND
OR
XOR
MUX
Comparators
Small Logic Functions
```

---

# 11. Flip-Flops

Flip-flops store state.

They are used for:

```text
Registers
Counters
State Machines
Pipelines
Control Logic
```

Example:

```systemverilog
logic [7:0] counter;
```

may use multiple flip-flops.

---

# 12. Carry Chains

Arithmetic operations such as:

```text
Addition
Subtraction
Counters
Comparisons
```

may use dedicated carry-chain resources.

Example:

```systemverilog
counter <= counter + 1'b1;
```

Vivado can map this efficiently into FPGA carry logic.

---

# 13. Block RAM

Larger memories may be implemented using:

```text
BRAM
```

or:

```text
Block RAM
```

Examples include:

- FIFOs
- Buffers
- Lookup tables
- Packet storage
- Small local memories

Using dedicated memory blocks is often more efficient than building large memories from registers.

---

# 14. DSP Blocks

FPGA devices often contain dedicated:

```text
DSP
```

resources.

These are useful for:

```text
Multiplication
Multiply-accumulate
Signal processing
Filtering
Arithmetic pipelines
```

Vivado may automatically infer DSP resources from suitable RTL.

---

# 15. Synthesis Optimization

Vivado attempts to optimize the design.

Examples include:

```text
Removing unused logic

Simplifying Boolean logic

Combining equivalent logic

Optimizing constants

Reducing resource usage
```

For example:

```systemverilog
assign x = 1'b0 & signal;
```

is always:

```text
0
```

so much of that logic may disappear during synthesis.

---

# 16. Unused Logic Removal

Suppose you create a signal:

```systemverilog
logic unused_signal;
```

and it never affects an output or required internal resource.

Vivado may remove it.

This is normal.

Synthesis keeps logic that contributes to the implemented design.

---

# 17. Constant Propagation

If a signal is always constant, synthesis can simplify downstream logic.

Example:

```systemverilog
logic enable;

assign enable = 1'b1;
```

Logic dependent on:

```text
enable
```

may be simplified because Vivado knows it is permanently high.

---

# 18. Run Synthesis

In Vivado:

```text
Flow Navigator
      │
      ▼
Synthesis
      │
      ▼
Run Synthesis
```

Vivado will analyze the HDL and generate a synthesized design.

After completion, you can select:

```text
Open Synthesized Design
```

---

# 19. Open Synthesized Design

The synthesized design allows you to inspect:

- Netlist hierarchy
- Logic resources
- Schematic
- Device resources
- Timing estimates
- Utilization

At this point, placement and routing are not yet final.

---

# 20. Synthesis Reports

Useful synthesis reports include:

```text
Utilization
Timing Estimates
Hierarchy
Clock Information
Warnings
Messages
```

Always review the synthesis messages.

Do not assume:

```text
Synthesis Completed
```

means the design is automatically correct.

---

# 21. Synthesis Warnings

Common synthesis warnings include:

```text
Unused Signals
Unused Registers
Unconnected Ports
Width Mismatches
Latch Inference
Multiple Drivers
Incomplete Assignments
```

Some warnings are harmless.

Others can indicate serious design mistakes.

---

# 22. Width Mismatch

Example:

```systemverilog
logic [7:0] a;
logic [15:0] b;

assign a = b;
```

Here:

```text
16-bit value
```

is being assigned to:

```text
8-bit signal
```

This may truncate bits.

Vivado may warn about the mismatch.

Be explicit about signal widths.

---

# 23. Multiple Drivers

A signal should generally not be driven by multiple procedural blocks unless the architecture specifically supports it.

Problematic example:

```systemverilog
always_ff @(posedge clk)
    value <= a;

always_ff @(posedge clk)
    value <= b;
```

Now:

```text
value
```

has multiple drivers.

This is usually a design error.

---

# 24. Latch Inference

Incomplete combinational logic may accidentally create a latch.

Example:

```systemverilog
always_comb begin
    if (enable)
        y = a;
end
```

What happens when:

```text
enable = 0
```

?

No assignment exists.

The design appears to need to remember the previous value.

A better implementation is:

```systemverilog
always_comb begin

    y = 1'b0;

    if (enable)
        y = a;

end
```

---

# 25. Implementation

After synthesis comes:

```text
Implementation
```

Implementation converts the synthesized logic into a physical layout inside the FPGA.

A simplified flow is:

```text
Synthesized Netlist
      │
      ▼
Optimization
      │
      ▼
Placement
      │
      ▼
Routing
      │
      ▼
Implemented Design
```

---

# 26. Run Implementation

In Vivado:

```text
Flow Navigator
      │
      ▼
Implementation
      │
      ▼
Run Implementation
```

Vivado then performs physical design.

---

# 27. Design Optimization

Before placement, Vivado may optimize the synthesized design further.

This stage may improve:

```text
Timing
Area
Power
Connectivity
```

Some logic can be restructured to improve implementation quality.

---

# 28. Placement

Placement determines where FPGA resources are physically located.

For example:

```text
Flip-Flop
     │
     ▼
Specific FPGA Slice
```

and:

```text
BRAM
     │
     ▼
Specific BRAM Site
```

Placement has a major effect on timing.

---

# 29. Why Placement Matters

Suppose two registers communicate frequently.

If they are physically close:

```text
Register A ──▶ Register B
```

routing delay may be small.

If they are far apart:

```text
Register A
     │
     │ Long Route
     │
     ▼
Register B
```

delay may increase.

Vivado tries to find a placement that balances many timing and routing requirements.

---

# 30. Routing

After placement, Vivado connects the FPGA resources using programmable routing.

Conceptually:

```text
Logic Block A
      │
      ▼
Routing Network
      │
      ▼
Logic Block B
```

Routing connects:

- LUTs
- Flip-flops
- BRAM
- DSPs
- I/O
- Clocking resources
- Other FPGA resources

---

# 31. Routing Delay

Routing delay can be a major part of FPGA timing.

A path may contain:

```text
Logic Delay
+
Routing Delay
```

Even simple logic can fail timing if the routing path is poor.

---

# 32. Implemented Design

After placement and routing complete, Vivado can open:

```text
Open Implemented Design
```

This represents the final physical implementation before bitstream generation.

---

# 33. Device View

The implemented design can be displayed on the FPGA device layout.

You can inspect where resources are physically placed.

For example:

```text
PCIe Logic
BRAM
DSP
Clock Buffers
User Logic
```

can appear in different regions of the device.

---

# 34. Utilization

Vivado reports how much of the FPGA is being used.

Typical resources include:

```text
LUT
Flip-Flop
BRAM
DSP
BUFG
I/O
Transceivers
```

Example:

```text
LUTs:
2,100 / 20,800

Flip-Flops:
1,500 / 41,600

BRAM:
4 / 50
```

---

# 35. Utilization Percentage

Resource usage is often represented as:

```text
Used / Available
```

or:

```text
Percentage
```

For example:

```text
LUT:
10%
```

does not automatically mean the design is easy to place.

Placement and timing depend on where resources are required and how they connect.

---

# 36. High Utilization

As FPGA utilization increases, implementation may become more difficult.

Potential problems include:

```text
Routing Congestion
Longer Routes
Timing Failures
Placement Difficulty
Longer Build Times
```

A design at:

```text
95% LUT utilization
```

is usually much harder to implement than one at:

```text
40%
```

---

# 37. Timing Analysis

One of the most important stages after implementation is:

```text
Static Timing Analysis
```

Vivado checks whether signal paths meet the defined timing constraints.

For example:

```text
100 MHz clock
→ 10 ns period
```

The logic between registers must satisfy that timing requirement.

---

# 38. Setup Timing

A typical path is:

```text
Source Register
      │
      ▼
Combinational Logic
      │
      ▼
Destination Register
```

The data must arrive before the destination register's setup requirement.

If it arrives too late:

```text
Setup Violation
```

occurs.

---

# 39. Hold Timing

Hold timing ensures the data remains stable long enough after the active clock edge.

A design must satisfy both:

```text
Setup Timing
```

and:

```text
Hold Timing
```

---

# 40. Slack

Timing margin is represented using:

```text
Slack
```

Simplified:

```text
Positive Slack
      │
      ▼
Timing Met

Negative Slack
      │
      ▼
Timing Violation
```

Example:

```text
Slack = +0.850 ns
```

is good.

Example:

```text
Slack = -1.200 ns
```

means the path fails its timing requirement.

---

# 41. WNS

Vivado commonly reports:

```text
WNS
```

which means:

```text
Worst Negative Slack
```

It represents one of the worst setup timing results.

If:

```text
WNS >= 0
```

setup timing is generally considered met for analyzed paths.

If:

```text
WNS < 0
```

there is at least one setup violation.

---

# 42. TNS

Vivado may also report:

```text
TNS
```

which means:

```text
Total Negative Slack
```

TNS represents the accumulated negative setup slack across failing paths.

Conceptually:

```text
WNS
→ Worst individual failure

TNS
→ Total amount of failing setup slack
```

---

# 43. Critical Path

The:

```text
Critical Path
```

is one of the most timing-limited paths in the design.

Example:

```text
Register
   │
   ▼
Comparison
   │
   ▼
Adder
   │
   ▼
MUX
   │
   ▼
Register
```

Too much logic between registers can create a critical path.

---

# 44. Pipelining

One of the most effective timing optimization techniques is:

```text
Pipelining
```

Before:

```text
Register
   │
   ▼
Logic A
   │
   ▼
Logic B
   │
   ▼
Logic C
   │
   ▼
Register
```

After:

```text
Register
   │
   ▼
Logic A
   │
   ▼
Register
   │
   ▼
Logic B
   │
   ▼
Register
   │
   ▼
Logic C
   │
   ▼
Register
```

This reduces the amount of logic that must complete in one clock cycle.

---

# 45. Pipeline Trade-Off

Pipelining improves clock frequency but adds:

```text
Latency
```

For example:

```text
Original:
1 cycle latency

Pipelined:
3 cycle latency
```

This is a common hardware design trade-off:

```text
Higher Performance
      ↕
More Latency / Registers
```

---

# 46. Fanout

A signal that drives many destinations has:

```text
High Fanout
```

Example:

```text
reset
 │
 ├── 1
 ├── 2
 ├── 3
 ├── ...
 └── 5000 registers
```

High fanout can complicate routing and timing.

Clock and reset networks often need special handling.

---

# 47. Routing Congestion

Routing congestion occurs when many signals need to use limited routing resources in the same region.

Conceptually:

```text
Many Connections
      │
      ▼
Small FPGA Region
      │
      ▼
Congestion
```

This may cause:

- Longer routing
- Timing failures
- Implementation difficulty

---

# 48. Hierarchy

Good RTL hierarchy can make large designs easier to understand.

Example:

```text
top
 │
 ├── pcie_wrapper
 │
 ├── register_block
 │
 ├── dma_engine
 │
 └── user_logic
```

However, synthesis may optimize across hierarchy depending on settings.

RTL hierarchy is primarily an organizational tool.

---

# 49. Schematic After Synthesis

The synthesized schematic differs from the elaborated RTL schematic.

Elaborated design shows:

```text
HDL Structure
```

Synthesized design shows:

```text
Mapped Hardware Logic
```

The synthesized version may contain:

```text
LUTs
Flip-Flops
Buffers
Carry Chains
Other Primitives
```

---

# 50. Timing Paths

A timing path typically has:

```text
Startpoint
    │
    ▼
Data Path
    │
    ▼
Endpoint
```

Example:

```text
FF_A/Q
   │
   ▼
LUT
   │
   ▼
LUT
   │
   ▼
FF_B/D
```

Vivado calculates how long this path takes.

---

# 51. Timing Report

In Vivado you can inspect timing using:

```text
Reports
   │
   ▼
Timing
```

Useful reports include:

```text
Report Timing Summary
Report Timing
Report Clock Interaction
```

These help identify performance problems.

---

# 52. Report Timing Summary

One of the most important Vivado reports is:

```text
Report Timing Summary
```

It provides an overview of:

```text
Setup Timing
Hold Timing
Clock Relationships
Timing Violations
WNS
TNS
```

Always review this report before considering the build complete.

---

# 53. Report Utilization

Another useful report is:

```text
Report Utilization
```

This shows how many FPGA resources are used.

For example:

```text
Slice LUTs
Slice Registers
BRAM
DSP
I/O
Clock Buffers
```

---

# 54. Report Clock Interaction

For designs with multiple clock domains:

```text
Report Clock Interaction
```

can help inspect timing relationships between clocks.

This is useful when reviewing:

```text
CDC
Generated Clocks
Asynchronous Clocks
PCIe Clock Domains
```

---

# 55. Design Rule Checks

Vivado also performs:

```text
DRC
```

or:

```text
Design Rule Checks
```

DRC problems may include:

```text
Invalid I/O configuration
Missing pin assignments
Clocking problems
Placement conflicts
Electrical rule violations
```

Critical DRC errors should be resolved before generating a bitstream.

---

# 56. Error vs Warning

Vivado messages can include:

```text
INFO
WARNING
CRITICAL WARNING
ERROR
```

A useful approach is:

```text
INFO
→ Review when relevant

WARNING
→ Understand why it exists

CRITICAL WARNING
→ Investigate carefully

ERROR
→ Must normally be fixed
```

Do not simply ignore large numbers of warnings.

---

# 57. Out-of-Context Synthesis

Some Vivado IP blocks are synthesized separately using:

```text
Out-of-Context
```

or:

```text
OOC
```

synthesis.

Examples may include:

```text
PCIe IP
Clocking IP
FIFO IP
Memory IP
```

This can reduce repeated build time and isolate IP synthesis.

---

# 58. Checkpoints

Vivado can store design states using:

```text
Design Checkpoints
```

commonly using:

```text
.dcp
```

files.

A checkpoint can represent stages such as:

```text
Synthesized Design
Placed Design
Routed Design
```

These are useful in advanced build and debugging workflows.

---

# 59. Build Reproducibility

For an open-source project, the build should ideally be reproducible.

Instead of depending only on manually created Vivado GUI files, a project can include:

```text
RTL Sources
XDC Constraints
IP Configuration
Tcl Build Scripts
Documentation
```

Then another developer can recreate the project.

---

# 60. Tcl Build Flow

A scripted project might follow:

```text
scripts/
└── build.tcl
```

Conceptually:

```tcl
create_project
add_files
read_xdc
synth_design
opt_design
place_design
route_design
report_timing_summary
write_bitstream
```

We will cover build automation in a later chapter.

---

# 61. Example Build Pipeline

A professional build pipeline may look like:

```text
Git Source
   │
   ▼
Vivado Tcl Script
   │
   ▼
Synthesis
   │
   ▼
Implementation
   │
   ▼
Timing Checks
   │
   ▼
Bitstream
   │
   ▼
Release Artifact
```

This makes firmware releases easier to reproduce.

---

# 62. PCIe Design Considerations

PCIe FPGA projects can be more difficult to implement because they may contain:

```text
High-Speed Transceivers
PCIe Hard Blocks
Strict Clocking
Large Streaming Interfaces
High-Frequency User Logic
Multiple Clock Domains
```

Therefore timing and placement reports become especially important.

---

# 63. Do Not Ignore Timing

A design can generate a bitstream and still contain timing violations.

That does not guarantee reliable hardware behavior.

A design that fails timing may:

```text
Work sometimes

Fail at certain temperatures

Fail on some FPGA samples

Produce intermittent data errors

Behave differently between builds
```

Timing closure is part of correct FPGA development.

---

# 64. Timing Closure

The process of eliminating timing violations is often called:

```text
Timing Closure
```

Possible techniques include:

```text
Pipelining

Reducing Logic Depth

Improving Constraints

Changing Architecture

Reducing Clock Frequency

Reducing Fanout

Improving Floorplanning

Reviewing CDC
```

---

# 65. Common Beginner Mistake

A common workflow mistake is:

```text
Synthesis succeeded
      │
      ▼
Generate Bitstream
      │
      ▼
Assume Everything Is Correct
```

A better workflow is:

```text
Synthesis
   │
   ▼
Review Warnings
   │
   ▼
Implementation
   │
   ▼
Review DRC
   │
   ▼
Review Timing
   │
   ▼
Review Utilization
   │
   ▼
Generate Bitstream
```

---

# 66. Recommended Vivado Workflow

For every serious FPGA build:

```text
1. Run Synthesis

2. Review synthesis warnings

3. Open Synthesized Design

4. Run Implementation

5. Review implementation messages

6. Run DRC

7. Review timing summary

8. Review utilization

9. Check critical paths

10. Generate bitstream
```

---

# 67. What We Learned

In this chapter, we learned:

```text
Vivado Build Flow
      │
      ├── Elaboration
      ├── Synthesis
      ├── Netlists
      ├── Technology Mapping
      ├── LUTs
      ├── Flip-Flops
      ├── BRAM
      ├── DSP
      ├── Optimization
      ├── Placement
      ├── Routing
      ├── Utilization
      ├── Timing
      ├── WNS / TNS
      └── Timing Closure
```

We now understand how Vivado transforms RTL into a physical FPGA implementation.

---

# Next Chapter

Continue to:

**[Chapter 12 — Timing Analysis and Timing Closure](12-timing-analysis.md)**

In the next chapter, we will study FPGA timing in greater detail.

We will cover:

```text
Setup Time
Hold Time
Slack
WNS
TNS
Critical Paths
Clock Skew
Logic Delay
Routing Delay
Pipelining
Timing Closure
Vivado Timing Reports
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
