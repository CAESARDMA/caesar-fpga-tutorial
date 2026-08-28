# Chapter 17 — Final Build, Verification, and Project Packaging

[← Previous Chapter](16-simulation-testbench.md) | [Back to README](../README.md)

---

## Introduction

At this point, we have covered the major parts of an FPGA development workflow:

```text
RTL
Constraints
Clocks
Reset
PCIe
BAR
TLP
Synthesis
Implementation
Timing
Bitstream
Hardware Debugging
Tcl Automation
Simulation
```

The final step is combining these pieces into a clean, reproducible and maintainable project.

A good FPGA project should not only work on one developer's computer.

It should also be understandable and rebuildable by someone else.

In this final chapter, we will cover:

- Final repository organization
- Source structure
- Constraints
- Simulation
- Build automation
- Timing verification
- Bitstream generation
- Hardware validation
- Versioning
- Release packaging
- Documentation
- Open-source project structure
- Final engineering workflow

---

# 1. The Complete FPGA Development Flow

The complete workflow can now be summarized as:

```text
Idea
 │
 ▼
Architecture
 │
 ▼
RTL Design
 │
 ▼
Simulation
 │
 ▼
Constraints
 │
 ▼
Synthesis
 │
 ▼
Implementation
 │
 ▼
Timing Analysis
 │
 ▼
Bitstream Generation
 │
 ▼
Hardware Programming
 │
 ▼
Hardware Debugging
 │
 ▼
Verification
 │
 ▼
Release
```

Each stage answers a different engineering question.

---

# 2. Architecture Comes First

Before writing RTL, decide how the system should be structured.

For example:

```text
PCIe Endpoint
      │
      ▼
Transaction Layer
      │
      ▼
BAR Controller
      │
      ▼
Register Block
      │
      ▼
Application Logic
```

Good architecture makes later stages easier.

---

# 3. Separate Responsibilities

A clean FPGA design should separate different responsibilities.

For example:

```text
pcie_wrapper
→ PCIe IP connection

bar_controller
→ BAR request decoding

register_block
→ Register storage

clock_reset
→ Clock and reset management

user_logic
→ Application functionality
```

Avoid putting everything into one giant top-level module.

---

# 4. Final Repository Structure

A mature FPGA repository could look like:

```text
caesar-fpga/
│
├── src/
│   ├── top.sv
│   │
│   ├── modules/
│   │   ├── counter.sv
│   │   └── reset_sync.sv
│   │
│   ├── pcie/
│   │   ├── pcie_wrapper.sv
│   │   ├── bar_controller.sv
│   │   └── register_block.sv
│   │
│   └── utils/
│
├── constraints/
│   └── board.xdc
│
├── sim/
│   ├── tb_counter.sv
│   ├── tb_register_block.sv
│   └── tb_top.sv
│
├── scripts/
│   └── build.tcl
│
├── ip/
│
├── docs/
│
├── images/
│
├── README.md
├── LICENSE
└── .gitignore
```

This structure separates source, verification, constraints and generated outputs.

---

# 5. `src/`

The:

```text
src/
```

directory contains synthesizable HDL.

Examples:

```text
top.sv

counter.sv

reset_sync.sv

bar_controller.sv

register_block.sv
```

These files describe hardware that will become part of the FPGA design.

---

# 6. `constraints/`

The:

```text
constraints/
```

directory contains physical and timing constraints.

Example:

```text
board.xdc
```

It may contain:

```text
Pin Locations

I/O Standards

Clock Definitions

Timing Constraints

Clock Relationships
```

Constraints must match the exact target hardware.

---

# 7. `sim/`

The:

```text
sim/
```

directory contains testbenches.

Examples:

```text
tb_counter.sv

tb_register_block.sv

tb_top.sv
```

Simulation files should not be mixed with synthesizable RTL.

---

# 8. `scripts/`

The:

```text
scripts/
```

directory contains automation.

For example:

```text
build.tcl
```

The goal is:

```text
Clone Repository
      │
      ▼
Run Build Script
      │
      ▼
Generate FPGA Output
```

with minimal manual configuration.

---

# 9. `ip/`

Generated or configured Vivado IP can be organized under:

```text
ip/
```

Examples:

```text
PCIe IP

Clocking Wizard

FIFO

ILA
```

The repository should contain enough configuration information to recreate required IP.

---

# 10. `docs/`

The:

```text
docs/
```

directory contains development documentation.

