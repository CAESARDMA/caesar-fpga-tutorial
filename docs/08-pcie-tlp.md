# Chapter 08 — PCIe TLP Fundamentals

[← Previous Chapter](07-pcie-bar.md) | [Back to README](../README.md)

---

## Introduction

In the previous chapter, we learned how PCIe BARs provide memory-mapped access between host software and FPGA logic.

Now we will move one layer deeper and study the packets used by PCI Express.

These packets are called:

```text
TLPs
```

which stands for:

```text
Transaction Layer Packets
```

TLPs carry transactions such as:

- Memory Read Requests
- Memory Write Requests
- Configuration Requests
- Completions
- Messages

Understanding TLPs is essential for understanding how PCIe devices exchange requests and data.

In this chapter, we will cover:

- TLP structure
- Request packets
- Completion packets
- Memory Reads
- Memory Writes
- Requester ID
- Completer ID
- Tags
- Length fields
- Byte Enables
- Addresses
- Payloads
- Basic request/completion flow

---

# 1. What Is a TLP?

PCI Express transfers transactions using packets.

At the Transaction Layer, these packets are called:

```text
Transaction Layer Packets
```

or:

```text
TLPs
```

A TLP can carry information such as:

```text
Operation Type
Address
Length
Requester
Tag
Payload Data
Control Information
```

A simplified packet looks like:

```text
┌────────────────────────────┐
│        TLP Header          │
├────────────────────────────┤
│      Optional Payload      │
├────────────────────────────┤
│     Optional Digest        │
└────────────────────────────┘
```

Not every TLP contains data.

---

# 2. Transaction Layer

The PCIe protocol stack contains:

```text
Transaction Layer
      │
      ▼
Data Link Layer
      │
      ▼
Physical Layer
```

The Transaction Layer is responsible for creating and processing requests and completions.

For example:

```text
Host wants to read FPGA memory
          │
          ▼
Transaction Layer
          │
          ▼
Memory Read Request TLP
```

---

# 3. Common TLP Types

Common TLP categories include:

```text
Memory Read Request
Memory Write Request
Configuration Read
Configuration Write
Completion
Completion with Data
Message
```

For basic FPGA BAR communication, the most important are:

```text
Memory Read
Memory Write
Completion with Data
```

---

# 4. Memory Write Request

A Memory Write Request sends data to a PCIe device.

Example:

```text
Host
  │
  ▼
Memory Write TLP
  │
  ▼
FPGA
  │
  ▼
BAR Register
```

A write request includes:

```text
Address
Length
Payload Data
Requester Information
Byte Enables
```

Memory writes are normally:

```text
Posted
```

This means the sender does not normally wait for a Completion packet.

---

# 5. Posted Transactions

A posted transaction does not require a completion response.

Example:

```text
Host
  │
  ├──── Memory Write ────▶ FPGA
  │
  ▼
Continue Execution
```

This improves performance because the host does not need to wait for an acknowledgement at the Transaction Layer.

Memory Writes are the most common example of posted transactions.

---

# 6. Memory Read Request

A Memory Read Request asks another PCIe device to return data.

Example:

```text
Host
  │
  ▼
Memory Read Request
  │
  ▼
FPGA
```

Unlike a Memory Write, the request does not contain the requested data.

Instead, it contains information such as:

```text
Address
Length
Requester ID
Tag
Byte Enables
```

The FPGA must later return a:

```text
Completion with Data
```

---

# 7. Read Request and Completion

A simple read transaction looks like:

```text
Host
  │
  │ Memory Read Request
  ▼
FPGA
  │
  │ Completion with Data
  ▼
Host
```

More precisely:

```text
Requester
    │
    ├──── Memory Read Request ────▶ Completer
    │
    ◀──── Completion with Data ────┤
```

The tag in the request helps match the completion to the original request.

---

# 8. Requester and Completer

In PCIe terminology:

```text
Requester
```

is the device that starts a transaction.

```text
Completer
```

is the device that responds to the request.

For example:

```text
CPU / Root Complex
      │
      ▼
Memory Read Request
      │
      ▼
FPGA Endpoint
```

