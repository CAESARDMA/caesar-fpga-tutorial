# Chapter 13 — Generating the FPGA Bitstream

[← Previous Chapter](12-timing-analysis.md) | [Back to README](../README.md)

---

## Introduction

After synthesis and implementation are complete, Vivado can generate the configuration file used to program the FPGA.

This configuration file is commonly called a:

```text
Bitstream
```

For Xilinx/AMD FPGA devices, common output formats include:

```text
.bit
.bin
```

The generated file contains the configuration data that defines how the FPGA hardware is configured.

In this chapter, we will cover:

- Bitstream generation
- `.bit` files
- `.bin` files
- FPGA configuration
- JTAG programming
- SPI flash
- Volatile configuration
- Non-volatile configuration
- Vivado Hardware Manager
- Configuration memory
- Build outputs
- Firmware release organization
- Common programming problems

---

# 1. What Is a Bitstream?

An FPGA does not permanently contain the hardware described by your SystemVerilog source.

Instead, the FPGA must be configured.

The configuration data is stored in a file called a:

```text
Bitstream
```

Conceptually:

```text
SystemVerilog
     │
     ▼
Synthesis
     │
     ▼
Implementation
     │
     ▼
Bitstream Generation
     │
     ▼
FPGA Configuration File
```

---

# 2. What Does the Bitstream Contain?

The bitstream contains configuration information for FPGA resources such as:

```text
LUT Configuration

Flip-Flop Configuration

Routing Connections

Block RAM Initialization

DSP Configuration

Clocking Resources

I/O Configuration

Transceiver Configuration
```

In other words, it describes how the programmable FPGA fabric should be configured.

---

# 3. Source Code vs Bitstream

Your source project may contain:

```text
SystemVerilog
XDC
IP Configuration
Tcl Scripts
```

These are development files.

The FPGA itself does not execute SystemVerilog source code directly.

Instead:

```text
Source Code
    │
    ▼
Vivado Build
    │
    ▼
Bitstream
    │
    ▼
FPGA
```

---

# 4. Generate Bitstream in Vivado

After successful implementation, Vivado provides:

```text
Generate Bitstream
```

in the Flow Navigator.

Typical workflow:

```text
Run Synthesis
      │
      ▼
Run Implementation
      │
      ▼
Review Timing
      │
      ▼
Review DRC
      │
      ▼
Generate Bitstream
```

---

# 5. Before Generating the Bitstream

Before generating a bitstream, verify:

```text
Synthesis completed successfully

Implementation completed successfully

Timing is acceptable

DRC errors are resolved

Correct FPGA device is selected

Correct XDC constraints are loaded

Correct top module is selected
```

Generating a bitstream should be the final build step, not the first test of whether the design is correct.

---

# 6. Bitstream Generation Flow

Conceptually:

```text
Implemented Design
       │
       ▼
Device Configuration
       │
       ▼
Bitstream Generator
       │
       ▼
.bit File
```

The generated file can then be transferred to the FPGA.

---

# 7. The `.bit` File

A common Vivado output is:

```text
.bit
```

Example:

```text
caesar_fpga.bit
```

The `.bit` file is commonly used for direct FPGA configuration through tools such as:

```text
Vivado Hardware Manager
JTAG
```

---

# 8. The `.bin` File

Another common format is:

```text
.bin
```

Example:

```text
caesar_fpga.bin
```

A `.bin` file contains raw binary configuration data.

It is often useful for:

```text
SPI Flash
Embedded Programming Tools
Custom Programming Utilities
Firmware Distribution
```

The exact format required depends on the target hardware and configuration method.

---

# 9. `.bit` vs `.bin`

Simplified comparison:

```text
.bit
│
├── Common Vivado programming format
├── Often used with Hardware Manager
└── Contains bitstream metadata/header information

.bin
│
├── Raw binary configuration data
├── Common for flash programming
└── Useful for external programming workflows
```

