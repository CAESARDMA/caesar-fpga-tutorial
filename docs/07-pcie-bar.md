# Chapter 07 — PCIe BAR Configuration

[← Previous Chapter](06-pcie-endpoint.md) | [Back to README](../README.md)

---

## Introduction

In the previous chapter, we learned how an FPGA can operate as a PCIe endpoint.

Now we will focus on one of the most important PCIe concepts:

```text
BAR
```

BAR stands for:

```text
Base Address Register
```

A BAR allows the operating system to map part of a PCIe device into the host system address space.

For FPGA developers, BARs are commonly used to expose:

- Control registers
- Status registers
- Device information
- FIFOs
- Memory windows
- Custom hardware interfaces

In this chapter, we will cover:

- What a BAR is
- How BARs are assigned
- Memory-mapped I/O
- 32-bit BARs
- 64-bit BARs
- BAR sizing
- Register maps
- Address decoding
- FPGA register blocks
- Read and write operations

---

# 1. What Is a PCIe BAR?

A PCIe endpoint can expose one or more memory regions to the host.

These regions are described using Base Address Registers.

Conceptually:

```text
Host CPU
   │
   ▼
System Address Space
   │
   ▼
PCIe BAR
   │
   ▼
FPGA Logic
```

The operating system assigns an address range to the BAR during PCIe enumeration.

For example:

```text
BAR0
Base Address:
0xD0000000

Size:
64 KB
```

The host may then access addresses such as:

```text
0xD0000000
0xD0000004
0xD0000008
0xD000000C
```

These accesses are forwarded to the PCIe device.

---

# 2. BARs in PCIe Configuration Space

A standard PCIe endpoint can contain several BAR registers.

Conceptually:

```text
PCIe Configuration Space
│
├── Vendor ID
├── Device ID
├── Command
├── Status
├── Revision ID
├── Class Code
│
├── BAR0
├── BAR1
├── BAR2
├── BAR3
├── BAR4
└── BAR5
```

Not every device uses all BARs.

A simple FPGA design may only use:

```text
BAR0
```

while a more complex design may expose several regions.

---

# 3. Memory-Mapped I/O

BARs are commonly used for:

```text
MMIO
```

which means:

```text
Memory-Mapped I/O
```

The operating system maps device registers into the host address space.

This allows software to access hardware using memory-style reads and writes.

Conceptually:

```text
Software
   │
   ▼
Memory Read / Write
   │
   ▼
PCIe Root Complex
   │
   ▼
PCIe Endpoint
   │
   ▼
BAR
   │
   ▼
FPGA Register
```

---

# 4. Example BAR Register Map

Suppose our FPGA exposes:

```text
BAR0
```

with a small register block.

We could define:

```text
Offset      Register
-------------------------
0x0000      DEVICE_ID
0x0004      VERSION
0x0008      CONTROL
0x000C      STATUS
0x0010      DATA
```

The host sees these registers relative to the BAR base address.

For example, if:

```text
BAR0 Base = 0xD0000000
```

then:

```text
DEVICE_ID = 0xD0000000
VERSION   = 0xD0000004
CONTROL   = 0xD0000008
STATUS    = 0xD000000C
DATA      = 0xD0000010
```

---

# 5. BAR Base Address

The FPGA normally does not decide the final host address of a BAR.

During system startup, firmware or the operating system assigns the BAR address.

Conceptually:

```text
PCIe Endpoint
     │
     ▼
Reports BAR Requirements
     │
     ▼
Host Allocates Address Space
     │
     ▼
BAR Base Address Assigned
```

The FPGA primarily works with:

```text
BAR-relative offsets
```

rather than hard-coded physical host addresses.

---

# 6. BAR Address Decoding

Inside the FPGA, the logic usually examines the offset of each BAR access.

Example:

```text
BAR0 Access
    │
    ▼
Address Offset
    │
    ├── 0x0000 → DEVICE_ID
    ├── 0x0004 → VERSION
    ├── 0x0008 → CONTROL
    ├── 0x000C → STATUS
    └── 0x0010 → DATA
```

This is called:

```text
Address Decoding
```

---

# 7. Simple Register Decoder

A simplified SystemVerilog register decoder might look like:

```systemverilog
always_comb begin

    read_data = 32'h00000000;

    case (address)

        16'h0000:
            read_data = 32'h43414553;

        16'h0004:
            read_data = 32'h00010000;

        16'h0008:
            read_data = control_reg;

        16'h000C:
            read_data = status_reg;

        default:
            read_data = 32'h00000000;

    endcase

end
```

