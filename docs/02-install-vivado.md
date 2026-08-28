# Chapter 02 — Installing AMD/Xilinx Vivado

[← Previous Chapter](01-introduction.md) | [Back to README](../README.md)

---

## Introduction

In this chapter, we will install **AMD/Xilinx Vivado**, the primary development environment used throughout this tutorial.

Vivado provides the tools required for:

- HDL development
- FPGA synthesis
- Implementation
- Place and route
- Timing analysis
- IP configuration
- Bitstream generation
- FPGA programming
- Hardware debugging

By the end of this chapter, you should have a working Vivado installation ready for FPGA development.

---

# 1. Download Vivado

Vivado can be downloaded from the official AMD website:

**AMD Vivado Design Suite**

https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html

AMD provides several installation methods.

For most Windows users, the easiest option is:

```text
AMD Unified Installer for FPGAs & Adaptive SoCs
Windows Self Extracting Web Installer
```

The Web Installer allows you to download only the tools and FPGA device families that you actually need.

---

### Vivado Download Page

<p align="center">
  <img src="../images/ch02/01-amd-download.png" width="850">
</p>

<p align="center">
  <i>Figure 2.1 — AMD Vivado download page.</i>
</p>

---

# 2. Launch the Unified Installer

Run the installer after the download completes.

The AMD Unified Installer will start.

Click:

```text
Next
```

You may be asked to sign in using your AMD account.

If you do not already have an AMD account, create one before continuing.

---

<p align="center">
  <img src="../images/ch02/02-unified-installer.png" width="750">
</p>

<p align="center">
  <i>Figure 2.2 — AMD Unified Installer.</i>
</p>

---

# 3. Select Installation Type

After signing in, the installer will ask how you want to install the software.

For most users, select:

```text
Download and Install Now
```

Then click:

```text
Next
```

This option downloads only the components required for your selected configuration.

---

<p align="center">
  <img src="../images/ch02/03-install-type.png" width="750">
</p>

<p align="center">
  <i>Figure 2.3 — Selecting Download and Install Now.</i>
</p>

---

# 4. Select Vivado

The installer may display multiple AMD development products.

For FPGA development in this tutorial, make sure that:

```text
Vivado
```

is included in your installation.

Vivado contains the tools required for:

```text
HDL Design
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
```

---

<p align="center">
  <img src="../images/ch02/04-vivado-selection.png" width="800">
</p>

<p align="center">
  <i>Figure 2.4 — Selecting Vivado in the AMD installer.</i>
</p>

---

# 5. Select FPGA Device Support

This is one of the most important installation steps.

Vivado supports many different AMD/Xilinx FPGA families.

Installing every device family is normally unnecessary and can consume a large amount of disk space.

Select only the FPGA families you plan to use.

---

## Example: Artix-7

Many PCIe FPGA development boards use devices from the:

```text
AMD/Xilinx Artix-7
```

family.

Examples include devices based on:

```text
XC7A35T
XC7A75T
XC7A100T
XC7A200T
```

If your development board uses one of these devices, make sure the appropriate **7 Series / Artix-7 device support** is installed.

---

<p align="center">
  <img src="../images/ch02/05-device-selection.png" width="850">
</p>

<p align="center">
  <i>Figure 2.5 — Selecting the required FPGA device families.</i>
</p>

---

## Important

Always check the exact FPGA model installed on your development board.

The device name is normally printed directly on the FPGA package.

Example:

```text
XC7A35T
```

The device name tells us:

```text
XC7  → Xilinx 7 Series

A    → Artix

35T  → Device size / family member
```

Selecting the correct FPGA family is required before Vivado can create a project targeting that device.

---

# 6. Installation Components

The installer allows you to customize which development tools are installed.

For the FPGA projects used in this tutorial, the important components are generally:

```text
Vivado
FPGA Device Support
Hardware Tools
Cable Drivers
```

Additional AMD tools may be useful for other development workflows but are not required for the basic FPGA projects in this tutorial.

---

# 7. Install Cable Drivers

Vivado communicates with FPGA programming hardware through JTAG and other supported interfaces.

On Windows, make sure:

```text
Install Cable Drivers
```

is enabled when available.

These drivers are used by Vivado Hardware Manager to communicate with supported FPGA programming hardware.

---

<p align="center">
  <img src="../images/ch02/06-cable-drivers.png" width="800">
</p>

<p align="center">
  <i>Figure 2.6 — Vivado cable driver installation option.</i>
</p>

---

# 8. Choose the Installation Directory

Choose where Vivado should be installed.

For example:

```text
C:\AMD\
```

or another suitable location.

Avoid unusual paths and make sure sufficient disk space is available.

The exact storage requirement depends heavily on the tools and FPGA device families selected.

Installing only the required devices can significantly reduce the installation size.

---

# 9. Review Installation Summary

Before installation begins, Vivado displays an installation summary.

Check:

```text
✓ Vivado

✓ Required FPGA family

✓ Hardware tools

✓ Cable drivers

✓ Installation directory
```

Then click:

```text
Install
```

The installer will download and install the selected components.

Installation time depends on:

- Internet connection
- Selected FPGA families
- Selected development tools
- Storage performance

---

# 10. Launch Vivado

After installation completes, launch:

```text
Vivado
```

You should see the Vivado start screen.

---

<p align="center">
  <img src="../images/ch02/07-vivado-start.png" width="900">
</p>

<p align="center">
  <i>Figure 2.7 — Vivado Quick Start screen.</i>
</p>

---

# 11. Vivado Quick Start

The main Vivado start screen provides several important options.

### Create Project

Creates a new FPGA development project.

We will use this in the next chapter.

### Open Project

Opens an existing Vivado project.

### Open Hardware Manager

Used to communicate with physical FPGA hardware.

Hardware Manager can be used for:

- Detecting FPGA devices
- JTAG programming
- Bitstream programming
- Flash programming
- Hardware debugging
- ILA debugging

---

# 12. Verify the Installation

Before continuing, verify that Vivado starts correctly.

You should be able to reach:

```text
Vivado
   │
   ▼
Quick Start
   │
   ├── Create Project
   │
   ├── Open Project
   │
   └── Open Hardware Manager
```

If this screen appears correctly, the basic Vivado installation is complete.

---

# 13. Optional — Verify Hardware Connection

If you already have an FPGA board and JTAG programmer connected, you can test the hardware interface.

Open:

```text
Vivado
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

If the drivers and hardware are configured correctly, Vivado should be able to detect compatible FPGA hardware.

Do not worry if you do not have hardware connected yet.

We will cover FPGA programming in a later chapter.

---

# Installation Complete

At this point you should have:

```text
✓ Vivado installed

✓ FPGA device support installed

✓ Hardware tools installed

✓ Cable drivers installed

✓ Vivado successfully launching
```

Your FPGA development environment is now ready.

---

# Next Chapter

Continue to:

**[Chapter 03 — Creating Your First Vivado Project](03-create-project.md)**

In the next chapter we will create our first FPGA project and learn how Vivado organizes:

```text
Sources
Constraints
IP
Simulation
Synthesis
Implementation
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
