# Chapter 06 — Creating a PCIe Endpoint

[← Previous Chapter](05-verilog-basics.md) | [Back to README](../README.md)

---

## Introduction

PCI Express, commonly called:

```text
PCIe
```

is one of the most important high-speed interfaces used in modern computers.

Graphics cards, network adapters, storage controllers and many FPGA accelerator cards communicate with the host system through PCIe.

An FPGA can also be configured to operate as a PCIe device.

In this chapter, we will learn the basic architecture of PCI Express and understand how an FPGA becomes a PCIe endpoint.

We will cover:

- PCIe architecture
- Root Complex
- Endpoint devices
- PCIe links
- Lanes
- Link training
- Configuration Space
- Vendor ID and Device ID
- PCIe capabilities
- FPGA PCIe IP
- Vivado PCIe workflow

---

# 1. What Is PCI Express?

PCI Express is a high-speed serial communication interface.

It connects devices inside a computer system.

Common PCIe devices include:

```text
GPU
Network Card
NVMe Controller
Capture Card
FPGA Card
Storage Controller
```

A simplified computer architecture looks like:

```text
                     CPU
                      │
                      ▼
                Root Complex
                      │
         ┌────────────┼────────────┐
         │            │            │
         ▼            ▼            ▼
        GPU         NVMe         FPGA
      Endpoint     Endpoint      Endpoint
```

The CPU and chipset communicate with PCIe devices through the:

```text
Root Complex
```

---

# 2. Root Complex

The Root Complex is the host-side controller of the PCIe system.

It connects the processor and system memory to PCIe devices.

Conceptually:

```text
CPU
 │
 ▼
Root Complex
 │
 ├── PCIe Endpoint
 ├── PCIe Endpoint
 └── PCIe Endpoint
```

The Root Complex is responsible for tasks such as:

- PCIe device discovery
- Configuration transactions
- Address routing
- Memory transactions
- Interrupt routing

---

# 3. What Is a PCIe Endpoint?

A PCIe Endpoint is a device connected to the PCIe hierarchy.

Examples:

```text
Graphics Card
Network Adapter
Storage Controller
FPGA Device
```

When an FPGA is configured with PCIe logic, it can behave as a PCIe Endpoint.

Conceptually:

```text
┌──────────────────────────────┐
│            FPGA              │
│                              │
│   ┌──────────────────────┐   │
│   │      User Logic      │   │
│   └──────────┬───────────┘   │
│              │               │
│   ┌──────────▼───────────┐   │
│   │     PCIe Logic       │   │
│   └──────────┬───────────┘   │
│              │               │
└──────────────┼───────────────┘
               │
               │ PCIe
               │
┌──────────────▼───────────────┐
│          Host System         │
└──────────────────────────────┘
```

The PCIe logic handles the protocol between the FPGA and the host.

---

# 4. PCIe Links

PCIe uses point-to-point links.

Unlike older shared bus architectures, each device communicates over its own dedicated link.

Example:

```text
Root Complex
     │
     ├──── PCIe Link ──── GPU
     │
     ├──── PCIe Link ──── NVMe
     │
     └──── PCIe Link ──── FPGA
```

Each link contains one or more:

```text
Lanes
```

---

# 5. PCIe Lanes

A PCIe lane contains two differential signal pairs.

One pair is used for transmission:

```text
TX
```

and one pair is used for reception:

```text
RX
```

Conceptually:

```text
Device A                     Device B

TX+  ──────────────────────▶ RX+
TX-  ──────────────────────▶ RX-

RX+  ◀────────────────────── TX+
RX-  ◀────────────────────── TX-
```

PCIe links can contain different numbers of lanes.

Common configurations include:

```text
x1
x2
x4
x8
x16
```

For example:

```text
PCIe x1
```

uses one lane.

```text
PCIe x4
```

uses four lanes.

---

# 6. PCIe Generations

PCI Express has evolved through multiple generations.

Common generations include:

```text
PCIe Gen1
PCIe Gen2
PCIe Gen3
PCIe Gen4
PCIe Gen5
```

Each generation increases the signaling rate and available bandwidth.

The actual generation supported by an FPGA design depends on:

- FPGA family
- PCIe hard block
- Transceiver capability
- Board layout
- Vivado IP configuration

---

# 7. FPGA PCIe Hardware

Not every FPGA implements PCIe in exactly the same way.