In this case:

```text
Requester = Host
Completer = FPGA
```

---

# 9. Requester ID

PCIe requests include a:

```text
Requester ID
```

This identifies the PCIe function that generated the request.

A Requester ID is commonly represented using:

```text
Bus
Device
Function
```

or:

```text
BDF
```

Conceptually:

```text
Bus Number
Device Number
Function Number
```

Together they identify a PCIe function within the hierarchy.

---

# 10. BDF

BDF stands for:

```text
Bus : Device . Function
```

An example might look like:

```text
03:00.0
```

This means:

```text
Bus     = 03
Device  = 00
Function = 0
```

Operating systems frequently display PCIe devices using this notation.

---

# 11. Tags

Memory Read Requests contain a:

```text
Tag
```

The tag helps identify outstanding read requests.

For example:

```text
Read Request A → Tag 0x12
Read Request B → Tag 0x13
Read Request C → Tag 0x14
```

When the FPGA returns a completion, the completion includes the matching tag.

Example:

```text
Request:
Tag = 0x12

Completion:
Tag = 0x12
```

This tells the requester which read operation the returned data belongs to.

---

# 12. Multiple Outstanding Reads

PCIe supports multiple requests being in flight at the same time.

Example:

```text
Requester
   │
   ├── Read Tag 01 ─────────▶
   ├── Read Tag 02 ─────────▶
   ├── Read Tag 03 ─────────▶
   │
   ◀── Completion Tag 02 ────
   ◀── Completion Tag 01 ────
   ◀── Completion Tag 03 ────
```

Responses do not always need to arrive in the same simple visual order in which requests were issued, depending on transaction ordering rules.

Tags allow the requester to track transactions correctly.

---

# 13. TLP Header

A TLP begins with a header.

Depending on the transaction, a header may contain fields such as:

```text
Format
Type
Traffic Class
Attributes
Length
Requester ID
Tag
Byte Enables
Address
```

A simplified request header can be visualized as:

```text
┌──────────────────────────┐
│ Format / Type            │
├──────────────────────────┤
│ Length                   │
├──────────────────────────┤
│ Requester ID             │
├──────────────────────────┤
│ Tag                      │
├──────────────────────────┤
│ Byte Enables             │
├──────────────────────────┤
│ Address                  │
└──────────────────────────┘
```

---

# 14. Format and Type

PCIe TLP headers contain fields commonly referred to as:

```text
Fmt
Type
```

Together these describe the packet format and transaction type.

Conceptually they answer questions such as:

```text
Does this packet contain data?

Is it a Memory Read?

Is it a Memory Write?

Is it a Completion?
```

For FPGA development, these fields are often decoded by the PCIe IP or the surrounding transaction interface.

---

# 15. 3DW and 4DW Headers

PCIe request headers may use:

```text
3DW
```

or:

```text
4DW
```

headers.

DW means:

```text
Double Word
```

and one DW is:

```text
32 bits
```

Therefore:

```text
3DW = 96 bits
4DW = 128 bits
```

---

# 16. Why 3DW vs 4DW?

The header size depends partly on the address format.

A 3DW request header can be used for addresses that fit within a 32-bit address format.

A 4DW request header supports a 64-bit address.

Conceptually:

```text
32-bit Address
      │
      ▼
3DW Header

64-bit Address
      │
      ▼
4DW Header
```

---

# 17. Length Field

The TLP header contains a:

```text
Length
```

field.

The length is generally expressed in:

```text
Double Words
```

where:

```text
1 DW = 4 bytes
```

Examples:

```text
Length = 1 DW
         ↓
       4 bytes

Length = 4 DW
         ↓
      16 bytes

Length = 16 DW
         ↓
      64 bytes
```

---

# 18. Payload

Some TLPs contain a payload.

Memory Write requests normally carry data.

Example:

```text
Memory Write TLP
│
├── Header
└── Payload
```

A Memory Read Request normally does not carry the requested payload.

Instead:

```text
Memory Read Request
│
└── Header
```

