# Chapter 14 — Programming and Debugging the FPGA

[← Previous Chapter](13-generate-bitstream.md) | [Back to README](../README.md)

---

## Introduction

Generating a bitstream is not the end of FPGA development.

The next step is testing the design on real hardware.

Hardware debugging is different from software debugging because many important signals exist only inside the FPGA fabric.

You cannot simply print every internal value to a console.

Instead, FPGA development uses tools such as:

```text
Vivado Hardware Manager
ILA
VIO
Debug Probes
JTAG
Trigger Logic
```

In this chapter, we will cover:

- Programming the FPGA
- Vivado Hardware Manager
- JTAG debugging
- Integrated Logic Analyzer
- Virtual I/O
- Debug probes
- Trigger conditions
- Signal capture
- Clock selection
- Hardware debug workflow
- PCIe debugging
- Common hardware problems

---

# 1. Hardware Debugging

Simulation is extremely useful, but real hardware introduces additional variables.

Examples include:

```text
Real Clock Behavior

Board Reset Timing

Signal Integrity

PCIe Enumeration

External Devices

Physical Connections

Clock Domain Crossing

Timing Margins
```

A design may work perfectly in simulation but fail on hardware because of one of these factors.

---

# 2. Typical Debug Flow

A practical FPGA debug process looks like:

```text
Write RTL
   │
   ▼
Simulate
   │
   ▼
Synthesize
   │
   ▼
Implement
   │
   ▼
Check Timing
   │
   ▼
Generate Bitstream
   │
   ▼
Program FPGA
   │
   ▼
Observe Hardware
   │
   ▼
Debug
```

Hardware debugging should be part of the normal development process.

---

# 3. Vivado Hardware Manager

Vivado includes:

```text
Hardware Manager
```

which communicates with FPGA devices through JTAG.

Typical workflow:

```text
Open Hardware Manager
      │
      ▼
Open Target
      │
      ▼
Auto Connect
      │
      ▼
Detect FPGA
```

Once detected, Vivado can program and debug the device.

---

# 4. Open Hardware Manager

In Vivado:

```text
Flow Navigator
      │
      ▼
PROGRAM AND DEBUG
      │
      ▼
Open Hardware Manager
```

Then:

```text
Open Target
      │
      ▼
Auto Connect
```

If the board and JTAG connection are working, the FPGA should appear.

---

# 5. Program Device

After detecting the FPGA:

```text
Right-click FPGA
      │
      ▼
Program Device
```

Select the generated:

```text
.bit
```

file.

Then click:

```text
Program
```

Vivado transfers the bitstream through JTAG.

---

# 6. What Happens During Programming?

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
FPGA Configuration Logic
   │
   ▼
Programmable Fabric
```

After configuration completes, the hardware defined by the bitstream becomes active.

---

# 7. Basic Hardware Verification

Before debugging complex logic, verify the simplest possible things first.

For example:

```text
Is the FPGA detected?

Does programming succeed?

Is the expected clock present?

Is reset released?

Does a test LED change?

Does the counter run?
```

Debugging from simple observations reduces uncertainty.

---

# 8. Start with Known Signals

A useful first test is exposing internal states through simple outputs.

Examples:

```text
LED

GPIO

Status Register

Debug Counter
```

For example:

```systemverilog
assign led = counter[25];
```

This can visually confirm that:

```text
Clock is running

Reset is released

Logic is active
```

---

# 9. Why LEDs Are Limited

LEDs are useful for simple status checks.

But they cannot show:

```text
High-Speed Transactions

PCIe Packets

Multiple Internal Signals

Short Pulses

Complex State Machines
```

For deeper debugging, we need internal FPGA instrumentation.

---

# 10. Integrated Logic Analyzer

Vivado provides:

```text
ILA
```

which stands for:

```text
Integrated Logic Analyzer
```

ILA acts like a logic analyzer inside the FPGA.

Conceptually:

```text
Internal FPGA Signals
        │
        ▼
       ILA
        │
        ▼
Capture Memory
        │
        ▼
JTAG
        │
        ▼
Vivado
```

---

# 11. What Can ILA Observe?

ILA can capture internal signals such as:

```text
Counters

FSM States

Addresses

Write Enables

Read Enables

Data Buses

PCIe Status