This maps addresses to registers.

For example:

```text
0x0000
```

returns:

```text
0x43414553
```

which can be interpreted as ASCII:

```text
CAES
```

---

# 8. Read-Only Registers

Some registers should only be readable by the host.

Examples include:

```text
Device Identifier
Firmware Version
Hardware Revision
Status
Capabilities
```

Example:

```systemverilog
localparam logic [31:0] DEVICE_ID =
    32'h43414553;
```

Then:

```systemverilog
case (address)

    16'h0000:
        read_data = DEVICE_ID;

endcase
```

---

# 9. Read/Write Registers

Other registers may be writable.

For example:

```text
CONTROL
```

The host may write a value to control FPGA behavior.

Example:

```systemverilog
logic [31:0] control_reg;

always_ff @(posedge clk) begin

    if (!reset_n)
        control_reg <= 32'h00000000;

    else if (write_enable) begin

        if (address == 16'h0008)
            control_reg <= write_data;

    end

end
```

Now the host can change:

```text
control_reg
```

through a PCIe write transaction.

---

# 10. Read and Write Paths

A register block normally has two basic paths.

Read path:

```text
Host Read
   │
   ▼
PCIe BAR
   │
   ▼
Address Decoder
   │
   ▼
Register
   │
   ▼
Read Data
   │
   ▼
Host
```

Write path:

```text
Host Write
   │
   ▼
PCIe BAR
   │
   ▼
Address Decoder
   │
   ▼
Register
```

---

# 11. Example Register Block

A simplified register block may look like:

```systemverilog
module register_block (
    input  logic        clk,
    input  logic        reset_n,

    input  logic        write_enable,
    input  logic [15:0] address,
    input  logic [31:0] write_data,

    output logic [31:0] read_data
);

    logic [31:0] control_reg;

    logic [31:0] status_reg;

    assign status_reg = 32'h00000001;

    always_ff @(posedge clk) begin

        if (!reset_n)
            control_reg <= 32'h00000000;

        else if (write_enable) begin

            case (address)

                16'h0008:
                    control_reg <= write_data;

                default:
                    control_reg <= control_reg;

            endcase

        end

    end

    always_comb begin

        read_data = 32'h00000000;

        case (address)

            16'h0000:
                read_data = 32'h43414553;

            16'h0004:
                read_data = 32'h00010000;

            16'h0008:
                read_data = control_reg;

            16'h000C:
                read_data = status_reg;

            default:
                read_data = 32'h00000000;

        endcase

    end

endmodule
```

---

# 12. Register Map for the Example

The previous module implements:

```text
Offset    Name        Access    Description
------------------------------------------------
0x0000    DEVICE_ID   RO        Device identifier
0x0004    VERSION     RO        Firmware version
0x0008    CONTROL     RW        Control register
0x000C    STATUS      RO        Status register
```

Where:

```text
RO = Read Only
RW = Read / Write
```

---

# 13. Why Register Maps Matter

A clear register map creates a stable interface between:

```text
FPGA Hardware
```

and:

```text
Host Software
```

For example:

```text
Host Driver / Application
        │
        ▼
Register Definitions
        │
        ▼
PCIe BAR
        │
        ▼
FPGA Register Block
```

Both sides need to agree on:

- Register offsets
- Register widths
- Read/write permissions
- Bit definitions
- Reset values

---

# 14. Register Bit Fields

A single register may contain multiple control bits.

Example:

```text
CONTROL Register
Offset: 0x0008
```

Could contain:

```text
Bit 0     ENABLE
Bit 1     RESET
Bit 2     INTERRUPT_ENABLE
Bit 3     LOOPBACK_ENABLE
Bits 31:4 Reserved
```

Conceptually:

```text
31                         4 3 2 1 0
┌──────────────────────────┬─┬─┬─┬─┐
│        Reserved          │L│I│R│E│
└──────────────────────────┴─┴─┴─┴─┘
```

---

# 15. Accessing Register Bits

In SystemVerilog:

```systemverilog
wire enable;

assign enable = control_reg[0];
```

Another bit:

```systemverilog
wire interrupt_enable;

assign interrupt_enable = control_reg[2];
```

This allows software to control individual FPGA functions.

---

# 16. 32-Bit BARs

PCIe BARs can describe 32-bit memory regions.

A 32-bit BAR uses one BAR register.

Conceptually:

```text
BAR0
   │
   ▼
32-bit Address Region
```