The requested data arrives later inside a Completion with Data.

---

# 19. Memory Write Example

Suppose the host writes:

```text
0x12345678
```

to:

```text
BAR0 + 0x0008
```

Conceptually, the transaction contains:

```text
Type:
Memory Write

Address:
BAR0 + 0x0008

Length:
1 DW

Payload:
0x12345678
```

The FPGA BAR logic then routes this write to the:

```text
CONTROL register
```

---

# 20. Memory Read Example

Suppose the host reads:

```text
BAR0 + 0x0004
```

where our tutorial FPGA exposes the firmware version.

The request might conceptually contain:

```text
Type:
Memory Read

Address:
BAR0 + 0x0004

Length:
1 DW

Tag:
0x05
```

The FPGA receives the request and determines that:

```text
Offset 0x0004
      │
      ▼
VERSION Register
```

Then it returns a Completion with Data.

---

# 21. Completion with Data

A successful Memory Read normally results in a:

```text
Completion with Data
```

A simplified completion contains:

```text
Completion Header
      +
Returned Data
```

For example:

```text
Tag:
0x05

Data:
0x00010000
```

The host uses the tag to associate this completion with the original read request.

---

# 22. Completion Status

Completion packets contain a:

```text
Completion Status
```

This indicates the outcome of the request.

A successful transaction uses a successful completion status.

Other statuses may indicate conditions such as unsupported or unsuccessful requests.

In FPGA development, correct completion generation is essential for reliable PCIe reads.

---

# 23. Completer ID

A completion may include a:

```text
Completer ID
```

This identifies the PCIe function returning the completion.

Conceptually:

```text
Requester ID
      ↓
Who sent the request?

Completer ID
      ↓
Who completed it?
```

---

# 24. Byte Enables

PCIe requests include:

```text
First DW Byte Enable
```

and, when applicable:

```text
Last DW Byte Enable
```

These determine which bytes in the first and last Double Words are valid.

Example:

```text
Byte Enable = 1111
```

means all four bytes are enabled.

Conceptually:

```text
Byte 3
Byte 2
Byte 1
Byte 0
```

each has an enable bit.

---

# 25. Byte Enable Example

Suppose a 32-bit word is:

```text
0xAABBCCDD
```

If all bytes are enabled:

```text
1111
```

then all four bytes participate.

If only the lowest byte is enabled:

```text
0001
```

then only:

```text
0xDD
```

is selected.

This is why the BAR register block in Chapter 07 may need byte-enable handling.

---

# 26. Address Alignment

PCIe memory transactions should be interpreted with correct address and byte alignment.

For example:

```text
32-bit register
```

is commonly placed at addresses such as:

```text
0x0000
0x0004
0x0008
0x000C
```

These are naturally aligned on 4-byte boundaries.

Clean register alignment simplifies hardware address decoding.

---

# 27. Example BAR Read Flow

Consider this register map:

```text
0x0000 DEVICE_ID
0x0004 VERSION
0x0008 CONTROL
0x000C STATUS
```

The host performs:

```text
Read BAR0 + 0x000C
```

The PCIe flow is:

```text
Host Software
      │
      ▼
MMIO Read
      │
      ▼
Root Complex
      │
      ▼
Memory Read TLP
      │
      ▼
FPGA PCIe IP
      │
      ▼
BAR Decoder
      │
      ▼
Offset 0x000C
      │
      ▼
STATUS Register
      │
      ▼
Completion with Data
      │
      ▼
Host
```

---

# 28. Example BAR Write Flow

The host writes:

```text
0x00000001
```

to:

```text
BAR0 + 0x0008
```

The flow is:

```text
Host Software
      │
      ▼
MMIO Write
      │
      ▼
Root Complex
      │
      ▼
Memory Write TLP
      │
      ▼
FPGA PCIe IP
      │
      ▼
BAR Decoder
      │
      ▼
CONTROL Register
```

No normal Completion TLP is required for a posted Memory Write.

---

# 29. Maximum Payload Size

PCIe devices advertise a:

```text
Maximum Payload Size
```

This affects the maximum payload carried by certain TLPs.