BAR Accesses

TLP Metadata
```

This allows you to observe signals that are not connected to physical pins.

---

# 12. ILA Architecture

Conceptually:

```text
User Logic
   │
   ├── signal_a
   ├── signal_b
   ├── signal_c
   │
   ▼
ILA Core
   │
   ▼
Internal Capture Memory
   │
   ▼
JTAG
   │
   ▼
Vivado Hardware Manager
```

---

# 13. ILA Requires a Clock

ILA samples signals using a clock.

Example:

```text
PCIe User Clock
      │
      ▼
ILA
```

The signals being observed should normally belong to the same clock domain as the ILA sampling clock.

---

# 14. Choosing the ILA Clock

Suppose you want to debug BAR logic operating on:

```text
pcie_user_clk
```

Then the ILA should normally use:

```text
pcie_user_clk
```

Conceptually:

```text
pcie_user_clk
      │
      ├── BAR Logic
      └── ILA
```

This ensures signals are sampled correctly.

---

# 15. Do Not Mix Clock Domains Carelessly

If signals from multiple unrelated clock domains are connected to one ILA, the captured values may be misleading or unsafe.

A better approach is usually:

```text
ILA 1
→ PCIe Clock Domain

ILA 2
→ User Clock Domain
```

or synchronize debug signals appropriately.

---

# 16. Adding ILA from Vivado

One method is using:

```text
IP Catalog
```

Search for:

```text
ILA
```

or:

```text
Integrated Logic Analyzer
```

Then configure:

```text
Probe Count

Probe Widths

Capture Depth

Trigger Features
```

---

# 17. Probe

An ILA input signal is called a:

```text
Probe
```

Example:

```text
probe0 → write_enable

probe1 → address[15:0]

probe2 → write_data[31:0]

probe3 → read_data[31:0]
```

Each probe can have a different width.

---

# 18. Example BAR Debug Probes

For the BAR logic from earlier chapters, useful probes might be:

```text
write_enable

read_enable

address

write_data

read_data

control_reg

status_reg
```

Conceptually:

```text
PCIe BAR Logic
      │
      ▼
ILA Probes
```

---

# 19. Capture Depth

ILA stores samples in internal FPGA memory.

This is called:

```text
Capture Depth
```

Example values may include:

```text
1024 samples

2048 samples

4096 samples

8192 samples
```

A larger capture depth records more history but consumes more FPGA resources.

---

# 20. Capture Memory

ILA commonly uses FPGA memory resources for captures.

Therefore increasing:

```text
Probe Width

Capture Depth

Number of Probes
```

increases resource consumption.

There is a trade-off between:

```text
Debug Visibility
```

and:

```text
FPGA Resource Usage
```

---

# 21. Trigger

ILA does not always need to capture randomly.

It can wait for a specific condition called a:

```text
Trigger
```

Example:

```text
write_enable == 1
```

When the condition occurs:

```text
Trigger Detected
      │
      ▼
Capture Relevant Samples
```

---

# 22. Example Trigger

Suppose you want to capture a write to:

```text
BAR0 + 0x0008
```

You might trigger when:

```text
write_enable = 1
```

and:

```text
address = 0x0008
```

Then ILA captures the surrounding activity.

---

# 23. Pre-Trigger Samples

ILA can retain samples that occurred before the trigger.

Conceptually:

```text
Before Trigger        Trigger        After Trigger
───────────────┬─────────▲───────────────
               │
          Capture Point
```

This helps answer:

```text
What happened immediately before the failure?
```

---

# 24. Post-Trigger Samples

Samples after the trigger can show what the logic did in response.

Example:

```text
Host Write
    │
    ▼
Trigger
    │
    ▼
Register Updated
    │
    ▼
State Machine Changes
```

Both pre-trigger and post-trigger data can be valuable.

---

# 25. Waveform View

Captured signals appear as digital waveforms.

Example:

```text
clk          _|‾|_|‾|_|‾|_|‾|_

write_en     _______|‾|________

address      ----0008------------

write_data   ----00000001--------