The correct format depends on how the FPGA board loads firmware.

---

# 10. FPGA Configuration Is Usually Volatile

Most SRAM-based FPGAs lose their configuration when power is removed.

Conceptually:

```text
Power ON
   │
   ▼
Load Bitstream
   │
   ▼
FPGA Runs
   │
   ▼
Power OFF
   │
   ▼
Configuration Lost
```

This means the FPGA must be configured again after the next power-up.

---

# 11. SRAM FPGA Configuration

Many Xilinx FPGA families use SRAM-based configuration memory.

This provides flexibility because the FPGA can be reconfigured many times.

However:

```text
Configuration is volatile
```

Therefore many boards include external non-volatile flash memory.

---

# 12. Configuration Flash

A common hardware architecture is:

```text
SPI Flash
    │
    ▼
FPGA
```

The bitstream is stored in non-volatile flash.

When the board powers on:

```text
Power On
   │
   ▼
FPGA Configuration Logic
   │
   ▼
Read SPI Flash
   │
   ▼
Load FPGA Configuration
   │
   ▼
Start User Design
```

---

# 13. JTAG Programming

One of the easiest development methods is:

```text
JTAG
```

Conceptually:

```text
Development PC
      │
      ▼
USB/JTAG Programmer
      │
      ▼
JTAG
      │
      ▼
FPGA
```

Vivado Hardware Manager can use JTAG to program many FPGA development boards.

---

# 14. JTAG Is Useful During Development

JTAG is excellent for development because:

```text
No flash programming is required

New bitstreams can be loaded quickly

Changes can be tested repeatedly

Vivado debugging tools can use the same connection
```

However, after power is removed, the FPGA usually loses the JTAG-loaded configuration.

---

# 15. Vivado Hardware Manager

Vivado contains:

```text
Hardware Manager
```

which can connect to FPGA hardware.

Typical path:

```text
Flow Navigator
      │
      ▼
Open Hardware Manager
      │
      ▼
Open Target
      │
      ▼
Auto Connect
```

If the FPGA is detected, it appears in the hardware device list.

---

# 16. Programming the FPGA

After the device is detected:

```text
Right-click FPGA Device
        │
        ▼
Program Device
```

Then select the generated:

```text
.bit
```

file.

Conceptually:

```text
Vivado
  │
  ▼
.bit File
  │
  ▼
JTAG
  │
  ▼
FPGA
```

---

# 17. Hardware Server

Vivado uses a service commonly known as:

```text
Hardware Server
```

for communicating with hardware targets.

Conceptually:

```text
Vivado
   │
   ▼
Hardware Server
   │
   ▼
Programming Cable
   │
   ▼
FPGA
```

Hardware Server can also support remote hardware debugging workflows.

---

# 18. Cable Drivers

If the FPGA is not detected through JTAG, one possible issue is the programming cable driver.

During Vivado installation, Windows users may install:

```text
Cable Drivers
```

Without the appropriate driver, the programming adapter may not be accessible.

---

# 19. JTAG Chain

Multiple JTAG-compatible devices may exist in one chain.

Conceptually:

```text
JTAG Programmer
      │
      ▼
Device 1
      │
      ▼
Device 2
      │
      ▼
Device 3
```

Vivado scans the chain and identifies compatible devices.

---

# 20. Programming Does Not Change the Source

Programming an FPGA does not modify:

```text
SystemVerilog Source

XDC Constraints

Vivado Project
```

It only transfers the already-generated configuration data into the hardware.

---

# 21. Configuration Memory Programming

To make the FPGA load firmware automatically after power-up, the board may use:

```text
Configuration Memory
```

Examples include:

```text
SPI NOR Flash

Quad SPI Flash

Dedicated Configuration Flash
```

The correct memory type depends on the board.

---

# 22. SPI Flash

SPI flash is commonly connected as:

```text
FPGA
 │
 ├── CLK
 ├── CS
 ├── DATA
 └── SPI Flash
```

