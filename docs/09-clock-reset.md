# Chapter 09 — Clock and Reset Design

[← Previous Chapter](08-pcie-tlp.md) | [Back to README](../README.md)

---

## Introduction

Clock and reset logic are fundamental parts of every FPGA design.

A design may contain correct functional logic but still fail in real hardware if:

- Clocks are configured incorrectly
- Reset logic is unstable
- Signals cross clock domains unsafely
- Timing requirements are not met
- Metastability is ignored

In PCIe FPGA designs, clock and reset handling becomes especially important because the PCIe interface, user logic and external interfaces may operate in different clock domains.

In this chapter, we will cover:

- FPGA clocks
- Clock periods
- Clock domains
- Clock generation
- Reset signals
- Synchronous reset
- Asynchronous reset
- Reset synchronization
- Metastability
- Clock Domain Crossing
- Two-flop synchronizers
- Pulse synchronization
- Multi-bit CDC
- FIFOs
- Timing constraints
- PCIe clock/reset considerations

---

# 1. What Is a Clock?

Most FPGA logic is synchronous.

This means the logic updates based on a clock signal.

Conceptually:

```text
Clock
  │
  ▼
Flip-Flops
  │
  ▼
Registered Logic
```

A clock continuously changes between:

```text
0
1
0
1
0
1
...
```

Digital logic commonly updates on one clock edge.

For example:

```systemverilog
always_ff @(posedge clk) begin
    counter <= counter + 1'b1;
end
```

The counter updates on every:

```text
rising edge
```

of the clock.

---

# 2. Clock Frequency

Clock speed is normally expressed in:

```text
Hz
MHz
GHz
```

Examples:

```text
50 MHz
100 MHz
125 MHz
200 MHz
250 MHz
```

A:

```text
100 MHz
```

clock produces:

```text
100,000,000 cycles per second
```

---

# 3. Clock Period

Frequency and period are related.

The formula is:

```text
Period = 1 / Frequency
```

For example:

```text
100 MHz
```

has a period of:

```text
10 ns
```

because:

```text
1 / 100,000,000 = 10 ns
```

Other examples:

```text
50 MHz  → 20 ns
100 MHz → 10 ns
125 MHz → 8 ns
200 MHz → 5 ns
250 MHz → 4 ns
```

---

# 4. Why Clock Period Matters

The FPGA logic between registers must complete within the available clock period.

Conceptually:

```text
Register A
    │
    ▼
Combinational Logic
    │
    ▼
Register B
```

For a 100 MHz clock:

```text
Available Period ≈ 10 ns
```

The data must travel from Register A through the logic and arrive at Register B in time for the next active clock edge.

If the path is too slow:

```text
Timing Violation
```

can occur.

---

# 5. Clock Domain

A:

```text
Clock Domain
```

is a group of logic operating from the same clock.

Example:

```text
clk_100mhz
     │
     ├── counter
     ├── register_block
     └── control_logic
```

All these modules belong to the same clock domain.

A larger FPGA may contain multiple clock domains.

Example:

```text
FPGA
│
├── 100 MHz User Clock
│
├── 125 MHz Ethernet Clock
│
├── 200 MHz Memory Clock
│
└── PCIe User Clock
```

---

# 6. Multiple Clock Domains

Modern FPGA projects frequently use more than one clock.

Example:

```text
PCIe Interface
      │
      ▼
PCIe Clock Domain
      │
      ▼
CDC Logic
      │
      ▼
User Clock Domain
```

Signals cannot always be connected directly between unrelated clock domains.

They may require:

```text
Clock Domain Crossing
```

logic.

---

# 7. Clock Sources

FPGA clocks may come from different sources.

Examples include:

```text
Board Oscillator
PCIe Reference Clock
External Device Clock
Recovered Clock
Clock Generator
PLL
MMCM
```

A board may contain an external oscillator such as:

```text
100 MHz
```

which is connected to an FPGA clock-capable input pin.

---

# 8. Differential Clocks