Many Xilinx/AMD FPGA families contain dedicated high-speed transceivers and PCIe-related hard IP.

A simplified architecture may look like:

```text
FPGA Fabric
    │
    ▼
PCIe IP
    │
    ▼
High-Speed Transceivers
    │
    ▼
PCIe Connector
```

The PCIe IP handles much of the protocol complexity.

The FPGA designer then connects custom logic to the PCIe interface.

---

# 8. PCIe Protocol Layers

PCI Express is organized into several protocol layers.

A simplified model is:

```text
Transaction Layer
       │
       ▼
Data Link Layer
       │
       ▼
Physical Layer
```

Each layer has a different responsibility.

---

## Transaction Layer

The Transaction Layer handles PCIe requests and completions.

Examples include:

```text
Memory Read
Memory Write
Configuration Read
Configuration Write
Completion
```

These transactions are carried using:

```text
Transaction Layer Packets
```

also known as:

```text
TLPs
```

We will study TLPs in a later chapter.

---

## Data Link Layer

The Data Link Layer provides reliable transmission between directly connected PCIe devices.

It manages mechanisms such as:

- Packet sequence numbers
- Error detection
- Link-level acknowledgements
- Retransmission

---

## Physical Layer

The Physical Layer handles the actual electrical PCIe link.

It includes:

- High-speed serial signaling
- Lane management
- Link training
- Encoding
- Transceivers

---

# 9. PCIe Link Training

When a computer starts, the PCIe link must be established.

This process is called:

```text
Link Training
```

The PCIe devices negotiate parameters such as:

```text
Link Width
Link Speed
Lane Configuration
```

Conceptually:

```text
Power On
   │
   ▼
Detect
   │
   ▼
Polling
   │
   ▼
Configuration
   │
   ▼
Link Up
```

The PCIe specification defines a state machine called:

```text
LTSSM
```

which stands for:

```text
Link Training and Status State Machine
```

---

# 10. LTSSM

The LTSSM manages the state of the PCIe link.

A simplified sequence looks like:

```text
Detect
  │
  ▼
Polling
  │
  ▼
Configuration
  │
  ▼
L0
```

The:

```text
L0
```

state represents a normal active PCIe link.

If the FPGA PCIe design does not reach L0, the host may not detect the device correctly.

---

# 11. PCIe Enumeration

After the PCIe link becomes active, the host begins discovering devices.

This process is called:

```text
Enumeration
```

The host reads the device's:

```text
Configuration Space
```

to determine what the device is.

The operating system may discover information such as:

```text
Vendor ID
Device ID
Class Code
BARs
Capabilities
Interrupt Support
```

---

# 12. Configuration Space

Every PCIe device exposes a configuration space.

This contains information used by firmware and the operating system.

A simplified view:

```text
Configuration Space
│
├── Vendor ID
├── Device ID
├── Command
├── Status
├── Revision ID
├── Class Code
├── BAR0
├── BAR1
├── BAR2
├── BAR3
├── BAR4
├── BAR5
└── Capabilities
```

This information helps the host understand what the device supports.

---

# 13. Vendor ID and Device ID

Two important PCIe configuration fields are:

```text
Vendor ID
Device ID
```

The Vendor ID identifies the device vendor.

The Device ID identifies a particular device model or implementation.

Conceptually:

```text
Vendor ID
    │
    ▼
Who made the device?

Device ID
    │
    ▼
Which device is it?
```

For experimental FPGA projects, configuration values should be chosen responsibly and should not impersonate unrelated hardware.

---

# 14. Class Code

The PCIe Class Code describes the general category of the device.

Examples of device categories include:

```text
Network Controller
Display Controller
Storage Controller
Multimedia Controller
Processing Accelerator
Other Device
```

The operating system may use the Class Code when determining how to handle the device.

---

# 15. Base Address Registers

PCIe devices may expose:

```text
BARs
```

which stands for:

```text
Base Address Registers
```

BARs allow the host to map regions of a PCIe device into the system address space.

Conceptually:

```text
Host CPU
   │
   ▼
Memory Address
   │
   ▼
PCIe BAR
   │
   ▼
FPGA Register Logic
```

This makes it possible for software to access FPGA registers through memory-mapped I/O.

We will study BARs in detail in:

```text
Chapter 07
```

---

# 16. Memory-Mapped Registers