Some boards use:

```text
QSPI
```

where multiple data lines allow faster transfers.

---

# 23. Master SPI Configuration

In a common configuration mode, the FPGA acts as the SPI master.

Conceptually:

```text
Power On
   │
   ▼
FPGA
   │
   ├── Generate SPI Clock
   │
   ▼
Flash
   │
   ▼
Return Configuration Data
   │
   ▼
FPGA Configures Itself
```

---

# 24. Configuration Mode

Xilinx FPGAs may support multiple configuration modes depending on the family.

Examples can include:

```text
JTAG

Master SPI

Slave Serial

SelectMAP
```

The board hardware determines which modes are available.

---

# 25. Mode Pins

Some FPGA families use physical configuration mode pins.

These determine which configuration method the FPGA attempts after reset.

Conceptually:

```text
Mode Pins
   │
   ▼
Configuration Mode
   │
   ├── JTAG
   ├── SPI
   └── Other Mode
```

These pins are normally fixed by the board design.

---

# 26. Creating a `.bin` File

Vivado can generate binary configuration output.

The exact GUI options depend on the Vivado version and device family.

One common project property is related to:

```text
BITSTREAM.GENERAL.BIN_FILE
```

Conceptually, enabling binary output allows the build to produce:

```text
design.bit
design.bin
```

---

# 27. Tcl Example

A Vivado Tcl flow may include:

```tcl
set_property BITSTREAM.GENERAL.BIN_FILE true [current_design]
```

Then:

```tcl
write_bitstream -force output/design.bit
```

Depending on the project/device configuration, a corresponding binary output can also be created.

Always verify the requirements of the target board before using the generated binary for flash programming.

---

# 28. `write_bitstream`

Vivado Tcl supports:

```tcl
write_bitstream
```

Example:

```tcl
write_bitstream -force caesar_fpga.bit
```

This allows bitstream generation to be included in automated build scripts.

---

# 29. Automated Builds

A future build script might contain:

```tcl
synth_design
opt_design
place_design
route_design
report_timing_summary
write_bitstream
```

This converts:

```text
Git Source
```

into:

```text
Release Firmware
```

with minimal manual GUI work.

---

# 30. Bitstream Properties

Vivado provides several bitstream-related configuration properties.

These may control features such as:

```text
Configuration behavior

Compression

Startup behavior

Binary output

Configuration interface
```

The appropriate values depend on the FPGA family and board.

Do not change configuration properties without understanding their hardware impact.

---

# 31. Bitstream Compression

Some devices support:

```text
Bitstream Compression
```

Compression can reduce the amount of configuration data that must be transferred.

Conceptually:

```text
Normal Bitstream
      │
      ▼
Large Configuration Data

Compressed Bitstream
      │
      ▼
Smaller Stored Data
```

This may improve configuration time or reduce flash usage in some designs.

---

# 32. Configuration Time

FPGA startup time depends on factors such as:

```text
Bitstream Size

Configuration Interface

SPI Clock Speed

Bus Width

Flash Performance

Compression
```

A larger FPGA usually requires more configuration data than a smaller FPGA.

---

# 33. DONE Signal

Many FPGA devices provide a configuration status signal commonly called:

```text
DONE
```

Conceptually:

```text
Configuration Starts
       │
       ▼
Bitstream Loads
       │
       ▼
Configuration Completes
       │
       ▼
DONE Asserted
```

The exact behavior is device-specific.

---

# 34. INIT_B

Some Xilinx FPGA families also expose configuration-related signals such as:

```text
INIT_B
```

These signals can help diagnose configuration problems.

Always consult the device configuration documentation for exact behavior.

---

# 35. Startup Sequence

FPGA startup includes multiple stages.

A simplified sequence is:

```text
Power Stable
     │
     ▼
Configuration Reset
     │
     ▼
Load Bitstream
     │
     ▼
Configuration Check
     │
     ▼
Startup
     │
     ▼
User Logic Running
```