High-speed interfaces often use differential clock signals.

For example:

```text
REFCLK_P
REFCLK_N
```

Conceptually:

```text
REFCLK_P ─────┐
              ├── Differential Clock Input
REFCLK_N ─────┘
```

PCIe reference clocks are commonly differential.

The FPGA uses dedicated input buffers for these signals.

---

# 9. Clock Buffers

FPGA clock signals normally use dedicated clock routing resources.

In Xilinx/AMD devices, common clocking primitives include:

```text
IBUF
IBUFDS
BUFG
BUFGCE
```

For example:

```text
External Clock
      │
      ▼
Input Buffer
      │
      ▼
Global Clock Buffer
      │
      ▼
FPGA Logic
```

Global clock resources provide low-skew clock distribution across the FPGA.

---

# 10. MMCM and PLL

Xilinx/AMD FPGAs provide clock management resources such as:

```text
MMCM
PLL
```

These can generate new clocks from an input clock.

Example:

```text
100 MHz Input
      │
      ▼
MMCM
      │
      ├── 50 MHz
      ├── 100 MHz
      └── 200 MHz
```

They can also perform operations such as:

- Frequency multiplication
- Frequency division
- Phase shifting
- Duty-cycle adjustment

---

# 11. Avoid Creating Clocks with Logic

A common beginner mistake is creating a new clock using normal FPGA logic.

For example:

```systemverilog
logic slow_clk;

always_ff @(posedge clk) begin
    slow_clk <= ~slow_clk;
end
```

Although this may synthesize, using ordinary fabric signals as clocks can create clock routing and timing problems.

A better design often keeps one clock and uses:

```text
Clock Enable
```

instead.

---

# 12. Clock Enable

Instead of creating a slower clock, generate an enable pulse.

Example:

```systemverilog
logic [25:0] counter;
logic        tick;

always_ff @(posedge clk) begin

    if (!reset_n) begin
        counter <= '0;
        tick    <= 1'b0;
    end
    else begin

        tick <= 1'b0;

        if (counter == 26'd49_999_999) begin
            counter <= '0;
            tick    <= 1'b1;
        end
        else begin
            counter <= counter + 1'b1;
        end

    end

end
```

Then another block can use:

```systemverilog
if (tick)
```

while remaining in the same clock domain.

This often simplifies timing and CDC design.

---

# 13. What Is Reset?

A reset places FPGA logic into a known state.

Example:

```systemverilog
if (!reset_n)
    counter <= 8'h00;
```

A reset is useful for initializing:

```text
Registers
Counters
State Machines
Control Logic
Interfaces
```

---

# 14. Active-High Reset

An active-high reset is asserted when:

```text
reset = 1
```

Example:

```systemverilog
always_ff @(posedge clk) begin

    if (reset)
        counter <= '0;
    else
        counter <= counter + 1'b1;

end
```

---

# 15. Active-Low Reset

An active-low reset is asserted when:

```text
reset_n = 0
```

The suffix:

```text
_n
```

commonly indicates active-low logic.

Example:

```systemverilog
always_ff @(posedge clk) begin

    if (!reset_n)
        counter <= '0;
    else
        counter <= counter + 1'b1;

end
```

---

# 16. Synchronous Reset

A synchronous reset is sampled only on the active clock edge.

Example:

```systemverilog
always_ff @(posedge clk) begin

    if (!reset_n)
        state <= IDLE;
    else
        state <= next_state;

end
```

The reset affects the register when a rising edge of:

```text
clk
```

occurs.

---

# 17. Asynchronous Reset

An asynchronous reset can reset the register independently of the clock edge.

Example:

```systemverilog
always_ff @(posedge clk or negedge reset_n) begin

    if (!reset_n)
        state <= IDLE;
    else
        state <= next_state;

end
```

Here:

```text
reset_n
```

can immediately force the register into reset.

---

# 18. Synchronous vs Asynchronous Reset

Conceptually:

```text
Synchronous Reset
    │
    └── Reset action occurs with clock edge

Asynchronous Reset
    │
    └── Reset can assert without waiting for clock
```