For small MMIO register regions, this may be sufficient.

---

# 17. 64-Bit BARs

PCIe also supports 64-bit memory BARs.

A 64-bit BAR consumes two consecutive BAR registers.

For example:

```text
BAR0 + BAR1
```

may together describe one 64-bit address region.

Conceptually:

```text
BAR0
 │
 ├── Lower Address Bits
 │
BAR1
 │
 └── Upper Address Bits
```

This allows BAR regions to be placed above the 4 GB boundary.

---

# 18. BAR Size

A BAR also defines the amount of address space required.

Examples:

```text
4 KB
16 KB
64 KB
1 MB
16 MB
```

A simple FPGA register interface usually does not require a very large BAR.

For example:

```text
BAR0 Size = 64 KB
```

provides offsets from:

```text
0x0000
```

through:

```text
0xFFFF
```

---

# 19. Why BAR Sizes Are Powers of Two

PCIe BAR sizes are generally aligned to powers of two.

Examples:

```text
4 KB
8 KB
16 KB
32 KB
64 KB
128 KB
256 KB
```

This simplifies address decoding and allocation.

For example:

```text
64 KB = 0x10000 bytes
```

---

# 20. BAR Alignment

BAR regions are aligned according to their size.

For example, a:

```text
64 KB BAR
```

would normally be aligned on a:

```text
64 KB boundary
```

Conceptually:

```text
Valid:
0xD0000000

Invalid example:
0xD0001234
```

The host PCIe resource allocator handles this alignment.

---

# 21. Prefetchable vs Non-Prefetchable

Memory BARs may be marked as:

```text
Prefetchable
```

or:

```text
Non-Prefetchable
```

For control and status registers, designers commonly use:

```text
Non-Prefetchable
```

because reads may have side effects or values may change dynamically.

Large memory buffers may sometimes use prefetchable memory depending on the architecture.

---

# 22. BAR0 for Register Access

For this tutorial, a simple architecture is:

```text
BAR0
 │
 ▼
Register Block
```

Example:

```text
BAR0
│
├── 0x0000 DEVICE_ID
├── 0x0004 VERSION
├── 0x0008 CONTROL
├── 0x000C STATUS
└── 0x0010 DATA
```

This provides a clean interface for learning PCIe MMIO.

---

# 23. BAR1 for Memory

A more advanced project might use:

```text
BAR0
```

for registers and:

```text
BAR1
```

for a larger memory region.

Example:

```text
BAR0
   │
   ▼
Control / Status Registers


BAR1
   │
   ▼
Memory Window
```

This separation is common in hardware designs.

---

# 24. PCIe BAR Access Flow

Suppose the host reads:

```text
BAR0 + 0x0004
```

The request flows conceptually as:

```text
Host CPU
   │
   ▼
MMIO Read
   │
   ▼
Root Complex
   │
   ▼
PCIe TLP
   │
   ▼
FPGA PCIe IP
   │
   ▼
BAR0 Decoder
   │
   ▼
Offset 0x0004
   │
   ▼
VERSION Register
   │
   ▼
Read Data
   │
   ▼
Completion TLP
   │
   ▼
Host
```

---

# 25. TLP Connection

BAR operations eventually become PCIe:

```text
TLPs
```

For example:

```text
Host MMIO Read
       │
       ▼
Memory Read Request TLP
```

and:

```text
Host MMIO Write
       │
       ▼
Memory Write Request TLP
```

Read requests normally require the endpoint to return a completion.

Writes are normally posted transactions.

We will cover these concepts in detail in:

```text
Chapter 08
```

---

# 26. Byte Enables

PCIe writes do not always modify every byte in a 32-bit register.

The protocol can include byte enables.

For example:

```text
Register:
0x11223344
```

A write might update only one byte.

Therefore, more advanced register logic may need to support:

```text
Byte Enable
```

or:

```text
Write Strobe
```

signals.

A conceptual interface may be:

```systemverilog
input logic [3:0] byte_enable;
```

Each bit corresponds to one byte of a 32-bit data word.

---

# 27. Example Byte Write Logic

A simplified implementation could be:

```systemverilog
if (write_enable && address == 16'h0008) begin

    if (byte_enable[0])
        control_reg[7:0] <= write_data[7:0];

    if (byte_enable[1])
        control_reg[15:8] <= write_data[15:8];

    if (byte_enable[2])
        control_reg[23:16] <= write_data[23:16];

    if (byte_enable[3])
        control_reg[31:24] <= write_data[31:24];

end
```