Clock and reset logic should account for this startup process.

---

# 36. User Logic Reset

Even after FPGA configuration completes, application logic may still require its own reset sequence.

For example:

```text
FPGA Configured
      │
      ▼
Clock Stable
      │
      ▼
Reset Synchronizer
      │
      ▼
User Reset Released
      │
      ▼
Application Starts
```

This is especially important for interfaces such as PCIe.

---

# 37. PCIe FPGA Startup

A PCIe FPGA board must coordinate several events:

```text
Power

Reference Clock

FPGA Configuration

PERST#

PCIe IP Reset

Link Training

Enumeration
```

Conceptually:

```text
FPGA Configuration
       │
       ▼
PCIe Logic Ready
       │
       ▼
PERST# Released
       │
       ▼
Link Training
       │
       ▼
L0
       │
       ▼
Host Enumeration
```

The exact order and timing depend on platform and device requirements.

---

# 38. PCIe Enumeration After Programming

When a PCIe FPGA is reprogrammed while the host is already running, the host may not always automatically rediscover the endpoint.

Depending on the platform, testing may require:

```text
PCIe Rescan

Device Reset

Slot Reset

System Reboot

Power Cycle
```

Development boards and host systems can behave differently.

---

# 39. FPGA Firmware Is Hardware Configuration

It is useful to remember:

```text
FPGA Firmware
```

is different from normal CPU software.

A CPU executes instructions.

An FPGA bitstream configures hardware resources.

Conceptually:

```text
CPU:
Software → Instructions → Processor

FPGA:
HDL → Bitstream → Hardware Configuration
```

---

# 40. Bitstream Compatibility

A bitstream is normally built for a specific FPGA device.

For example:

```text
XC7A35T
```

firmware should not be assumed to work on:

```text
XC7A75T
```

or another device.

Even closely related FPGAs may have different:

```text
Resources

Device IDs

Package Pinouts

Transceivers

Configuration Data
```

---

# 41. Board Compatibility

Even if two boards use the same FPGA device, the bitstream may still not be compatible.

Why?

Because boards may have different:

```text
Pin Assignments

Clock Sources

PCIe Lane Routing

LED Connections

SPI Flash Devices

Reset Wiring
```

Therefore:

```text
Same FPGA
≠
Same Firmware
```

---

# 42. Build Target Identification

A firmware release should clearly identify the target.

Example:

```text
Project:
CAESAR FPGA Tutorial

FPGA:
XC7A35T

Board:
Example Board A

Vivado:
2026.1

Build:
v1.0.0
```

This reduces accidental programming of incompatible hardware.

---

# 43. Firmware Versioning

Firmware releases should use consistent versioning.

Example:

```text
v1.0.0
v1.1.0
v1.1.1
v2.0.0
```

A version register inside the FPGA can match the release version.

For example:

```text
GitHub Release:
v1.2.0

FPGA VERSION Register:
0x00010200
```

---

# 44. Build Information Register

More advanced FPGA projects can expose build information through BAR registers.

Example:

```text
0x0000 DEVICE_ID
0x0004 VERSION
0x0008 BUILD_ID
0x000C STATUS
```

This allows host software to determine which firmware build is running.

---

# 45. Build ID

A build ID could represent:

```text
Release Number

Git Commit

Build Date

Hardware Revision
```

A simple example:

```systemverilog
localparam logic [31:0] BUILD_ID =
    32'h0000_0001;
```

This makes hardware testing easier.

---

# 46. Release Directory

A clean project can separate generated release files from source.

Example:

```text
release/
│
├── caesar_fpga_v1.0.bit
├── caesar_fpga_v1.0.bin
└── README.txt
```

Generated build outputs should not be mixed randomly throughout the source tree.

---

# 47. Build Directory

Another clean structure is:

```text
build/
│
├── reports/
│
├── checkpoints/
└── bitstreams/
```