For example:

```text
Build Guide

Board Guide

PCIe Architecture

Register Map

Debugging Notes
```

Good documentation reduces support work and helps other developers understand the design.

---

# 11. `images/`

Documentation screenshots and diagrams can live in:

```text
images/
```

For example:

```text
Vivado Screenshots

Block Diagrams

Board Images

Architecture Diagrams
```

Keep documentation assets organized instead of scattering them through the repository.

---

# 12. Generated Build Directory

Generated Vivado output should normally go into:

```text
build/
```

Example:

```text
build/
│
├── reports/
├── checkpoints/
└── output/
```

This directory can usually be deleted and regenerated.

---

# 13. Do Not Treat Generated Files as Source

A common mistake is committing every generated Vivado file.

This makes repositories large and difficult to maintain.

The source of truth should ideally be:

```text
RTL

XDC

IP Configuration

Tcl Scripts

Documentation
```

Generated outputs should be reproducible from those inputs.

---

# 14. `.gitignore`

A good FPGA repository should ignore generated files.

Conceptually:

```gitignore
build/

*.jou
*.log
*.str
*.cache
*.runs
*.sim
*.hw
*.ip_user_files
```

The exact list depends on the project structure.

Be careful not to ignore source files that are required to recreate the project.

---

# 15. First Build Verification

Before creating a release, perform a clean build.

Conceptually:

```text
Delete Generated Files
       │
       ▼
Run build.tcl
       │
       ▼
Synthesis
       │
       ▼
Implementation
       │
       ▼
Reports
       │
       ▼
Bitstream
```

The project should not depend on stale local files.

---

# 16. Clean Build

A clean build is important because incremental Vivado projects may hide missing dependencies.

A clean build can reveal:

```text
Missing Source File

Missing XDC

Missing IP

Wrong Path

Hidden GUI Setting

Wrong Compile Order
```

---

# 17. Simulation Before Release

Before hardware testing, run the important simulation tests.

Example regression:

```text
tb_counter
→ PASS

tb_register_block
→ PASS

tb_bar_controller
→ PASS

tb_top
→ PASS
```

A release should not knowingly contain failing tests.

---

# 18. Synthesis Verification

After simulation:

```text
Run Synthesis
```

Review:

```text
Errors

Critical Warnings

Warnings

Utilization
```

Do not simply look for:

```text
Synthesis Completed
```

and ignore the messages.

---

# 19. Implementation Verification

Next run:

```text
Implementation
```

Review:

```text
Placement

Routing

DRC

Resource Usage

Clocking
```

Implementation is where logical design becomes physical FPGA placement.

---

# 20. Timing Verification

Before generating the final firmware, inspect:

```text
Report Timing Summary
```

Important metrics include:

```text
WNS

TNS

WHS

THS
```

All intended clock domains should be correctly constrained.

---

# 21. Timing PASS Is Meaningful Only with Correct Constraints

Suppose Vivado reports:

```text
WNS = +5 ns
```

That sounds excellent.

But if the real clock is not constrained correctly, the report may be meaningless.

Therefore:

```text
Correct Constraints
+
Positive Timing Result
```

are both required.

---

# 22. Check Unconstrained Paths

A design should be reviewed for:

```text
Unconstrained Clocks

Unconstrained Endpoints

Unexpected Clock Relationships
```

A timing report is only useful when Vivado understands the intended timing requirements.

---

# 23. DRC Verification

Review:

```text
Design Rule Checks
```

before release.

Critical problems involving:

```text
I/O

Clocking

Placement

Electrical Configuration

Configuration
```

should be resolved.

---

# 24. Generate the Final Bitstream

After:

```text
Simulation PASS

Synthesis PASS

Implementation PASS

Timing PASS

DRC PASS
```

generate the bitstream.

Example output:

```text
caesar_fpga-v1.0.0.bit
```

If required by the hardware workflow:

```text
caesar_fpga-v1.0.0.bin
```

may also be produced.

---

# 25. Hardware Programming

For development, program the FPGA through:

```text
JTAG
```

using:

```text
Vivado Hardware Manager
```

Then verify the basic system behavior.

---

# 26. Hardware Verification Order

A useful hardware validation order is:

```text
1. FPGA detected

2. FPGA programs successfully

3. Clock running

4. Reset released

5. Basic user logic active

6. PCIe link established

7. Host enumerates device

8. BAR resources assigned

9. Register reads work

10. Register writes work
```