Possible supported values depend on device capability and platform configuration.

Conceptually:

```text
Larger Payload
      │
      ▼
More Data Per Packet
```

but system settings and endpoint capabilities must agree.

---

# 30. Maximum Read Request Size

PCIe also has a:

```text
Maximum Read Request Size
```

This controls the maximum amount of data requested by a single read request.

Conceptually:

```text
Requester
    │
    ▼
Read Request Size
    │
    ▼
One or More Completions
```

A large request may be returned using multiple completion packets.

---

# 31. Completion Splitting

A single Memory Read Request may sometimes produce multiple Completion TLPs.

Example:

```text
Read Request
Length = Large
     │
     ▼
Completion 1
     │
     ▼
Completion 2
     │
     ▼
Completion 3
```

The requester tracks the returned data until the request has been fully satisfied.

This becomes important in higher-performance PCIe designs.

---

# 32. Traffic Class

TLPs contain a:

```text
Traffic Class
```

field.

Traffic classes can be used as part of PCIe quality-of-service mechanisms.

For many basic FPGA endpoint projects, default traffic-class behavior is sufficient.

---

# 33. TLP Attributes

TLP headers may contain attributes controlling certain transaction behaviors.

Examples can include concepts related to:

```text
Ordering
Caching behavior
Snooping behavior
```

These features become more important in advanced PCIe system design.

---

# 34. ECRC

PCIe optionally supports:

```text
ECRC
```

which stands for:

```text
End-to-End Cyclic Redundancy Check
```

ECRC can provide additional packet integrity checking across the end-to-end transaction path.

Not every design enables or uses it.

---

# 35. TLP Interface Inside the FPGA

Depending on the FPGA family and PCIe IP, the user-facing interface may not expose raw PCIe serial data.

Instead, the PCIe IP presents transaction information using an internal streaming interface.

Conceptually:

```text
PCIe Serial Link
      │
      ▼
PCIe Hard / Soft IP
      │
      ▼
Internal Transaction Interface
      │
      ▼
FPGA User Logic
```

The exact signal names and interface format depend on the PCIe IP being used.

---

# 36. Streaming Interfaces

Many FPGA PCIe implementations use stream-oriented interfaces.

A simplified conceptual interface may contain:

```text
Data
Valid
Ready
Keep / Byte Enable
Last
Metadata
```

Conceptually:

```text
PCIe IP
  │
  │ Transaction Stream
  ▼
User Logic
```

The PCIe IP handles lower protocol layers while the FPGA logic processes requests and completions.

---

# 37. Receive Path

The receive path handles TLPs arriving from the host.

For example:

```text
Host
 │
 ▼
PCIe Link
 │
 ▼
PCIe IP
 │
 ▼
RX Transaction Interface
 │
 ▼
TLP Decoder
 │
 ├── Memory Read
 │
 └── Memory Write
```

The FPGA then decides how to handle the request.

---

# 38. Transmit Path

The transmit path sends TLPs from the FPGA.

For example, when handling a Memory Read:

```text
Register Data
     │
     ▼
Completion Generator
     │
     ▼
TX Transaction Interface
     │
     ▼
PCIe IP
     │
     ▼
PCIe Link
     │
     ▼
Host
```

---

# 39. TLP Decoder Architecture

A simplified TLP receive architecture could look like:

```text
RX TLP
  │
  ▼
Header Decoder
  │
  ├── Type
  ├── Address
  ├── Length
  ├── Requester ID
  ├── Tag
  └── Byte Enables
  │
  ▼
Request Router
  │
  ├── BAR Read
  └── BAR Write
```

This separates protocol decoding from register logic.

---

# 40. Completion Generator Architecture

For Memory Read requests:

```text
Read Request
    │
    ▼
Address Decoder
    │
    ▼
Register / Memory
    │
    ▼
Read Data
    │
    ▼
Completion Generator
    │
    ├── Requester ID
    ├── Tag
    ├── Length
    └── Payload
    │
    ▼
TX TLP
```

The completion must contain the information required for the requester to match it correctly.

---