For example:

```text
build/bitstreams/caesar_fpga.bit
```

The entire build directory can often be regenerated.

---

# 48. Source vs Release Artifacts

A repository may distinguish between:

```text
Source Files
```

and:

```text
Release Artifacts
```

Source:

```text
src/
constraints/
scripts/
docs/
```

Generated:

```text
build/
```

Published releases:

```text
GitHub Releases
```

This keeps the repository clean.

---

# 49. Should Bitstreams Be Stored in Git?

Generally, large generated bitstreams do not need to be committed every time the source changes.

A cleaner approach is often:

```text
Source Code
→ Git Repository

Stable Bitstream
→ GitHub Release
```

This keeps Git history focused on source changes.

---

# 50. Reproducible Firmware

A good open-source FPGA project should ideally allow another developer to reproduce the bitstream from source.

This requires documenting:

```text
Vivado Version

FPGA Device

Source Files

Constraints

IP Configuration

Build Script

Build Instructions
```

Reproducibility improves trust and maintainability.

---

# 51. Build Metadata

A firmware release can include metadata such as:

```text
Firmware:
CAESAR FPGA

Version:
1.0.0

Vivado:
2026.1

Target:
XC7A35T

Timing:
PASS

Build Date:
2026-xx-xx
```

This is useful when testing multiple firmware versions.

---

# 52. Keep Timing Reports with Releases

For important builds, it can be useful to archive:

```text
Timing Summary

Utilization Report

DRC Report
```

along with release metadata.

Example:

```text
release/
│
├── firmware.bit
├── firmware.bin
├── timing_summary.txt
└── build_info.txt
```

---

# 53. Bitstream Verification

Before publishing a firmware build:

```text
Build
  │
  ▼
Review Timing
  │
  ▼
Program FPGA
  │
  ▼
Test Hardware
  │
  ▼
Verify Interfaces
  │
  ▼
Create Release
```

Never assume a successful bitstream generation guarantees correct hardware behavior.

---

# 54. Programming Errors

Common programming problems include:

```text
FPGA not detected

Wrong bitstream target

JTAG connection failure

Cable driver missing

Board not powered

Wrong JTAG chain

Configuration failure

Incorrect flash type
```

Start debugging from the hardware connection and exact target device.

---

# 55. Wrong Device Error

If Vivado detects:

```text
XC7A35T
```

but the bitstream was built for another FPGA device, programming may fail.

Always confirm:

```text
Detected Device
=
Build Target Device
```

---

# 56. Board Power

A surprisingly common problem is insufficient or missing board power.

A programming cable alone may not power the entire FPGA board.

Verify:

```text
Power Rails

Board LEDs

USB/JTAG Power

External Supply

PCIe Slot Power
```

according to the board design.

---

# 57. JTAG Clock Speed

Some programming setups allow adjustment of:

```text
JTAG Clock Frequency
```

If signal integrity is poor, reducing JTAG speed may sometimes improve programming reliability.

This is a debugging measure, not a substitute for correct board design.

---

# 58. Flash Programming Is Different from FPGA Programming

Programming the FPGA directly:

```text
JTAG
   │
   ▼
FPGA SRAM
```

is temporary.

Programming flash:

```text
JTAG / Programmer
       │
       ▼
SPI Flash
       │
       ▼
Persistent Storage
```

allows the firmware to survive power cycles.

---

# 59. Flash Programming Workflow

A simplified workflow is:

```text
Generate Bitstream
      │
      ▼
Generate Flash Image
      │
      ▼
Detect Configuration Memory
      │
      ▼
Program Flash
      │
      ▼
Verify Flash
      │
      ▼
Power Cycle
      │
      ▼
FPGA Loads Automatically
```

---

# 60. Configuration Memory Size

The flash device must have enough capacity to store the FPGA image.

For example:

```text
Bitstream Size
      │
      ▼
Must Fit
      │
      ▼
Flash Capacity
```

