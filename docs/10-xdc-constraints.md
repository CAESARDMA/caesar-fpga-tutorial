# Chapter 10 — FPGA Constraints with XDC

[← Previous Chapter](09-clock-reset.md) | [Back to README](../README.md)

---

## Introduction

HDL describes the logical behavior of an FPGA design.

However, Vivado also needs to know:

- Which FPGA pins are used
- What electrical standards are required
- Which signals are clocks
- What timing requirements must be met
- Which paths should or should not be analyzed

This information is described using:

```text
XDC
```

which stands for:

```text
Xilinx Design Constraints
```

XDC files use Tcl-based syntax and are an essential part of Xilinx/AMD FPGA projects.

In this chapter, we will cover:

- XDC files
- Pin assignments
- Package pins
- IOSTANDARD
- Clock constraints
- Differential clocks
- PCIe signals
- Clock groups
- False paths
- Timing exceptions
- Constraint organization
- Common mistakes

---

# 1. What Is an XDC File?

An XDC file contains constraints for the FPGA design.

Example:

```tcl
set_property PACKAGE_PIN W5 [get_ports clk]

set_property IOSTANDARD LVCMOS33 [get_ports clk]

create_clock -period 10.000 [get_ports clk]
```

These commands tell Vivado:

```text
Which physical pin is used

Which electrical standard is used

What clock frequency is expected
```

---

# 2. HDL vs XDC

HDL describes:

```text
What the hardware does
```

XDC describes:

```text
How the hardware connects to the physical FPGA
```

For example:

```systemverilog
module top (
    input logic clk
);
```

only defines a logical port called:

```text
clk
```

It does not tell Vivado which FPGA package pin carries that signal.

That information belongs in the XDC file.

---

# 3. Typical Project Structure

A clean repository might contain:

```text
src/
│
├── top.sv
└── modules/

constraints/
│
└── board.xdc
```

The HDL and constraints are kept separate.

For example:

```text
src/top.sv
```

contains RTL logic.

```text
constraints/board.xdc
```

contains FPGA pin and timing information.

---

# 4. Pin Assignment

A physical FPGA pin can be assigned using:

```tcl
set_property PACKAGE_PIN
```

Example:

```tcl
set_property PACKAGE_PIN W5 [get_ports clk]
```

This means:

```text
Top-Level Port:
clk

FPGA Package Pin:
W5
```

---

# 5. Never Copy Random Pin Numbers

FPGA pin assignments are hardware-specific.

The correct pin depends on:

- FPGA device
- FPGA package
- Development board
- PCB layout
- Board revision

Never copy a pin assignment from another board without verifying it.

For example:

```tcl
set_property PACKAGE_PIN W5 [get_ports clk]
```

may be correct for one board and completely wrong for another.

Always check:

```text
Board Schematic
Board User Guide
FPGA Pinout
Vendor Constraints File
```

---

# 6. IOSTANDARD

FPGA pins also require an electrical I/O standard.

This is configured using:

```tcl
set_property IOSTANDARD
```

Example:

```tcl
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

This configures the signal to use:

```text
3.3 V LVCMOS
```

---

# 7. Common I/O Standards

Examples include:

```text
LVCMOS33
LVCMOS25
LVCMOS18
LVDS
SSTL
HSTL
```

The correct standard depends on:

- Board voltage
- FPGA bank voltage
- External hardware
- Signal type

Using the wrong IOSTANDARD can prevent the design from working and may create electrical compatibility problems.

---

# 8. Example LED Constraint

Suppose the top-level RTL contains:

```systemverilog
output logic led
```

The board documentation states that the LED is connected to:

```text
Package Pin A10
```

and uses:

```text
3.3 V
```

The XDC might contain:

```tcl
set_property PACKAGE_PIN A10 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

---

# 9. Example Button Constraint

Suppose a push button is connected to:

```text
B12
```

Example:

```tcl
set_property PACKAGE_PIN B12 [get_ports button]
set_property IOSTANDARD LVCMOS33 [get_ports button]
```

The corresponding top-level port may be:

```systemverilog
input logic button
```

---

# 10. Port Names Must Match

The name used in:

```tcl
get_ports
```

must match the top-level HDL port.

For example:

```systemverilog
module top (
    input logic clk,
    output logic led
);
```

The XDC must use:

```tcl
[get_ports clk]
[get_ports led]
```

If the name is wrong, Vivado may report that no matching port was found.

---

# 11. Clock Constraints

Vivado must know which signals are clocks.

A clock is commonly defined using:

```tcl
create_clock
```

Example:

```tcl
create_clock -period 10.000 [get_ports clk]
```

This means:

```text
Clock Period:
10 ns
```

which corresponds to:

```text
100 MHz
```

---

# 12. Frequency and Period

The relationship is:

```text
Period = 1 / Frequency
```

Examples:

```text
50 MHz
→ 20 ns

100 MHz
→ 10 ns

125 MHz
→ 8 ns

200 MHz
→ 5 ns

250 MHz
→ 4 ns
```

So:

```tcl
create_clock -period 5.000 [get_ports clk]
```

defines a:

```text
200 MHz
```

clock.

---

# 13. Naming Clocks

Clocks can also be given names.

Example:

```tcl
create_clock \
    -name sys_clk \
    -period 10.000 \
    [get_ports clk]
```

Now Vivado knows this clock as:

```text
sys_clk
```

Named clocks can make larger constraint files easier to understand.

---

# 14. Clock Waveform

A clock can optionally define its waveform.

Example:

```tcl
create_clock \
    -name sys_clk \
    -period 10.000 \
    -waveform {0.000 5.000} \
    [get_ports clk]
```

This describes a 10 ns clock where:

```text
Rising Edge = 0 ns
Falling Edge = 5 ns
```

which represents a 50% duty cycle.

---

# 15. Differential Clock Inputs

High-speed systems often use differential clocks.

Example top-level ports:

```systemverilog
input logic refclk_p,
input logic refclk_n
```

Conceptually:

```text
REFCLK_P
    │
    ├── Differential Pair
    │
REFCLK_N
```

The two signals are routed together on the PCB.

---

# 16. Differential I/O Standard

A differential pair may use an I/O standard such as:

```text
LVDS
```

Example:

```tcl
set_property PACKAGE_PIN A5 [get_ports refclk_p]
set_property PACKAGE_PIN A4 [get_ports refclk_n]

set_property IOSTANDARD LVDS [get_ports refclk_p]
set_property IOSTANDARD LVDS [get_ports refclk_n]
```

The actual pins and standards must match the selected FPGA and board.

---

# 17. PCIe Reference Clock

PCIe commonly uses a:

```text
100 MHz differential reference clock
```

Conceptually:

```text
PCIe Connector
      │
      ├── REFCLK_P
      └── REFCLK_N
             │
             ▼
          FPGA
```

The exact constraint syntax depends on the FPGA family and how the PCIe IP expects the reference clock to be connected.

---

# 18. PCIe Reset

PCIe commonly provides:

```text
PERST#
```

which is active low.

Example logical top-level port:

```systemverilog
input logic pcie_reset_n
```

A board-specific constraint may look like:

```tcl
set_property PACKAGE_PIN <PIN> [get_ports pcie_reset_n]
set_property IOSTANDARD <STANDARD> [get_ports pcie_reset_n]
```

Do not replace `<PIN>` or `<STANDARD>` until the board documentation has been verified.

---

# 19. PCIe Transceiver Pins

PCIe data lanes use dedicated high-speed transceiver pins.

Examples include:

```text
PCIe TX+
PCIe TX-

PCIe RX+
PCIe RX-
```

These are not normal GPIO signals.

They connect to dedicated FPGA transceivers.