One common FPGA PCIe architecture is to create a register block behind a BAR.

Example:

```text
Host
 │
 ▼
PCIe
 │
 ▼
BAR0
 │
 ▼
Register Block
 │
 ├── CONTROL
 ├── STATUS
 ├── VERSION
 └── DATA
```

For example:

```text
BAR0 + 0x00 → CONTROL
BAR0 + 0x04 → STATUS
BAR0 + 0x08 → VERSION
BAR0 + 0x0C → DATA
```

The host can read or write these registers depending on the design.

---

# 17. PCIe Interrupts

PCIe devices can notify the host using interrupts.

Modern PCIe devices commonly use:

```text
MSI
MSI-X
```

rather than traditional shared interrupt lines.

Interrupts can be used to signal events such as:

```text
Operation Completed
Data Available
Error Detected
Status Changed
```

We will discuss interrupts later when building more advanced PCIe interfaces.

---

# 18. FPGA PCIe IP

Creating an entire PCIe protocol implementation manually would be extremely complex.

Vivado provides PCIe-related IP blocks that handle much of the low-level protocol.

A typical FPGA architecture may look like:

```text
                    FPGA
                     │
     ┌───────────────┼───────────────┐
     │                               │
     ▼                               ▼
 User Logic                      PCIe IP
     │                               │
     └───────────────┬───────────────┘
                     │
                     ▼
                Transceivers
                     │
                     ▼
                PCIe Connector
```

The exact available IP depends on the selected FPGA family.

---

# 19. Vivado IP Catalog

Vivado contains an:

```text
IP Catalog
```

which provides configurable FPGA IP blocks.

To open it:

```text
Flow Navigator
      │
      ▼
IP Catalog
```

You can then search for:

```text
PCI Express
```

Depending on your FPGA family, Vivado may display one or more compatible PCIe IP options.

---

# 20. Creating PCIe IP

A typical PCIe IP workflow looks like:

```text
Open Vivado
     │
     ▼
IP Catalog
     │
     ▼
Search PCI Express
     │
     ▼
Select Compatible PCIe IP
     │
     ▼
Configure Link
     │
     ▼
Configure Device Settings
     │
     ▼
Configure BARs
     │
     ▼
Generate IP
```

The exact configuration window depends on the FPGA family and Vivado version.

---

# 21. PCIe IP Configuration

A PCIe IP configuration may include settings such as:

```text
Link Speed
Link Width
Vendor ID
Device ID
Class Code
BAR Configuration
MSI / MSI-X
Reference Clock
Interface Width
```

These values determine how the PCIe endpoint behaves.

---

# 22. Link Width

A PCIe design may support widths such as:

```text
x1
x2
x4
x8
```

The available options depend on the FPGA and board design.

For example:

```text
FPGA PCIe Endpoint
        │
        ▼
      x1 Link
```

uses one PCIe lane.

A wider link can provide more bandwidth, but requires more transceiver lanes and appropriate PCB routing.

---

# 23. Reference Clock

PCIe hardware requires a reference clock.

A common PCIe reference clock is:

```text
100 MHz
```

The board design routes this clock to the FPGA transceiver or PCIe logic.

Conceptually:

```text
Host PCIe Clock
      │
      ▼
FPGA Reference Clock Input
      │
      ▼
PCIe IP
```

Clocking is one of the most important parts of a stable PCIe design.

---

# 24. PCIe Reset

PCIe devices also receive a reset signal from the host platform.

This is commonly associated with:

```text
PERST#
```

The `#` indicates that the signal is active low.

Conceptually:

```text
PERST# = 0
      │
      ▼
PCIe Device Held in Reset

PERST# = 1
      │
      ▼
PCIe Device Can Initialize
```

The FPGA design must handle PCIe reset correctly.

---

# 25. Example FPGA PCIe Architecture

A simplified PCIe FPGA design may look like:

```text
                  Host PC
                     │
                     │ PCIe
                     ▼
        ┌─────────────────────────┐
        │          FPGA           │
        │                         │
        │   ┌─────────────────┐   │
        │   │     PCIe IP     │   │
        │   └────────┬────────┘   │
        │            │            │
        │   ┌────────▼────────┐   │
        │   │  BAR Interface  │   │
        │   └────────┬────────┘   │
        │            │            │
        │   ┌────────▼────────┐   │
        │   │ Register Block  │   │
        │   └────────┬────────┘   │
        │            │            │
        │   ┌────────▼────────┐   │
        │   │   User Logic    │   │
        │   └─────────────────┘   │
        │                         │
        └─────────────────────────┘
```