Test from simple layers toward complex layers.

---

# 27. PCIe Hardware Validation

For a PCIe FPGA design, useful milestones include:

```text
FPGA Configured
      │
      ▼
PCIe Link Up
      │
      ▼
Host Enumeration
      │
      ▼
BAR Assignment
      │
      ▼
Register Access
      │
      ▼
Application Logic
```

Each milestone proves part of the system.

---

# 28. First Register Test

A useful read-only register is:

```text
DEVICE_ID
```

Example value:

```text
0x43414553
```

If host software reads the expected value, many pieces of the read path are working.

---

# 29. Version Register

A firmware project should expose a version.

Example:

```text
VERSION
0x00010000
```

This could represent:

```text
1.0.0
```

The exact encoding is a project design choice.

---

# 30. Build ID Register

A build ID helps identify specific firmware revisions.

Example register map:

```text
0x0000 DEVICE_ID
0x0004 VERSION
0x0008 BUILD_ID
0x000C STATUS
```

This makes hardware test reports easier to correlate with source code.

---

# 31. Status Register

A useful:

```text
STATUS
```

register can expose hardware state.

Possible bits:

```text
Bit 0
System Ready

Bit 1
PCIe Link Ready

Bit 2
Error Seen

Bit 3
FIFO Overflow
```

A status register provides basic observability without requiring ILA.

---

# 32. Debug Counters

Persistent counters are valuable for validation.

Examples:

```text
BAR Read Count

BAR Write Count

Request Count

Completion Count

Error Count
```

They help answer:

```text
Is traffic actually reaching this block?
```

---

# 33. ILA Validation

If behavior is incorrect, add or enable:

```text
ILA
```

and observe the relevant signals.

Do not capture the entire design immediately.

Choose probes that answer a specific question.

---

# 34. Validate Reset Behavior

Test both:

```text
Cold Startup
```

and, if supported:

```text
Reset / Reprogram
```

A design that only works after one specific sequence may have reset or startup problems.

---

# 35. Cold Boot Testing

If the FPGA loads from configuration flash, verify:

```text
Power Off
   │
   ▼
Power On
   │
   ▼
FPGA Automatically Configures
   │
   ▼
System Becomes Ready
```

JTAG-only testing does not verify flash boot behavior.

---

# 36. Repeatability

Run important hardware tests more than once.

For example:

```text
Boot Test × 10

Register Read Test × 1000

Write/Readback Test × 1000
```

A design should not only work once.

---

# 37. Versioning

Use clear version numbers.

Example:

```text
v0.1.0
v0.2.0
v1.0.0
v1.1.0
```

Avoid names such as:

```text
final.bin

final2.bin

new_final.bin

working_final_real.bin
```

Versioning makes releases traceable.

---

# 38. Semantic Versioning Concept

A common convention is:

```text
MAJOR.MINOR.PATCH
```

Example:

```text
1.2.3
```

Conceptually:

```text
MAJOR
→ Major compatibility changes

MINOR
→ New compatible functionality

PATCH
→ Bug fixes
```

The exact policy can be adapted for FPGA firmware.

---

# 39. Tag the Source

A release should correspond to a source version.

Conceptually:

```text
Git Tag:
v1.0.0

Firmware:
caesar_fpga-v1.0.0.bit
```

This allows developers to identify exactly which source produced the firmware.

---

# 40. Release Package

A clean release package may contain:

```text
caesar_fpga-v1.0.0/
│
├── caesar_fpga-v1.0.0.bit
├── caesar_fpga-v1.0.0.bin
├── build_info.txt
├── timing_summary.txt
└── README.txt
```

Not every project needs every file, but release artifacts should be clearly organized.

---

# 41. `build_info.txt`

Example:

```text
Project:
CAESAR FPGA

Version:
1.0.0

Vivado:
2026.1

FPGA:
<exact device>

Board:
<exact board>

Timing:
PASS

Source Tag:
v1.0.0
```

This helps identify the release later.

---

# 42. Timing Summary in Release

For engineering builds, including a timing summary can demonstrate:

```text
Required clocks were analyzed

Implementation completed

Timing closure was checked
```

This is especially useful when comparing builds.

---

# 43. Release Notes

Each release should explain what changed.

Example:

```text
CAESAR FPGA v1.1.0

Changes:

- Added status register
- Improved reset handling
- Added BAR write counter
- Updated build script
- Improved timing margin
```