Their placement is heavily constrained by:

- FPGA transceiver resources
- PCIe IP configuration
- Board PCB routing
- Lane location

---

# 20. Do Not Treat PCIe Lanes Like GPIO

A PCIe lane should not be constrained like a normal LED or button signal.

For example, this type of generic GPIO assumption is incorrect:

```text
PCIe TX
→ random PACKAGE_PIN
→ LVCMOS33
```

PCIe uses:

```text
High-Speed Serial Transceivers
```

and requires dedicated FPGA resources.

---

# 21. Bank Voltage

FPGA I/O pins are grouped into:

```text
I/O Banks
```

Different banks may operate at different voltages.

Example:

```text
Bank 13 → 3.3 V
Bank 14 → 1.8 V
```

The selected:

```text
IOSTANDARD
```

must be compatible with the bank voltage.

---

# 22. Drive Strength

Some single-ended output standards support drive-strength configuration.

Example:

```tcl
set_property DRIVE 8 [get_ports led]
```

This might configure:

```text
8 mA
```

drive strength.

This setting is hardware-dependent and should not be changed without understanding the external circuit.

---

# 23. Slew Rate

Some outputs also support:

```text
SLEW
```

Example:

```tcl
set_property SLEW SLOW [get_ports led]
```

or:

```tcl
set_property SLEW FAST [get_ports signal_out]
```

Faster slew is not automatically better.

Fast edges can increase:

- EMI
- Crosstalk
- Signal integrity problems

Use the setting appropriate for the interface.

---

# 24. Pull-Ups and Pull-Downs

Some FPGA input pins may use internal pull resistors.

Examples:

```tcl
set_property PULLUP true [get_ports button]
```

or:

```tcl
set_property PULLDOWN true [get_ports input_signal]
```

Whether this should be used depends on the board circuit.

External resistors may already exist.

---

# 25. Generated Clocks

Some clocks are created internally by clock-management blocks.

For example:

```text
100 MHz Input
      │
      ▼
MMCM
      │
      ▼
200 MHz Output
```

Vivado may automatically derive some generated clocks.

In other situations, explicit generated-clock constraints may be needed.

Example conceptually:

```tcl
create_generated_clock ...
```

The exact syntax depends on the clocking architecture.

---

# 26. Clock Relationships

Vivado performs timing analysis between clock domains when it knows their relationship.

For related clocks:

```text
100 MHz
   │
   ▼
MMCM
   │
   ├── 100 MHz
   └── 200 MHz
```

timing may be analyzed between the domains.

For unrelated asynchronous clocks, this relationship is different.

---

# 27. Asynchronous Clock Groups

If two clocks are truly asynchronous, they can sometimes be declared as separate asynchronous clock groups.

Conceptually:

```tcl
set_clock_groups \
    -asynchronous \
    -group [get_clocks clock_a] \
    -group [get_clocks clock_b]
```

This tells Vivado not to perform ordinary synchronous timing analysis between those clock groups.

---

# 28. Use Clock Groups Carefully

Do not mark clocks asynchronous just to remove timing errors.

Doing so can hide real design problems.

Before using:

```tcl
set_clock_groups -asynchronous
```

verify that:

- The clocks are genuinely asynchronous
- CDC logic exists
- Crossings are intentionally designed
- Timing between those domains should not be analyzed synchronously

---

# 29. False Paths

A:

```text
False Path
```

is a path that does not need normal timing analysis.

A false path can be declared using:

```tcl
set_false_path
```

For example, certain asynchronous control paths may be excluded if the architecture justifies it.

But false-path constraints should be used carefully.

---

# 30. Do Not Hide Timing Problems

This is one of the most important XDC rules:

```text
Never add timing exceptions simply to make timing warnings disappear.
```

A constraint such as:

```tcl
set_false_path
```

changes timing analysis.

It does not fix incorrect hardware architecture.

Always understand the signal path before applying an exception.