# 41. Why Tags Matter in FPGA Logic

Suppose the FPGA receives:

```text
Requester ID = Host
Tag = 0x21
Address = BAR0 + 0x0004
```

When creating the completion, it must preserve the information needed to associate the response with that request.

Conceptually:

```text
Memory Read
Tag 0x21
    │
    ▼
FPGA Reads VERSION
    │
    ▼
Completion
Tag 0x21
```

Incorrect tag handling can cause read transactions to fail.

---

# 42. Why Length Matters

The FPGA must also understand the amount of data requested.

For a simple 32-bit register:

```text
Length = 1 DW
```

is straightforward.

For larger requests:

```text
Length > 1 DW
```

the FPGA may need to return multiple words or multiple completions depending on the architecture and PCIe rules.

---

# 43. Simple Register Read Case

For our tutorial register map:

```text
0x0000 DEVICE_ID
0x0004 VERSION
0x0008 CONTROL
0x000C STATUS
```

a 1-DW read can be handled conceptually as:

```text
Receive Memory Read
        │
        ▼
Extract Address
        │
        ▼
Decode Offset
        │
        ▼
Read 32-bit Register
        │
        ▼
Generate Completion
        │
        ▼
Return 1 DW
```

---

# 44. Simple Register Write Case

A 1-DW Memory Write can be handled as:

```text
Receive Memory Write
        │
        ▼
Extract Address
        │
        ▼
Extract Payload
        │
        ▼
Check Byte Enables
        │
        ▼
Decode Register
        │
        ▼
Write Register
```

This is the conceptual bridge between raw PCIe transactions and the BAR register block from Chapter 07.

---

# 45. TLPs and PCIe BARs

BARs and TLPs are closely related but describe different layers of the system.

```text
BAR
 │
 ▼
Defines addressable device region

TLP
 │
 ▼
Carries the actual read/write transaction
```

Together:

```text
Host accesses BAR
      │
      ▼
Root Complex creates TLP
      │
      ▼
Endpoint receives TLP
      │
      ▼
BAR decoder handles address
```

---

# 46. Common Debugging Questions

When debugging TLP handling, useful questions include:

```text
What TLP type was received?

Is the address correct?

What is the requested length?

What are the byte enables?

What Requester ID was supplied?

What tag was supplied?

Was the BAR decoded correctly?

Was the completion generated?

Does the completion contain the correct tag?

Does the completion contain the correct length and payload?
```

---

# 47. Keep Protocol and Application Logic Separate

A clean design should avoid mixing every PCIe detail into application logic.

A better structure is:

```text
PCIe IP
   │
   ▼
TLP Interface
   │
   ▼
TLP Decoder / Generator
   │
   ▼
BAR Interface
   │
   ▼
Register Block
   │
   ▼
User Logic
```

Each layer has a clear responsibility.

---

# 48. Future Source Structure

A larger FPGA project might eventually contain:

```text
src/
│
├── top.sv
│
├── pcie/
│   ├── pcie_wrapper.sv
│   ├── tlp_decoder.sv
│   ├── completion_generator.sv
│   ├── bar_controller.sv
│   └── register_block.sv
│
└── modules/
    └── reset_sync.sv
```

This creates a scalable architecture for PCIe development.

---

# 49. What We Learned

In this chapter, we learned:

```text
PCIe TLP
   │
   ├── Memory Read
   ├── Memory Write
   ├── Completion
   ├── Completion with Data
   ├── Requester ID
   ├── Completer ID
   ├── Tag
   ├── Length
   ├── Address
   ├── Payload
   ├── Byte Enables
   └── Transaction Flow
```

We now understand how PCIe requests move between the host and an FPGA endpoint.

---

# Next Chapter

Continue to:

**[Chapter 09 — Clock and Reset Design](09-clock-reset.md)**

In the next chapter, we will move back to FPGA architecture and study two of the most important foundations of any reliable hardware design:

```text
Clock Domains
Clock Generation
Reset Synchronization
Synchronous Reset
Asynchronous Reset
Clock Domain Crossing
Metastability
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