control_reg  --------00000001----
```

This makes hardware behavior much easier to understand.

---

# 26. Mark Debug Signals

Vivado can also allow RTL signals to be marked for debugging.

A common attribute is:

```systemverilog
(* mark_debug = "true" *) logic debug_signal;
```

Example:

```systemverilog
(* mark_debug = "true" *)
logic [31:0] control_reg;
```

Vivado can preserve the signal for hardware debug insertion.

---

# 27. Example Mark Debug

```systemverilog
(* mark_debug = "true" *)
logic write_enable;

(* mark_debug = "true" *)
logic [15:0] address;

(* mark_debug = "true" *)
logic [31:0] write_data;
```

These signals can then be connected to ILA probes through Vivado debug tools.

---

# 28. Debug Hub

Vivado hardware debugging uses internal debug infrastructure.

Conceptually:

```text
ILA
 │
 ▼
Debug Hub
 │
 ▼
JTAG
 │
 ▼
Hardware Manager
```

If the debug hub is not operating correctly, ILA cores may not appear in Hardware Manager.

---

# 29. ILA After Programming

After programming a bitstream containing ILA:

```text
Hardware Manager
      │
      ▼
Refresh Device
      │
      ▼
ILA Core Appears
```

You can then arm the trigger and capture internal signals.

---

# 30. Running a Trigger

Typical workflow:

```text
Configure Trigger
      │
      ▼
Run Trigger
      │
      ▼
ILA Waits
      │
      ▼
Hardware Event Occurs
      │
      ▼
Trigger Fires
      │
      ▼
Waveform Captured
```

---

# 31. Example PCIe BAR Debug

Suppose the host writes to:

```text
CONTROL
Offset 0x0008
```

We want to verify the FPGA receives it.

ILA probes:

```text
wr_en
addr
wr_data
control_reg
```

Expected capture:

```text
wr_en
      ______|‾|_________

addr
      ------0008---------

wr_data
      ------00000001-----

control_reg
      --------00000001---
```

This confirms the BAR write path is working.

---

# 32. Debugging a Missing BAR Write

Suppose:

```text
control_reg
```

never changes.

Possible causes include:

```text
No PCIe transaction reaches FPGA

BAR decode incorrect

Address offset incorrect

write_enable missing

Byte enables incorrect

Register write logic incorrect

Reset remains active
```

ILA helps identify which stage fails.

---

# 33. Debug by Layers

A useful debugging strategy is:

```text
Layer 1
PCIe Link

Layer 2
PCIe IP

Layer 3
Transaction Interface

Layer 4
BAR Decoder

Layer 5
Register Block

Layer 6
Application Logic
```

Test one layer at a time.

---

# 34. PCIe Link Status

Before debugging BAR or TLP logic, confirm that the PCIe link is established.

Conceptually:

```text
PCIe Physical Link
      │
      ▼
LTSSM
      │
      ▼
L0
```

If the link never reaches normal operating state, BAR transactions will never arrive.

---

# 35. Debugging LTSSM

Some PCIe IP configurations expose status signals related to:

```text
LTSSM State

Link Up

Negotiated Width

Negotiated Speed
```

These can be useful ILA probes.

For example:

```text
link_up
```

should eventually become:

```text
1
```

after successful link training.

---

# 36. Example Link Debug

Conceptually:

```text
PERST#
   │
   ▼
PCIe IP Reset
   │
   ▼
LTSSM
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
L0
   │
   ▼
link_up = 1
```

ILA can help observe this startup sequence if the IP exposes appropriate status signals.

---

# 37. If PCIe Does Not Enumerate

Useful checks include:

```text
Is the FPGA configured early enough?

Is the PCIe reference clock present?

Is PERST# handled correctly?

Does the link reach L0?

Is the correct FPGA transceiver used?

Is lane width configured correctly?

Is the PCIe IP configured correctly?
```

Start with physical and link-level conditions before investigating BAR logic.

---

# 38. Operating System Verification

Once the PCIe link is established, verify that the host detects the device.

On Linux:

```text
lspci
```

can display PCIe devices.

On Windows:

```text
Device Manager
```

can show enumerated hardware.

This confirms that configuration-space enumeration succeeded.

---

# 39. Linux `lspci`

A device may appear conceptually as:

```text
03:00.0 Processing accelerators: Example Device
```

The exact description depends on configuration-space values and system software.

Useful details can also include:

```text
BAR resources

Link speed

Link width