---

# 31. Input Delay

External synchronous interfaces may require:

```text
set_input_delay
```

Example conceptually:

```tcl
set_input_delay \
    -clock external_clk \
    <delay> \
    [get_ports data_in]
```

This describes when external input data arrives relative to a reference clock.

The exact values should come from:

- External device timing specifications
- PCB delay analysis
- Interface requirements

---

# 32. Output Delay

Similarly:

```text
set_output_delay
```

describes timing requirements for signals leaving the FPGA.

Conceptually:

```tcl
set_output_delay \
    -clock external_clk \
    <delay> \
    [get_ports data_out]
```

This is important for source-synchronous and other external interfaces.

---

# 33. Why External Delays Matter

Without proper I/O timing constraints, Vivado may know internal FPGA timing but not the complete timing relationship between:

```text
FPGA
```

and:

```text
External Device
```

Correct constraints allow timing analysis to include interface requirements.

---

# 34. Constraint Ordering

XDC files are Tcl scripts.

This means commands are interpreted in order.

In large projects, organization becomes important.

A clean approach might separate constraints by purpose.

Example:

```text
constraints/
│
├── pins.xdc
├── clocks.xdc
├── timing.xdc
└── debug.xdc
```

---

# 35. Alternative Constraint Organization

Another approach is board-specific organization.

Example:

```text
constraints/
│
├── board_a.xdc
├── board_b.xdc
└── board_c.xdc
```

This is useful when the same HDL supports multiple FPGA boards.

---

# 36. Recommended Tutorial Structure

For a simple tutorial project:

```text
constraints/
└── board.xdc
```

is sufficient.

As the project grows:

```text
constraints/
│
├── pins.xdc
├── clocks.xdc
└── timing.xdc
```

may be easier to maintain.

---

# 37. Example Basic XDC

A simple learning example might look like:

```tcl
# ============================================================
# Clock
# ============================================================

set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

create_clock \
    -name sys_clk \
    -period 10.000 \
    [get_ports clk]


# ============================================================
# Reset
# ============================================================

set_property PACKAGE_PIN B12 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]


# ============================================================
# LED
# ============================================================

set_property PACKAGE_PIN A10 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]
```

These pin values are only examples.

They must not be used on real hardware unless they match the exact board.

---

# 38. Comment Your Constraints

XDC supports comments using:

```text
#
```

Example:

```tcl
# System Clock
create_clock -period 10.000 [get_ports clk]
```

Comments make constraint files easier to review and maintain.

---

# 39. Group Constraints by Function

A clear XDC file may use sections like:

```tcl
# ============================================================
# System Clock
# ============================================================

# ============================================================
# Reset
# ============================================================

# ============================================================
# PCIe
# ============================================================

# ============================================================
# LEDs
# ============================================================
```

This becomes very useful in larger FPGA projects.

---

# 40. Vivado I/O Ports Window

Vivado provides GUI tools for viewing and editing physical pin assignments.

You can inspect:

```text
I/O Ports
Package
Device
```

These views help visualize:

- Pin locations
- I/O banks
- Standards
- Port assignments

---

# 41. Package View

The Vivado:

```text
Package
```

view displays the physical FPGA package.

It can help identify:

```text
Package Pins
I/O Banks
Clock-Capable Pins
Transceiver Locations
```

However, board documentation should still be used to determine what each physical FPGA pin connects to.

---

# 42. Board Schematic

One of the most important references for FPGA constraints is the:

```text
Board Schematic
```

The schematic shows connections such as:

```text
FPGA Pin
   │
   ▼
PCB Trace
   │
   ▼
LED / Button / Clock / PCIe Connector
```

For custom hardware, the schematic is often the primary source for XDC pin assignments.

---

# 43. Master XDC Files

Some development-board vendors provide a:

```text
Master XDC
```

file.

This may contain predefined constraints for:

- LEDs
- Buttons
- Clocks
- UART
- SPI
- Ethernet
- Other board peripherals

Users normally uncomment only the signals needed by the project.

---

# 44. Custom FPGA Boards

For a custom FPGA board, a constraint file should be created from:

```text
PCB Schematic
FPGA Pin Assignment
Voltage Rail Information
Clock Architecture
Transceiver Routing
```

Do not rely on a constraint file from a different board just because it uses the same FPGA family.

---

# 45. Same FPGA Does Not Mean Same Pins

Two boards can use the same FPGA model but have completely different PCB connections.

Example:

```text
Board A
XC7A35T
LED → Pin A10

Board B
XC7A35T
LED → Pin F17
```

Therefore:

```text
Same FPGA
≠
Same XDC
```

---

# 46. FPGA Package Matters

Even FPGA devices from the same family may use different packages.

For example:

```text
XC7A35T-CSG324
XC7A35T-CPG236
```

Package pins are different.

Always verify:

```text
Device
Package
Speed Grade
Board Revision
```

before building constraints.

---

# 47. PCIe Lane Placement

PCIe lane placement is especially sensitive.

A board may physically route:

```text
PCIe Lane 0
```

to a specific FPGA transceiver channel.

The Vivado PCIe configuration must match that hardware routing.

Conceptually:

```text
PCIe Connector Lane 0
        │
        ▼
PCB Routing
        │
        ▼
FPGA Transceiver Channel
        │
        ▼
PCIe IP
```

---

# 48. PCIe Lane Reversal

Some PCIe systems and devices can support concepts such as:

```text
Lane Reversal
```

depending on hardware and IP capabilities.

However, this should never be assumed.

The PCB routing and PCIe IP configuration must be checked carefully.

---

# 49. PCIe Clock Constraints

PCIe IP usually includes specific clocking and timing requirements.

Many PCIe-related constraints may be created or managed as part of the generated IP.

You should avoid manually overriding PCIe IP constraints unless you understand the consequences.

Generated IP constraints are part of the PCIe implementation.

---

# 50. IP-Generated Constraints

Vivado IP blocks can include their own:

```text
XDC
```

constraints.

For example:

```text
Clocking Wizard
PCIe IP
Memory Interface Generator
```

may provide constraints automatically.

These constraints work together with your project-level XDC files.

---

# 51. Constraint Scope

Some constraints apply to:

```text
Top-Level Ports
```

while others apply to internal objects such as:

```text
Pins
Cells
Clocks
Nets
```

Examples:

```tcl
get_ports
get_pins
get_cells
get_clocks
get_nets
```

These Tcl queries identify objects inside the design.

---

# 52. `get_ports`

Example:

```tcl
get_ports clk
```

returns the top-level port called:

```text
clk
```

Used in:

```tcl
set_property PACKAGE_PIN W5 [get_ports clk]
```

---

# 53. `get_clocks`

Example:

```tcl
get_clocks sys_clk
```

selects a clock named:

```text
sys_clk
```

This can be used in more advanced timing constraints.

---

# 54. `get_cells`

Example conceptually:

```tcl
get_cells <cell_name>
```

selects logic cells or module instances within the implemented design.

This is useful for advanced placement or timing constraints.

---

# 55. Wildcards

Tcl queries can use patterns.

For example:

```tcl
get_ports {led[*]}
```

might be used for a vector such as:

```systemverilog
output logic [3:0] led;
```

You could then apply one property to the entire group.

---

# 56. Vector Port Constraints

For:

```systemverilog
output logic [3:0] led;
```

individual bits can be constrained:

```tcl
set_property PACKAGE_PIN A10 [get_ports {led[0]}]
set_property PACKAGE_PIN B10 [get_ports {led[1]}]
set_property PACKAGE_PIN C10 [get_ports {led[2]}]
set_property PACKAGE_PIN D10 [get_ports {led[3]}]
```

Then apply a shared I/O standard:

```tcl
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
```

Again, these pin names are examples only.

---

# 57. Unconstrained Ports

If top-level ports do not have appropriate physical constraints, Vivado may issue warnings or errors.

For example:

```text
Unconstrained Logical Port
```

or missing:

```text
IOSTANDARD
```

may prevent bitstream generation depending on project settings and design-rule checks.

---

# 58. Design Rule Checks

Vivado performs:

```text
DRC
```

which stands for:

```text
Design Rule Check
```

DRCs can identify problems such as:

- Missing pin assignments
- Missing I/O standards
- Invalid pin combinations
- Clocking problems
- Placement conflicts

Do not automatically ignore DRC errors.

---

# 59. Timing Constraints vs Physical Constraints

XDC contains two major categories of constraints.

Physical:

```text
PACKAGE_PIN
IOSTANDARD
DRIVE
SLEW
Placement
```

Timing:

```text
create_clock
set_input_delay
set_output_delay
set_clock_groups
set_false_path
```

Both are essential for reliable FPGA hardware.

---

# 60. Common XDC Mistakes

Common mistakes include:

```text
Copying constraints from another board

Using the wrong FPGA package

Using the wrong IOSTANDARD

Forgetting clock constraints

Incorrect clock periods

Marking unrelated paths as false just to fix timing

Treating PCIe transceiver pins like GPIO

Ignoring generated IP constraints

Using pin assignments without checking schematics
```

---

# 61. Recommended Workflow

A reliable constraint workflow looks like:

```text
Identify Exact FPGA
      │
      ▼
Identify Exact Board
      │
      ▼
Read Schematic
      │
      ▼
Identify Clock Sources
      │
      ▼
Assign Package Pins
      │
      ▼
Assign I/O Standards
      │
      ▼
Create Clock Constraints
      │
      ▼
Add Interface Timing Constraints
      │
      ▼
Run Synthesis
      │
      ▼
Run Implementation
      │
      ▼
Check DRC
      │
      ▼
Check Timing
```

---

# 62. Keep XDC in Version Control

Constraint files should normally be stored in Git.

For example:

```text
constraints/
└── board.xdc
```

This allows another developer to reproduce the hardware build.

Unlike Vivado-generated temporary files, XDC files are part of the actual FPGA source project.

---

# 63. Document the Target Hardware

A project should clearly state which hardware its constraints support.

Example:

```text
Target FPGA:
XC7A35T

Package:
CPG236

Board:
Example FPGA Board

Clock:
100 MHz
```

This reduces the chance of users programming firmware built for the wrong board.

---

# 64. Recommended Repository Layout

After adding constraints, our tutorial project structure may look like:

```text
caesar-fpga-tutorial/
│
├── docs/
│
├── images/
│
├── src/
│   ├── top.sv
│   └── modules/
│       └── counter.sv
│
├── constraints/
│   └── board.xdc
│
├── .gitignore
└── README.md
```

The actual `board.xdc` should only contain verified constraints for a specific target board.

---

# 65. What We Learned

In this chapter, we learned:

```text
XDC Constraints
      │
      ├── Package Pins
      ├── IOSTANDARD
      ├── Clock Constraints
      ├── Differential Signals
      ├── PCIe Signals
      ├── Clock Groups
      ├── False Paths
      ├── Input / Output Delays
      ├── DRC
      └── Timing Constraints
```

XDC files connect the logical HDL design to the physical FPGA hardware and tell Vivado how the design must meet timing.

---

# Next Chapter

Continue to:

**[Chapter 11 — Synthesis and Implementation](11-synthesis-implementation.md)**

In the next chapter, we will examine what happens when Vivado transforms our RTL source into a physical FPGA implementation.

We will cover:

```text
Elaboration
Synthesis
Netlists
Technology Mapping
Optimization
Placement
Routing
Utilization
Timing Reports
Critical Paths
Implementation
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