Clear release notes help both users and developers.

---

# 44. Document Target Hardware

Every firmware release should identify its hardware target.

For example:

```text
Target FPGA:
<device>

Target Board:
<board>

PCIe Configuration:
Gen X, xY

Vivado:
<version>
```

Do not assume users know which firmware matches which board.

---

# 45. Same FPGA Does Not Guarantee Same Board

Remember:

```text
Same FPGA Part
≠
Same Board Layout
```

Boards may use different:

```text
Clock Pins

Reset Pins

PCIe Routing

Flash Devices

GPIO Pins

Power Architecture
```

Firmware should clearly identify compatibility.

---

# 46. README as the Entry Point

The repository:

```text
README.md
```

should be the main entry point for a new developer.

It should answer:

```text
What is this project?

What does it teach?

What hardware is required?

How do I build it?

Where is the documentation?

How do I contribute?

Where can I ask questions?
```

---

# 47. Documentation Should Be Layered

Avoid putting every technical detail into the README.

A better structure is:

```text
README
   │
   ▼
Overview
   │
   ▼
Tutorial Chapters
   │
   ▼
Detailed Technical Documentation
```

This keeps the front page readable.

---

# 48. Repository Navigation

A good README can link directly to chapters.

For example:

```text
01 Introduction

02 Installing Vivado

03 Creating a Project

...

17 Final Project
```

This turns the repository into a structured learning resource.

---

# 49. Architecture Documentation

For larger projects, include an architecture section.

Example:

```text
Host PC
   │
   ▼
PCIe
   │
   ▼
PCIe Endpoint
   │
   ▼
BAR / TLP Logic
   │
   ▼
Register Interface
   │
   ▼
Application Logic
```

A simple architecture diagram can explain more than a long paragraph.

---

# 50. Register Map Documentation

If the FPGA exposes registers, document them.

Example:

| Offset | Name | Access | Description |
|---|---|---|---|
| `0x0000` | `DEVICE_ID` | RO | Device identification |
| `0x0004` | `VERSION` | RO | Firmware version |
| `0x0008` | `CONTROL` | RW | Control register |
| `0x000C` | `STATUS` | RO | Status register |

Register maps should remain synchronized with the RTL.

---

# 51. Build Documentation

A build section should explain:

```text
Required Vivado Version

Target FPGA

Build Command

Output Location
```

For example:

```text
vivado -mode batch -source scripts/build.tcl
```

Then:

```text
build/output/
```

contains the generated artifacts.

---

# 52. Simulation Documentation

Document how to run tests.

For example:

```text
Run Behavioral Simulation

Simulation Top:
tb_counter
```

For automated environments, document the test command when available.

---

# 53. Contributing

An open-source repository can include contribution guidance.

Useful expectations include:

```text
Keep RTL readable

Document new modules

Add tests when possible

Do not commit generated Vivado output

Verify timing before major changes
```

This makes collaboration easier.

---

# 54. Coding Style

A project may define basic RTL style rules.

For example:

```text
Use meaningful signal names

Use always_ff for sequential logic

Use always_comb for combinational logic

Use nonblocking assignments in sequential logic

Avoid unexplained magic numbers

Document interfaces
```

Consistency makes hardware code easier to review.

---

# 55. Module Headers

Complex modules can include brief comments.

Example:

```systemverilog
// ============================================================
// CAESAR FPGA
//
// Module:
// register_block
//
// Description:
// Implements memory-mapped control and status registers.
// ============================================================
```

Comments should explain design intent, not repeat every line of code.

---

# 56. License

An open-source project should include a:

```text
LICENSE
```

file.

The license determines how others may:

```text
Use

Modify

Redistribute

Combine
```

the source code.

Choose a license deliberately.

---

# 57. Third-Party Code

If the project contains third-party or upstream code:

```text
Keep Copyright Notices

Preserve Required License Text

Document Source

Follow Redistribution Requirements
```

Do not remove upstream authorship or present external code as original work.

---

# 58. Dependency Documentation

If the project depends on:

```text
Vivado IP

External HDL Modules

Open-Source Libraries
```

document those dependencies.

A developer should know what is required before starting the build.

---

# 59. Avoid Hidden Dependencies

A repository should not silently depend on:

```text
A file only on your desktop

An unpublished IP core

A local XDC

An old generated Vivado cache
```

If a clean clone cannot rebuild the project, something is missing.

---

# 60. Reproducibility Test