This preserves bytes that were not selected by the transaction.

---

# 28. Invalid Addresses

The host may access an address that is not implemented.

For example:

```text
BAR0 + 0x1234
```

when the FPGA only implements:

```text
0x0000 - 0x0010
```

A simple register block may return:

```text
0x00000000
```

for undefined reads.

Example:

```systemverilog
default:
    read_data = 32'h00000000;
```

More complex hardware may implement specific error handling.

---

# 29. Register Reset Values

Every writable register should have a clearly defined reset value.

Example:

```text
CONTROL
Reset Value:
0x00000000
```

SystemVerilog:

```systemverilog
if (!reset_n)
    control_reg <= 32'h00000000;
```

This ensures predictable FPGA behavior after reset.

---

# 30. Version Register

A firmware version register is useful for identifying the FPGA build.

Example:

```text
VERSION
Offset:
0x0004

Value:
0x00010002
```

This could represent:

```text
Version 1.2
```

Host software can read this value and confirm compatibility.

---

# 31. Device Identifier Register

A simple custom identifier is also useful.

For example:

```systemverilog
32'h43414553
```

ASCII interpretation:

```text
43 = C
41 = A
45 = E
53 = S
```

Together:

```text
CAES
```

This is a convenient demonstration value for the tutorial.

---

# 32. Recommended Register Documentation

A real FPGA project should document registers clearly.

Example:

| Offset | Name | Access | Reset | Description |
|---|---|---|---|---|
| `0x0000` | DEVICE_ID | RO | `0x43414553` | Device identifier |
| `0x0004` | VERSION | RO | `0x00010000` | Firmware version |
| `0x0008` | CONTROL | RW | `0x00000000` | Device control |
| `0x000C` | STATUS | RO | `0x00000001` | Device status |

This makes development much easier for both FPGA and software developers.

---

# 33. Clean Register Architecture

A good FPGA PCIe architecture separates transport from register logic.

```text
PCIe IP
   │
   ▼
BAR Interface
   │
   ▼
Address Decoder
   │
   ▼
Register Block
   │
   ▼
User Logic
```

This is preferable to mixing all functionality inside one large PCIe module.

---

# 34. Future Project Structure

As the project grows, the source tree may look like:

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
    ├── counter.sv
    └── reset_sync.sv
```

Each module has a clear responsibility.

---

# 35. Debugging BAR Problems

If the PCIe device appears in the operating system but BAR access does not work, useful checks include:

```text
Does the host assign the BAR?

Is the BAR size correct?

Is the BAR enabled?

Is Memory Space Enable set?

Does the FPGA receive the request?

Is address decoding correct?

Does the FPGA return the expected data?

Are byte enables handled correctly?
```

These checks help isolate problems between PCIe transport and user logic.

---

# 36. Memory Space Enable

PCIe configuration space contains a Command register.

One important control is:

```text
Memory Space Enable
```

When enabled, the device can respond to memory-mapped BAR accesses.

Conceptually:

```text
PCI Command Register
        │
        ▼
Memory Space Enable
        │
        ▼
BAR MMIO Access Allowed
```

The host operating system typically configures this during device initialization.

---

# 37. BAR Design Workflow

A practical BAR development flow looks like:

```text
Choose BAR Size
      │
      ▼
Configure PCIe IP
      │
      ▼
Define Register Map
      │
      ▼
Create Address Decoder
      │
      ▼
Create Read Logic
      │
      ▼
Create Write Logic
      │
      ▼
Connect User Logic
      │
      ▼
Build FPGA
      │
      ▼
Enumerate Device
      │
      ▼
Test MMIO
```

---

# 38. What We Learned

In this chapter, we learned:

```text
PCIe BAR
   │
   ├── Base Address
   ├── MMIO
   ├── Register Mapping
   ├── Address Decoding
   ├── Read Registers
   ├── Write Registers
   ├── 32-bit BAR
   ├── 64-bit BAR
   ├── BAR Size
   ├── Alignment
   ├── Byte Enables
   └── Register Documentation
```

BARs provide one of the most important interfaces between host software and FPGA logic.

---

# Next Chapter

Continue to:

**[Chapter 08 — PCIe TLP Fundamentals](08-pcie-tlp.md)**

In the next chapter, we will move below the BAR abstraction and study the packets used by PCI Express.

We will cover:

```text
Transaction Layer Packets
Memory Read Requests
Memory Write Requests
Completions
Requester ID
Completer ID
Tags
Addresses
Payloads
Byte Enables
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