Both approaches are used in FPGA designs.

The correct choice depends on:

- FPGA architecture
- Clock availability
- External reset requirements
- IP requirements
- Timing strategy

---

# 19. Reset Assertion and Deassertion

One important reset design technique is:

```text
Asynchronous Assert
Synchronous Deassert
```

This means reset can become active immediately.

But when reset is released, it is synchronized to the destination clock.

Conceptually:

```text
Reset Assert
     │
     ▼
Immediate

Reset Release
     │
     ▼
Synchronizer
     │
     ▼
Clock-Aligned Release
```

This helps reduce reset-release timing problems.

---

# 20. Reset Synchronizer

A simple reset synchronizer may look like:

```systemverilog
module reset_sync (
    input  logic clk,
    input  logic async_reset_n,
    output logic reset_n
);

    logic [1:0] sync_ff;

    always_ff @(posedge clk or negedge async_reset_n) begin

        if (!async_reset_n)
            sync_ff <= 2'b00;
        else
            sync_ff <= {sync_ff[0], 1'b1};

    end

    assign reset_n = sync_ff[1];

endmodule
```

Reset assertion is asynchronous.

Reset deassertion passes through two flip-flops.

---

# 21. Why Synchronize Reset Release?

Consider two registers leaving reset at slightly different times.

Without careful reset handling:

```text
Register A ── leaves reset
Register B ───── leaves reset slightly later
```

This may cause invalid intermediate states.

Synchronizing reset release helps the logic begin operation consistently relative to the destination clock.

---

# 22. What Is Metastability?

Metastability can occur when a signal changes too close to a flip-flop's sampling edge.

Example:

```text
Asynchronous Signal
        │
        ▼
Destination Flip-Flop
        │
        ▼
Potential Metastability
```

The flip-flop may temporarily enter an uncertain internal state before resolving to:

```text
0
```

or:

```text
1
```

---

# 23. Why Metastability Matters

A metastable signal can cause unpredictable behavior if it is used directly by other logic.

Potential problems include:

```text
Incorrect state transitions
Corrupted counters
Unexpected control behavior
Unstable interfaces
```

Metastability cannot be completely eliminated.

Instead, FPGA designs reduce the probability that it affects user logic.

---

# 24. Two-Flop Synchronizer

A common method for synchronizing a single-bit control signal is:

```text
Two-Flop Synchronizer
```

Conceptually:

```text
Async Signal
     │
     ▼
Flip-Flop 1
     │
     ▼
Flip-Flop 2
     │
     ▼
Synchronized Signal
```

Example:

```systemverilog
module bit_sync (
    input  logic clk,
    input  logic async_in,
    output logic sync_out
);

    logic sync_ff1;
    logic sync_ff2;

    always_ff @(posedge clk) begin

        sync_ff1 <= async_in;
        sync_ff2 <= sync_ff1;

    end

    assign sync_out = sync_ff2;

endmodule
```

---

# 25. Why Two Flip-Flops?

The first flip-flop may become metastable.

The second flip-flop provides additional time for the first stage to settle.

Conceptually:

```text
Async Signal
    │
    ▼
FF1
Possible Metastability
    │
    ▼
FF2
Stable Signal
```

This greatly reduces the probability of metastability propagating into the rest of the design.

---

# 26. Synchronizer Attributes

Vivado can be given information about synchronizer registers.

For example:

```systemverilog
(* ASYNC_REG = "TRUE" *) logic sync_ff1;
(* ASYNC_REG = "TRUE" *) logic sync_ff2;
```

Or:

```systemverilog
(* ASYNC_REG = "TRUE" *) logic [1:0] sync_ff;
```

This helps implementation tools recognize CDC synchronizer logic.

---

# 27. Clock Domain Crossing

When a signal moves between unrelated clocks, the operation is called:

```text
Clock Domain Crossing
```

or:

```text
CDC
```

Example:

```text
Clock Domain A
     │
     ▼
Signal
     │
     ▼
CDC Logic
     │
     ▼
Clock Domain B
```

CDC design must be handled carefully.

---

# 28. Single-Bit CDC

For a slowly changing single-bit control signal:

```text
enable
ready
status
interrupt
```

a two-flop synchronizer may be appropriate.

Example:

```text
Domain A
 enable
   │
   ▼
Synchronizer
   │
   ▼
Domain B
```

---

# 29. Why Multi-Bit Signals Are Different

A multi-bit bus should generally not be synchronized by independently placing each bit through separate two-flop synchronizers.

For example:

```text
data[31:0]
```

If each bit crosses independently, different bits may be captured during different source transitions.

The destination could observe:

```text
Corrupted Data
```

---

# 30. Example Multi-Bit Problem

Suppose a source bus changes from:

```text
0000
```

to:

```text
1111
```

The destination might temporarily capture:

```text
1010
```

because individual bits do not necessarily cross at exactly the same moment.

Therefore:

```text
Multi-bit CDC requires a proper protocol
```

---

# 31. Handshake Synchronization

One method for transferring multi-bit data is using a handshake.

Conceptually:

```text
Source Domain
     │
     ├── Data
     └── Valid
          │
          ▼
      CDC Handshake
          │
          ▼
Destination Domain
```

The source holds data stable while control signals communicate when the transfer is valid and complete.

---

# 32. Asynchronous FIFO

For transferring streams of data between different clock domains, a common solution is:

```text
Asynchronous FIFO
```

Conceptually:

```text
Write Clock Domain
        │
        ▼
   Async FIFO
        │
        ▼
Read Clock Domain
```

The write and read sides operate using different clocks.

---

# 33. Async FIFO Architecture

A simplified asynchronous FIFO contains:

```text
                Memory
             ┌──────────┐
Write Data ─▶│          │─▶ Read Data
             └──────────┘
                 ▲   ▲
                 │   │
           Write Ptr Read Ptr
                 │   │
             CDC Logic
```

Proper FIFO designs often use:

```text
Gray-code pointers
```

to safely synchronize pointer information between clock domains.

---

# 34. Pulse Crossing

A one-clock-cycle pulse in one domain may be missed by another clock domain.

Example:

```text
Source:
____|‾|________
```

If the destination clock never samples during the high period, the event can disappear.

Therefore short pulses require special CDC handling.

---

# 35. Pulse Stretching

One simple technique is:

```text
Pulse Stretching
```

The source keeps the signal active long enough for the destination clock to observe it.

However, this approach depends on known clock relationships and event rates.

For robust asynchronous interfaces, handshake or toggle-based synchronization is often preferable.

---

# 36. Toggle Synchronizer

A common event-transfer technique uses a toggling bit.

Instead of sending a short pulse:

```text
0 → 1 → 0
```

the source changes state once per event:

```text
Event 1:
0 → 1

Event 2:
1 → 0

Event 3:
0 → 1
```

The destination synchronizes the toggle and detects a change.

Conceptually:

```text
Source Event
    │
    ▼
Toggle Bit
    │
    ▼
2-FF Synchronizer
    │
    ▼
Change Detector
    │
    ▼
Destination Pulse
```

---

# 37. Related Clock Domains

Not all clock domains are completely asynchronous.

Some clocks are generated from the same clock source.

For example:

```text
100 MHz Input
      │
      ▼
MMCM
  │       │
  ▼       ▼
100 MHz  200 MHz
```

These clocks have a defined relationship.

Vivado timing analysis can often analyze crossings between related clocks automatically if the constraints are correct.

---

# 38. Asynchronous Clock Domains

Two clocks may have no fixed phase relationship.

Example:

```text
PCIe User Clock
```

and:

```text
External Ethernet Clock
```

These may be treated as asynchronous.

Crossings between them require explicit CDC architecture.

---

# 39. Clock Constraints

Vivado needs accurate clock constraints.

An XDC constraint might define a 100 MHz clock:

```tcl
create_clock -period 10.000 [get_ports clk]
```

This tells Vivado:

```text
Clock Period = 10 ns
```

which corresponds to:

```text
100 MHz
```

---

# 40. 200 MHz Clock Constraint

For:

```text
200 MHz
```

the period is:

```text
5 ns
```

Example:

```tcl
create_clock -period 5.000 [get_ports clk]
```

Vivado uses this information during timing analysis.

---

# 41. Generated Clocks

Clocks created by FPGA clock-management resources may be recognized or constrained as:

```text
Generated Clocks
```

For example:

```text
Input Clock
     │
     ▼
MMCM
     │
     ▼
Generated Clock
```

Accurate generated-clock relationships allow timing analysis between related domains.

---

# 42. Timing Analysis

After implementation, Vivado performs static timing analysis.

Important concepts include:

```text
Setup Time
Hold Time
Slack
Critical Path
```

A design with timing violations may work inconsistently or fail in hardware.

---

# 43. Setup Timing

Setup timing checks that data arrives before the destination register's sampling edge.

Conceptually:

```text
Source Register
      │
      ▼
Logic Delay
      │
      ▼
Destination Register
```

The data must arrive early enough to satisfy the destination register's setup requirement.

---

# 44. Hold Timing

Hold timing checks that data does not change too quickly after the sampling edge.

Both:

```text
Setup
```

and:

```text
Hold
```

requirements must be satisfied.

---

# 45. Timing Slack

Vivado reports:

```text
Slack
```

A simplified interpretation is:

```text
Positive Slack
      │
      ▼
Timing Requirement Met

Negative Slack
      │
      ▼
Timing Violation
```

For example:

```text
Slack = +1.2 ns
```

means the path meets the timing requirement with margin.

```text
Slack = -0.4 ns
```

means the path violates timing.

---

# 46. Critical Path

The:

```text
Critical Path
```

is one of the longest or most timing-limited paths in the design.

Example:

```text
Register
   │
   ▼
Large Logic Network
   │
   ▼
Register
```

Optimizing critical paths may require:

- Pipelining
- Reducing combinational depth
- Changing architecture
- Improving placement
- Adjusting clock frequency

---

# 47. Pipelining

Pipelining divides a long logic path into smaller stages.

Before:

```text
Register
   │
   ▼
Large Logic
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
```

This can improve the maximum achievable clock frequency.

---

# 48. PCIe Reference Clock

PCIe systems commonly provide a dedicated reference clock.

Conceptually:

```text
PCIe Connector
      │
      ▼
PCIe REFCLK
      │
      ▼
FPGA Transceiver / PCIe IP
```

The exact clocking requirements depend on:

- FPGA family
- PCIe generation
- Board design
- PCIe IP configuration

Always follow the hardware and IP documentation for the selected device.

---

# 49. PCIe PERST#

PCIe systems commonly provide:

```text
PERST#
```

This is the PCIe reset signal.

It is active low.

Conceptually:

```text
Host
 │
 └── PERST# ───▶ FPGA PCIe Logic
```

The FPGA must correctly handle reset timing relative to:

```text
Reference Clock
Power
PCIe IP
User Logic
```

---

# 50. PCIe User Clock

PCIe IP often provides a clock for the user-side transaction interface.

Conceptually:

```text
PCIe IP
   │
   ├── User Clock
   ├── User Reset
   └── Transaction Interface
```

Logic directly connected to the PCIe transaction interface typically operates in this PCIe user clock domain.

---

# 51. PCIe and User Logic Domains

Suppose custom user logic operates on another clock.

Then the design may look like:

```text
PCIe User Clock Domain
        │
        ▼
PCIe Interface
        │
        ▼
CDC
        │
        ▼
Application Clock Domain
```

This CDC boundary must be explicitly designed.

---

# 52. Example Architecture

A scalable PCIe FPGA architecture might look like:

```text
                  FPGA
                    │
         ┌──────────┴──────────┐
         │                     │
         ▼                     ▼
 PCIe Clock Domain       User Clock Domain
         │                     │
         ▼                     ▼
     PCIe IP              User Logic
         │                     ▲
         ▼                     │
  BAR / TLP Logic         CDC Interface
         │                     ▲
         └────────── CDC ──────┘
```

---

# 53. Reset Per Clock Domain

If a design contains multiple clocks, each domain should generally have reset handling appropriate for that clock.

Example:

```text
Global Reset
    │
    ├── Reset Synchronizer → PCIe Clock Domain
    │
    ├── Reset Synchronizer → User Clock Domain
    │
    └── Reset Synchronizer → Memory Clock Domain
```

This prevents one unsynchronized reset-release signal from being used everywhere.

---

# 54. Example Reset Structure

Conceptually:

```text
async_reset_n
      │
      ├───────────────┐
      │               │
      ▼               ▼
reset_sync         reset_sync
      │               │
      ▼               ▼
reset_pcie_n       reset_user_n
      │               │
      ▼               ▼
PCIe Domain        User Domain
```

Each synchronizer uses its destination clock.

---

# 55. CDC Verification

CDC problems can be difficult to reproduce because failures may depend on exact timing relationships.

Therefore CDC should be designed intentionally rather than relying only on hardware testing.

Useful approaches include:

```text
CDC Design Review
Vivado CDC Reports
Simulation
Timing Constraints
Hardware Testing
```

---

# 56. Vivado CDC Analysis

Vivado provides reports that can help identify suspicious clock-domain crossings.

For example, designers can inspect CDC-related analysis after synthesis or implementation.

The exact workflow depends on Vivado version and project configuration.

CDC analysis should support good architecture rather than replace it.

---

# 57. Common Clock Mistakes

Common mistakes include:

```text
Using a normal logic signal as a clock

Missing clock constraints

Sending asynchronous inputs directly into logic

Synchronizing each bit of a data bus independently

Sending one-cycle pulses directly between unrelated clocks

Releasing resets asynchronously into complex logic

Ignoring timing violations

Assuming simulation success guarantees hardware timing
```

---

# 58. Recommended Clock Design Rules

Useful rules include:

```text
1. Use dedicated clock resources.

2. Define every important clock correctly.

3. Prefer clock enables over fabric-generated clocks.

4. Treat unrelated clocks as separate domains.

5. Use synchronizers for asynchronous single-bit signals.

6. Use handshakes or async FIFOs for multi-bit data.

7. Synchronize reset release per clock domain.

8. Review timing and CDC reports.

9. Never ignore unexplained timing violations.
```

---

# 59. Example Source Structure

Our project may eventually include:

```text
src/
│
├── top.sv
│
├── modules/
│   ├── counter.sv
│   ├── bit_sync.sv
│   └── reset_sync.sv
│
└── pcie/
    ├── pcie_wrapper.sv
    ├── bar_controller.sv
    └── register_block.sv
```

The synchronization modules can be reused throughout the project.

---

# 60. What We Learned

In this chapter, we learned:

```text
Clock and Reset Design
        │
        ├── Clock Frequency
        ├── Clock Period
        ├── Clock Domains
        ├── MMCM / PLL
        ├── Clock Enables
        ├── Synchronous Reset
        ├── Asynchronous Reset
        ├── Reset Synchronization
        ├── Metastability
        ├── Two-Flop Synchronizers
        ├── CDC
        ├── Async FIFOs
        ├── Timing Constraints
        └── PCIe Clock / Reset
```

Reliable clock and reset architecture is one of the foundations of stable FPGA hardware.

---

# Next Chapter

Continue to:

**[Chapter 10 — FPGA Constraints with XDC](10-xdc-constraints.md)**

In the next chapter, we will learn how Vivado uses XDC constraints to describe the physical and timing requirements of an FPGA design.

We will cover:

```text
Pin Assignments
IOSTANDARD
Clock Constraints
Differential Signals
Timing Constraints
False Paths
Clock Groups
PCIe Pins
Constraint Organization
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