Large FPGA devices may require larger configuration memories.

---

# 61. Flash Image Formats

Depending on the Xilinx device family and configuration workflow, Vivado may generate formats such as:

```text
.bin
.mcs
```

Different programming tools may require different formats.

Always select the format required by the target configuration memory and programming workflow.

---

# 62. `.mcs` Files

An:

```text
.mcs
```

file is commonly associated with configuration-memory programming workflows.

It can contain data prepared for flash devices.

For direct FPGA JTAG programming, `.bit` is often more convenient.

---

# 63. Never Guess Flash Parameters

Before programming configuration flash, verify:

```text
Flash Manufacturer

Flash Model

Capacity

Bus Width

Configuration Mode

Board Wiring
```

Selecting the wrong flash configuration can cause programming or boot failures.

---

# 64. Backup Existing Flash When Appropriate

On development hardware containing an existing vendor image, preserve recovery information when the board vendor provides a supported backup/recovery process.

This makes it easier to restore the board if experimental firmware does not boot correctly.

---

# 65. Programming Workflow for Development

A practical development cycle is:

```text
Edit RTL
  │
  ▼
Synthesis
  │
  ▼
Implementation
  │
  ▼
Timing Check
  │
  ▼
Generate .bit
  │
  ▼
Program via JTAG
  │
  ▼
Test
```

Once the design becomes stable:

```text
Generate Flash Image
      │
      ▼
Program SPI Flash
      │
      ▼
Test Cold Boot
```

---

# 66. Recommended Release Workflow

A professional release process could look like:

```text
Git Commit
    │
    ▼
Clean Vivado Build
    │
    ▼
Timing PASS
    │
    ▼
DRC PASS
    │
    ▼
Generate Bitstream
    │
    ▼
Hardware Test
    │
    ▼
Create Version
    │
    ▼
Publish Release
```

---

# 67. Example Release Names

Instead of:

```text
firmware1.bin
new.bin
final.bin
final2.bin
```

use clear names.

For example:

```text
caesar_fpga-v1.0.0.bit
caesar_fpga-v1.0.0.bin
```

For board-specific builds:

```text
caesar_fpga-board_a-v1.0.0.bit
```

This makes firmware management much easier.

---

# 68. Development vs Release Builds

During development:

```text
build/
```

may contain many temporary builds.

For releases:

```text
release/
```

should only contain verified firmware.

Conceptually:

```text
Development Builds
        │
        ▼
Testing
        │
        ▼
Verified Build
        │
        ▼
Release
```

---

# 69. Bitstream Security

Modern FPGA families may support security features such as:

```text
Bitstream Encryption

Authentication
```

These features are useful when a product needs to protect configuration data or verify firmware authenticity.

The exact capabilities depend on the FPGA family.

---

# 70. Development Projects

For open-source educational projects, encryption is normally unnecessary because the purpose is reproducibility and learning.

A public tutorial should prioritize:

```text
Readable Source

Documented Build Process

Reproducible Firmware

Clear Hardware Targets
```

---

# 71. What We Learned

In this chapter, we learned:

```text
FPGA Configuration
      │
      ├── Bitstream
      ├── .bit
      ├── .bin
      ├── .mcs
      ├── JTAG
      ├── Hardware Manager
      ├── SPI Flash
      ├── Volatile Configuration
      ├── Non-Volatile Configuration
      ├── Firmware Versioning
      └── Release Workflow
```

We now understand how a completed Vivado design becomes firmware that can be loaded into a real FPGA.

---

# Next Chapter

Continue to:

**[Chapter 14 — Programming and Debugging the FPGA](14-program-debug.md)**

In the next chapter, we will focus on testing the firmware on real hardware.

We will cover:

```text
Vivado Hardware Manager
JTAG Debugging
ILA
VIO
Debug Probes
Trigger Conditions
Signal Capture
Hardware Testing
PCIe Debugging
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