Device status
```

---

# 40. Windows Device Manager

In Windows, open:

```text
Device Manager
```

Then inspect the relevant PCIe device.

Useful properties can include:

```text
Hardware IDs

Resources

Device Status

Location
```

This can confirm whether the operating system enumerated the endpoint.

---

# 41. BAR Resource Verification

The operating system may show memory resources assigned to a PCIe device.

Conceptually:

```text
BAR0
→ Memory Range

BAR1
→ Memory Range
```

If no expected memory resource exists, review:

```text
BAR configuration

PCIe command settings

Enumeration

IP configuration
```

---

# 42. Debugging Reads

Suppose the host can write but reads fail.

Potential causes include:

```text
Memory Read request not decoded

Read address incorrect

Completion not generated

Completion tag incorrect

Requester ID handling incorrect

Completion length incorrect

Read data incorrect
```

These were concepts introduced in Chapter 08.

---

# 43. ILA for Read Requests

Useful probes include:

```text
read_request_valid

address

requester_id

tag

length

read_data

completion_valid
```

Then observe:

```text
Read Request
      │
      ▼
Address Decode
      │
      ▼
Register Data
      │
      ▼
Completion
```

---

# 44. Debugging Writes

Memory Writes are normally posted.

Useful write probes include:

```text
write_valid

address

length

byte_enable

payload

register_write
```

Expected flow:

```text
Memory Write
      │
      ▼
Decode
      │
      ▼
Register Update
```

---

# 45. Debug Counters

Debug counters are extremely useful.

For example:

```systemverilog
logic [31:0] write_count;

always_ff @(posedge clk) begin

    if (!reset_n)
        write_count <= 32'h0;

    else if (write_enable)
        write_count <= write_count + 1'b1;

end
```

This can reveal whether transactions are reaching the design even when they are too fast to observe directly.

---

# 46. Error Counters

You can also create counters for unexpected events.

Examples:

```text
Invalid Address Count

Unsupported Request Count

Dropped Packet Count

FIFO Overflow Count

FIFO Underflow Count
```

These can be exposed through status registers.

---

# 47. Sticky Error Bits

A useful debug technique is:

```text
Sticky Error Bit
```

Once an error occurs, the bit remains high until reset or software clears it.

Example:

```systemverilog
always_ff @(posedge clk) begin

    if (!reset_n)
        error_seen <= 1'b0;

    else if (error_condition)
        error_seen <= 1'b1;

end
```

Even a one-cycle event becomes easy to detect later.

---

# 48. Virtual I/O

Vivado also provides:

```text
VIO
```

which stands for:

```text
Virtual Input/Output
```

VIO allows Vivado to interact with internal FPGA signals through JTAG.

Conceptually:

```text
Vivado
   │
   ▼
JTAG
   │
   ▼
VIO
   │
   ├── Drive Internal Signals
   └── Observe Internal Signals
```

---

# 49. VIO Inputs and Outputs

From the FPGA perspective, VIO can provide:

```text
Probe In
```

to observe signals.

And:

```text
Probe Out
```

to drive signals.

Example:

```text
VIO probe_out
      │
      ▼
test_enable
```

This allows test controls to be changed without recompiling host software.

---

# 50. Example VIO Use

Suppose the design contains:

```systemverilog
logic test_mode;
```

VIO can drive:

```text
test_mode = 0
```

or:

```text
test_mode = 1
```

from Vivado Hardware Manager.

This can be useful during development.

---

# 51. ILA vs VIO

Simplified:

```text
ILA
→ Capture and inspect signal history

VIO
→ Observe or manually control live signals
```

They can be used together.

Example:

```text
VIO
  │
  ▼
Enable Test

ILA
  │
  ▼
Capture Result
```

---

# 52. Debug Resource Cost

ILA and VIO consume FPGA resources.

They may use:

```text
LUTs

Flip-Flops

BRAM

Routing
```

Large debug cores can affect:

```text
Timing

Placement