One of the strongest final checks is:

```text
Clone Repository into New Directory
      │
      ▼
Follow README
      │
      ▼
Run Build
      │
      ▼
Run Simulation
      │
      ▼
Generate Bitstream
```

This tests the project from the perspective of another developer.

---

# 61. Developer Experience

A good open-source project should reduce friction.

Instead of:

```text
Create Vivado project manually

Guess FPGA settings

Find missing files

Guess top module

Guess constraints
```

aim for:

```text
Clone

Read README

Run Script

Build
```

---

# 62. Professional FPGA Workflow

A mature development workflow can be represented as:

```text
Feature Branch
      │
      ▼
RTL Changes
      │
      ▼
Simulation
      │
      ▼
Code Review
      │
      ▼
Clean Build
      │
      ▼
Timing Verification
      │
      ▼
Hardware Test
      │
      ▼
Merge
      │
      ▼
Release
```

This is much more reliable than manually changing firmware without a repeatable process.

---

# 63. Source Control

Git should track the important engineering inputs.

Examples:

```text
.sv

.v

.xdc

.tcl

.xci

.md
```

Generated output should be handled separately according to the project's release strategy.

---

# 64. Commit Messages

Use meaningful commit messages.

Better:

```text
Add BAR register block

Fix reset synchronizer

Pipeline read response path

Update board constraints
```

Less useful:

```text
update

fix

new

test
```

Clear Git history makes debugging easier.

---

# 65. Small Commits

Prefer logical commits.

For example:

```text
Commit 1
Add reset synchronizer

Commit 2
Add simulation test

Commit 3
Integrate reset into top
```

This makes changes easier to review and revert.

---

# 66. Keep Known-Good Builds

When a hardware milestone is reached, tag or document it.

Example:

```text
v0.1.0
→ FPGA programs successfully

v0.2.0
→ PCIe enumerates

v0.3.0
→ BAR reads work

v0.4.0
→ BAR writes work

v1.0.0
→ Stable initial release
```

Milestone-based development reduces debugging uncertainty.

---

# 67. Do Not Change Everything at Once

If a working design suddenly fails after major changes, debugging becomes difficult.

A better process is:

```text
Small Change

Build

Test

Commit

Next Change
```

This helps identify exactly when a regression appeared.

---

# 68. Final Verification Checklist

Before creating a release:

```text
[ ] Correct FPGA selected

[ ] Correct board constraints loaded

[ ] Simulation tests pass

[ ] Synthesis passes

[ ] Critical warnings reviewed

[ ] Implementation passes

[ ] DRC reviewed

[ ] Timing constraints reviewed

[ ] Setup timing passes

[ ] Hold timing passes

[ ] Bitstream generated

[ ] FPGA programmed successfully

[ ] Hardware functionality tested

[ ] Firmware version updated

[ ] Release notes written

[ ] Documentation updated
```

---

# 69. PCIe Verification Checklist

For PCIe projects:

```text
[ ] Reference clock verified

[ ] Reset behavior verified

[ ] PCIe link reaches operational state

[ ] Host enumerates endpoint

[ ] Expected link width negotiated

[ ] Expected link speed negotiated

[ ] BAR resources assigned

[ ] DEVICE_ID read works

[ ] VERSION read works

[ ] CONTROL write/readback works

[ ] Error counters checked
```

---

# 70. Debug Build vs Release Build

It can be useful to maintain two build modes.

Debug:

```text
ILA

VIO

Additional Counters

Extra Status Signals
```

Release:

```text
Minimal Debug Logic

Validated Configuration

Release Version
```

This avoids shipping unnecessary debug instrumentation.

---

# 71. Archive Debug Information

For difficult hardware problems, save:

```text
ILA Capture

Timing Report

Bitstream Version

Git Commit

Board Revision

Host Information
```

This creates a useful engineering record.

---

# 72. Final Build Pipeline

The final CAESAR-style project flow can look like:

```text
Source
   │
   ▼
Simulation
   │
   ▼
Vivado Tcl Build
   │
   ▼
Synthesis
   │
   ▼
Implementation
   │
   ▼
Timing + DRC
   │
   ▼
Bitstream
   │
   ▼
Hardware Validation
   │
   ▼
Release
```

---

# 73. From Tutorial to Real Project

This tutorial demonstrated the concepts required to move from:

```text
Simple Verilog
```

toward:

```text
Structured FPGA Firmware
```

A real project can now extend these ideas with:

```text
More Complex PCIe Logic

Streaming Interfaces

DMA Engines

Memory Controllers

Additional FPGA Boards

Custom Hardware
```

The same engineering fundamentals continue to apply.

---

# 74. The Most Important FPGA Skill

Learning individual Verilog syntax is important.

But the larger skill is understanding the complete development cycle:

```text
Design

Verify

Implement

Measure

Debug

Improve
```

FPGA engineering is iterative.

---

# 75. Do Not Treat Vivado as a Black Box

When a build fails, understand which stage failed.

For example:

```text
RTL Problem
→ Simulation / Synthesis

Physical Problem
→ Placement / Routing

Timing Problem
→ Timing Analysis

Hardware Problem
→ ILA / Board Debug

PCIe Problem
→ Link / Enumeration / Transaction Debug
```

Knowing where to look is one of the most valuable FPGA engineering skills.

---

# 76. Build for Observability

A good design should make important internal states visible.

Useful features include:

```text
Version Registers

Status Registers

Counters

Error Flags

ILA Hooks
```

Observability dramatically reduces debugging time.

---

# 77. Build for Reproducibility

A good project should answer:

```text
Can someone else rebuild this?
```

If the answer is no, improve:

```text
Build Scripts

Documentation

Dependency Management

Constraints

Version Information
```

---

# 78. Build for Maintainability

Code should be organized so that future changes are manageable.

Prefer:

```text
Small Modules

Clear Interfaces

Defined Clock Domains

Documented Register Maps

Automated Tests
```

over large tightly coupled RTL blocks.

---

# 79. Build for Verification

Design module boundaries so blocks can be tested independently.

For example:

```text
PCIe Parser
      │
      ▼
Internal Request Interface
      │
      ▼
Register Block
```

The register block can be tested without requiring a complete PCIe simulation environment.

---

# 80. Build for Timing

Think about pipeline boundaries during architecture design.

Do not wait until the end to discover one enormous combinational path.

High-frequency FPGA logic benefits from:

```text
Short Logic Stages

Registered Interfaces

Controlled Fanout

Clear Clock Domains
```

---

# 81. Build for Hardware Reality

FPGA development exists at the intersection of:

```text
Software-Like Code
+
Digital Hardware
+
Physical Board Design
```

You need to understand all three layers.

A perfect RTL module cannot compensate for the wrong board pin assignment.

---

# 82. What This Tutorial Covered

Across this tutorial, we studied:

```text
01
FPGA Development Fundamentals

02
Vivado Installation

03
Creating a Vivado Project

04
Project Structure

05
Verilog & SystemVerilog

06
PCIe Endpoint Fundamentals

07
PCIe BAR Configuration

08
PCIe TLP Fundamentals

09
Clock and Reset Design

10
XDC Constraints

11
Synthesis and Implementation

12
Timing Analysis and Timing Closure

13
Bitstream Generation

14
FPGA Programming and Debugging

15
Vivado Tcl Automation

16
Simulation and Testbenches

17
Final Build and Project Packaging
```

This gives us a complete foundation for developing structured FPGA firmware.

---

# 83. Where to Go Next

Possible next topics include:

```text
Advanced PCIe Architecture

AXI-Stream

PCIe Transaction Engines

FIFO Design

BRAM Interfaces

Interrupts

MSI / MSI-X

Multi-Clock Systems

Advanced CDC

Custom FPGA Boards

High-Speed Interfaces

Automated Verification

CI for FPGA Projects
```

These can be built on top of the foundation from this tutorial.

---

# 84. Final Engineering Rule

Before calling a firmware build complete, ask:

```text
Does it simulate?

Does it synthesize?

Does it implement?

Does it meet timing?

Does it work on hardware?

Can it be rebuilt?

Is it documented?
```

If the answer to all seven is yes, the project is in a strong engineering state.

---

# Tutorial Complete

Congratulations.

You have reached the end of the:

# CAESAR FPGA Development Tutorial

You now understand the complete FPGA development flow from RTL to real hardware:

```text
SystemVerilog
      │
      ▼
Simulation
      │
      ▼
Vivado
      │
      ▼
Synthesis
      │
      ▼
Implementation
      │
      ▼
Timing
      │
      ▼
Bitstream
      │
      ▼
FPGA Hardware
```

The next step is to apply these concepts to real FPGA projects.

---

<div align="center">

## CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

Build. Verify. Understand the hardware.

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