This architecture is common in FPGA PCIe development.

---

# 26. PCIe Endpoint Data Flow

Suppose host software reads an FPGA register.

The transaction may conceptually flow like:

```text
CPU
 │
 ▼
PCIe Root Complex
 │
 ▼
PCIe Link
 │
 ▼
FPGA PCIe IP
 │
 ▼
BAR Logic
 │
 ▼
Register Block
 │
 ▼
Requested Data
 │
 ▼
PCIe Completion
 │
 ▼
Host
```

The PCIe IP handles the protocol transport while the FPGA user logic determines what data should be returned.

---

# 27. HDL and PCIe

The PCIe IP itself is only one part of the project.

Custom SystemVerilog modules may implement logic such as:

```text
BAR Controller
Register Decoder
Status Registers
Control Registers
FIFO
Memory Interface
Interrupt Logic
User Logic
```

The project may eventually look like:

```text
src/
│
├── top.sv
│
├── pcie/
│   ├── pcie_wrapper.sv
│   ├── bar_controller.sv
│   └── register_block.sv
│
└── modules/
    ├── reset_sync.sv
    └── counter.sv
```

---

# 28. PCIe Endpoint vs User Logic

It is useful to separate:

```text
PCIe Transport
```

from:

```text
Application Logic
```

Conceptually:

```text
PCIe Transport
      │
      ▼
Register / Data Interface
      │
      ▼
Application Logic
```

This makes the FPGA design easier to maintain.

The PCIe layer handles communication.

The user logic handles the actual device functionality.

---

# 29. Debugging a PCIe Endpoint

When debugging a PCIe FPGA design, useful questions include:

```text
Is the reference clock present?

Is PCIe reset released?

Does the LTSSM reach L0?

What link speed was negotiated?

What link width was negotiated?

Does the host enumerate the device?

Is Configuration Space readable?

Are BARs assigned?

Can the host access registers?
```

These questions help narrow down where a PCIe design is failing.

---

# 30. Host-Side Detection

After a PCIe endpoint is working correctly, the operating system should detect it.

On Windows, PCIe devices can typically be inspected using:

```text
Device Manager
```

On Linux, devices can be inspected using tools such as:

```text
lspci
```

The exact host-side workflow will be covered later when we test a complete FPGA PCIe design.

---

# 31. PCIe Development Flow

A typical PCIe FPGA development workflow looks like:

```text
Choose FPGA
     │
     ▼
Create Vivado Project
     │
     ▼
Configure PCIe IP
     │
     ▼
Configure Clock / Reset
     │
     ▼
Configure BARs
     │
     ▼
Add User Logic
     │
     ▼
Synthesis
     │
     ▼
Implementation
     │
     ▼
Generate Bitstream
     │
     ▼
Program FPGA
     │
     ▼
Boot Host
     │
     ▼
PCIe Enumeration
     │
     ▼
Test Device
```

---

# 32. Important Design Principle

A PCIe endpoint should be designed as a clear hierarchy.

For example:

```text
top
 │
 ├── pcie_wrapper
 │
 │    ├── PCIe IP
 │    ├── BAR Interface
 │    └── Interrupt Interface
 │
 ├── register_block
 │
 ├── reset_logic
 │
 └── user_logic
```

This separation makes future development much easier.

---

# 33. What We Learned

In this chapter, we learned:

```text
PCI Express
     │
     ├── Root Complex
     ├── Endpoint
     ├── PCIe Link
     ├── Lanes
     ├── Link Training
     ├── LTSSM
     ├── Enumeration
     ├── Configuration Space
     ├── Vendor / Device ID
     ├── BARs
     ├── Interrupts
     └── FPGA PCIe IP
```

We now understand the basic architecture required for an FPGA to operate as a PCIe endpoint.

---

# Next Chapter

Continue to:

**[Chapter 07 — PCIe BAR Configuration](07-pcie-bar.md)**

In the next chapter, we will study PCIe Base Address Registers in detail.

We will learn:

```text
What BARs Are
Memory-Mapped I/O
BAR Address Space
32-bit and 64-bit BARs
BAR Size
Register Maps
Address Decoding
FPGA Register Interfaces
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