Utilization
```

Therefore debug instrumentation should be sized appropriately.

---

# 53. Debug Builds

A professional workflow may have:

```text
Debug Build
```

and:

```text
Release Build
```

Debug build:

```text
ILA enabled
VIO enabled
Extra counters
More status signals
```

Release build:

```text
Minimal debug instrumentation
Optimized resource usage
```

---

# 54. Conditional Debug Logic

SystemVerilog compilation options can sometimes be used to conditionally include debug logic.

Conceptually:

```systemverilog
`ifdef DEBUG

    // Debug instrumentation

`endif
```

This allows debug features to be enabled for development builds.

---

# 55. Keep Debugging Reproducible

When debugging a problem, record:

```text
Git Commit

Vivado Version

FPGA Board

Bitstream Version

Host Platform

Trigger Condition

Observed Waveform
```

This makes difficult hardware bugs much easier to reproduce.

---

# 56. Save ILA Waveforms

Important captures should be saved.

For example:

```text
debug/
│
├── pcie_link_startup/
├── bar_write/
└── read_completion/
```

A saved waveform can document exactly what happened on real hardware.

---

# 57. Compare Good and Bad Captures

One powerful debugging technique is comparing:

```text
Known Good Build
```

with:

```text
Failing Build
```

For example:

```text
Good:
request_valid → decode → completion

Bad:
request_valid → decode → no completion
```

The difference immediately narrows the problem.

---

# 58. Hardware Bugs Can Be Intermittent

Some hardware problems may only appear occasionally.

Examples:

```text
CDC Errors

Reset Timing

Timing Violations

FIFO Overflow

Rare State Machine Conditions
```

Trigger conditions and sticky status bits are especially useful for these bugs.

---

# 59. Trigger on Error

Instead of triggering on normal activity, trigger when:

```text
error_condition = 1
```

Then retain pre-trigger history.

Conceptually:

```text
Normal Activity
      │
      ▼
Something Goes Wrong
      │
      ▼
error_condition
      │
      ▼
ILA Trigger
```

Now you can inspect what happened immediately before the failure.

---

# 60. Trigger on State

FSM debugging can use a state trigger.

Suppose:

```text
IDLE
WAIT
TRANSFER
ERROR
```

Trigger when:

```text
state == ERROR
```

Then inspect:

```text
Previous state

Inputs

Control signals

Counters
```

---

# 61. Trigger on Address

For register debugging, trigger when:

```text
address == 0x0008
```

or:

```text
address == 0x000C
```

This isolates activity involving a specific BAR register.

---

# 62. Trigger on Data Pattern

ILA can also be useful when looking for a specific data value.

Conceptually:

```text
write_data == 0x12345678
```

Then capture the transaction that carried that value.

---

# 63. Debugging Clock Problems

If logic appears completely inactive, check:

```text
Is the input clock present?

Is the MMCM locked?

Is the correct user clock running?

Is the clock buffer connected?

Is the module using the intended clock?
```

A dead clock can make an otherwise correct design appear completely broken.

---

# 64. MMCM Lock

Clocking blocks may expose signals such as:

```text
locked
```

Conceptually:

```text
MMCM
 │
 ├── clk_out
 └── locked
```

User reset logic may wait until:

```text
locked = 1
```

before releasing the design.

---

# 65. Debugging Reset Problems

If registers remain at reset values, check:

```text
Is reset asserted?

Is reset polarity correct?

Is reset synchronizer working?

Does reset ever deassert?

Is the correct reset connected to the module?
```

Probe reset signals with ILA.

---

# 66. Reset Polarity Mistake

Suppose the design expects:

```text
reset_n
```

but receives an active-high reset.

Then the FPGA logic may behave incorrectly.

Always confirm:

```text
Active High
```

versus:

```text
Active Low
```

at every interface boundary.

---

# 67. Debugging CDC Problems

CDC problems may appear as:

```text
Occasional corrupted values

Missing events

Duplicate events

Random state transitions
```

Useful checks include:

```text
Is the signal single-bit or multi-bit?

Is a synchronizer present?

Is a handshake required?

Should an async FIFO be used?

Are resets synchronized per domain?
```

---

# 68. Hardware Debugging Does Not Replace CDC Design

ILA may show a CDC problem.

But the solution is still architectural.

For example:

```text
Add Two-Flop Synchronizer

Use Toggle Synchronizer

Use Handshake

Use Asynchronous FIFO
```

Do not attempt to fix CDC problems only by adjusting implementation settings.

---

# 69. PCIe Debug Hierarchy

A useful PCIe debug sequence is:

```text
1. FPGA configured?

2. Reference clock present?

3. Reset correct?

4. LTSSM reaches L0?

5. Link up?

6. Host enumerates device?

7. BAR assigned?

8. BAR requests reach FPGA?

9. Register decode works?

10. Read completion works?
```

Do not start debugging step 10 when step 4 is already failing.

---

# 70. First PCIe Milestone

A good first milestone is simply:

```text
PCIe Device Appears in Host
```

At this stage you have verified much of:

```text
Clock

Reset

Transceiver

PCIe IP

Link Training

Configuration Space
```

Then move on to BAR testing.

---

# 71. Second PCIe Milestone

Next milestone:

```text
BAR Resources Assigned
```

This confirms the host recognizes the endpoint's requested memory regions.

Then test:

```text
Simple Register Read
```

---

# 72. Third PCIe Milestone

A useful first BAR register is:

```text
DEVICE_ID
```

For example:

```text
0x43414553
```

If the host reads the expected value, you have verified:

```text
Memory Read Request

Address Decode

Register Read

Completion Generation
```

That is a major milestone.

---

# 73. Fourth PCIe Milestone

Then test a writable register:

```text
CONTROL
```

Write:

```text
0x00000001
```

and read it back.

This verifies:

```text
Memory Write

Write Decode

Register Storage

Memory Read

Completion
```

---

# 74. Build Debug Features Early

It is easier to debug a design that was designed with observability in mind.

Useful debug features include:

```text
Version Register

Build ID

Status Register

Transaction Counters

Error Counters

Sticky Error Flags

ILA Probes
```

These features save significant development time.

---

# 75. Avoid Observing Everything

Connecting every internal signal to ILA creates a huge debug core.

Instead, choose signals based on the question you are trying to answer.

For example:

```text
Question:
Did the BAR write reach the register block?

Probes:
write_enable
address
write_data
```

Small targeted captures are easier to understand.

---

# 76. Debug One Question at a Time

Instead of asking:

```text
Why doesn't the FPGA work?
```

ask smaller questions:

```text
Is the clock running?

Is reset released?

Is PCIe link up?

Did a read request arrive?

Was the address decoded?

Was a completion generated?
```

Each answer reduces the search space.

---

# 77. Common Hardware Debugging Mistakes

Common mistakes include:

```text
Changing many things at once

Ignoring timing failures

Debugging BAR logic before PCIe link-up

Using the wrong ILA clock

Capturing too many signals

Ignoring reset state

Assuming simulation proves board connectivity

Using unverified XDC constraints
```

---

# 78. Recommended Debug Workflow

A structured workflow:

```text
Reproduce Problem
      │
      ▼
Identify Layer
      │
      ▼
Choose Signals
      │
      ▼
Add ILA / Counters
      │
      ▼
Create Trigger
      │
      ▼
Capture
      │
      ▼
Analyze
      │
      ▼
Form Hypothesis
      │
      ▼
Change One Thing
      │
      ▼
Test Again
```

---

# 79. Hardware Debug Checklist

Before blaming complex RTL, check:

```text
Board Power

FPGA Device

Bitstream Version

Clock

Reset

XDC

Timing

JTAG Connection

External Cabling

PCIe Slot

Host Detection
```

Simple physical issues can look like complicated firmware bugs.

---

# 80. What We Learned

In this chapter, we learned:

```text
FPGA Hardware Debugging
        │
        ├── Hardware Manager
        ├── JTAG
        ├── ILA
        ├── VIO
        ├── Debug Probes
        ├── Trigger Conditions
        ├── Waveform Capture
        ├── Debug Counters
        ├── Sticky Error Flags
        ├── Clock Debugging
        ├── Reset Debugging
        ├── CDC Debugging
        └── PCIe Debugging
```

Hardware debugging turns invisible FPGA behavior into observable information.

---

# Next Chapter

Continue to:

**[Chapter 15 — Automating Vivado Builds with Tcl](15-vivado-tcl.md)**

In the next chapter, we will move from manual GUI builds to reproducible scripted FPGA builds.

We will cover:

```text
Vivado Tcl
Project Creation
Adding Sources
Adding Constraints
Synthesis
Implementation
Timing Reports
Bitstream Generation
Build Directories
Reproducible Builds
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
