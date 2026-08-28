# Chapter 12 — Timing Analysis and Timing Closure

[← Previous Chapter](11-synthesis-implementation.md) | [Back to README](../README.md)

---

## Introduction

A design that synthesizes successfully is not automatically a reliable FPGA design.

The implementation must also meet timing.

Timing analysis checks whether signals can travel through the FPGA fast enough to satisfy the requirements of each clock domain.

In this chapter, we will cover:

- Setup time
- Hold time
- Arrival time
- Required time
- Slack
- WNS
- TNS
- Critical paths
- Logic delay
- Routing delay
- Clock skew
- Clock uncertainty
- Timing reports
- Pipelining
- Fanout
- Timing closure
- Common timing mistakes

---

# 1. Why Timing Matters

FPGA logic is usually synchronous.

A typical data path looks like:

```text
Source Register
      │
      ▼
Combinational Logic
      │
      ▼
Destination Register
```

The source register launches data on one clock edge.

The destination register must receive stable data before the next required clock edge.

If the data arrives too late:

```text
Timing Violation
```

occurs.

---

# 2. Example Clock Period

Suppose the design uses:

```text
100 MHz
```

The clock period is:

```text
10 ns
```

So the full data path must fit within the available timing budget.

Conceptually:

```text
Clock Edge
   │
   ▼
Source FF
   │
   ▼
Logic
   │
   ▼
Routing
   │
   ▼
Destination FF
```

The total delay must satisfy the timing requirement.

---

# 3. Setup Time

A destination flip-flop requires data to be stable slightly before the active clock edge.

This requirement is called:

```text
Setup Time
```

Conceptually:

```text
Data
─────────────── stable ─────────────

                         Clock Edge
                             │
                             ▼
```

The data must arrive before that edge with enough margin.

---

# 4. Setup Violation

Suppose:

```text
Required Arrival:
10.0 ns

Actual Arrival:
10.7 ns
```

The data arrives:

```text
0.7 ns too late
```

This creates a setup timing violation.

Conceptually:

```text
Required Time  = 10.0 ns
Arrival Time   = 10.7 ns
Slack          = -0.7 ns
```

---

# 5. Hold Time

A destination flip-flop also requires the data to remain stable for a short time after the active clock edge.

This requirement is called:

```text
Hold Time
```

A hold violation occurs if new data reaches the destination too quickly.

---

# 6. Setup vs Hold

The two main timing requirements are:

```text
Setup
→ Data must not arrive too late

Hold
→ Data must not change too early
```

Both must be satisfied.

A design can pass setup timing but fail hold timing.

---

# 7. Arrival Time

The:

```text
Arrival Time
```

represents when data reaches the destination.

It includes delays such as:

```text
Clock-to-Q Delay
Logic Delay
Routing Delay
```

Conceptually:

```text
Source FF
   │
   ▼
Clock-to-Q
   │
   ▼
Logic Delay
   │
   ▼
Routing Delay
   │
   ▼
Destination
```

---

# 8. Required Time

The:

```text
Required Time
```

represents when the data needs to arrive.

This depends on:

- Clock period
- Clock relationship
- Setup requirement
- Clock skew
- Clock uncertainty
- Timing constraints

Vivado compares:

```text
Arrival Time
```

with:

```text
Required Time
```

---

# 9. Slack

Slack represents the remaining timing margin.

For setup timing, conceptually:

```text
Slack = Required Time - Arrival Time
```

Example:

```text
Required Time = 10.0 ns
Arrival Time  = 8.5 ns

Slack = +1.5 ns
```

This path passes timing.

---

# 10. Negative Slack

Example:

```text
Required Time = 10.0 ns
Arrival Time  = 11.2 ns

Slack = -1.2 ns
```

The path fails timing.

Negative slack means:

```text
The design cannot reliably meet the specified timing requirement.
```

---

# 11. Timing Margin

Positive slack provides timing margin.

Example:

```text
Slack = +2.0 ns
```

means the path has significant margin.

Example:

```text
Slack = +0.01 ns
```

technically passes, but with very little margin.

Designs with better timing margin are generally easier to maintain.

---

# 12. WNS

Vivado commonly reports:

```text
WNS
```

which stands for:

```text
Worst Negative Slack
```

It represents the worst setup slack among the analyzed timing paths.

Example:

```text
WNS = +0.350 ns
```

means the worst analyzed setup path still passes.

Example:

```text
WNS = -1.150 ns
```

means at least one setup path fails.

---

# 13. TNS

Vivado also reports:

```text
TNS
```

which stands for:

```text
Total Negative Slack
```

TNS adds the negative slack of all failing setup endpoints.

For example:

```text
Path 1 = -1.0 ns
Path 2 = -0.5 ns
Path 3 = -0.2 ns
```

Then conceptually:

```text
TNS = -1.7 ns
```

---

# 14. Why WNS and TNS Are Both Useful

WNS tells you:

```text
How bad is the worst path?
```

TNS tells you:

```text
How widespread are the failures?
```

Example:

```text
WNS = -3.0 ns
TNS = -3.0 ns
```

may indicate one very bad path.

While:

```text
WNS = -0.3 ns
TNS = -100 ns
```

may indicate many small failures.

---

# 15. Critical Path

A:

```text
Critical Path
```

is one of the most timing-limited paths in the design.

For example:

```text
Register A
    │
    ▼
Comparator
    │
    ▼
Adder
    │
    ▼
Multiplexer
    │
    ▼
Register B
```

Too much combinational logic can make this path slow.

---

# 16. Logic Delay

Logic delay is the delay through FPGA logic resources.

Examples include:

```text
LUTs
Carry Chains
MUXes
DSP Logic
```

A long chain of logic increases total delay.

---

# 17. Routing Delay

Routing delay comes from the programmable interconnect between FPGA resources.

Example:

```text
LUT
 │
 │ Long Route
 │
 ▼
Flip-Flop
```

In many FPGA designs, routing delay can be as important as logic delay.

Sometimes routing delay is larger than the actual LUT delay.

---

# 18. Why Routing Delay Increases

Routing delay may increase because of:

```text
Long physical distance

High fanout

Routing congestion

Poor placement

Large device utilization

Clock region boundaries
```

This is why implementation quality matters.

---

# 19. Clock-to-Q Delay

After a clock edge, the source flip-flop does not change its output instantly.

There is a delay called:

```text
Clock-to-Q
```

Conceptually:

```text
Clock Edge
    │
    ▼
Source FF
    │
    ▼
Q Changes
```

This delay is included in the timing path.

---

# 20. Clock Skew

Clock signals do not necessarily reach every register at exactly the same moment.

The difference is called:

```text
Clock Skew
```

Conceptually:

```text
Clock Source
   │
   ├──▶ Register A
   │
   └──────▶ Register B
```

Dedicated FPGA clock networks are designed to minimize skew.

---

# 21. Clock Uncertainty

Timing analysis may also include:

```text
Clock Uncertainty
```

This accounts for effects such as:

- Jitter
- Clock variation
- Modeling margin

Clock uncertainty reduces the available timing budget.

---

# 22. Timing Budget

Suppose the clock period is:

```text
10 ns
```

That does not necessarily mean the full 10 ns is available for logic.

Conceptually:

```text
10 ns Clock Period
      │
      ├── Clock Uncertainty
      ├── Setup Requirement
      ├── Clock Skew
      └── Data Path
```

The usable data-path budget may be smaller.

---

# 23. Vivado Timing Summary

After implementation, open:

```text
Report Timing Summary
```

This is one of the most important reports in Vivado.

It provides information such as:

```text
WNS
TNS
Setup Violations
Hold Violations
Pulse Width Checks
Clock Information
```

---

# 24. Timing Summary Example

A timing summary might conceptually show:

```text
Setup:
WNS = 0.542 ns
TNS = 0.000 ns

Hold:
WHS = 0.103 ns
THS = 0.000 ns
```

This indicates that analyzed setup and hold timing pass.

---

# 25. WHS

Vivado may report:

```text
WHS
```

which stands for:

```text
Worst Hold Slack
```

A negative hold slack indicates a hold timing failure.

---

# 26. THS

Vivado may also report:

```text
THS
```

which represents total negative hold slack across failing endpoints.

As with setup timing, both the worst path and the total number of failures are useful.

---

# 27. Timing Path Details

A detailed timing report usually contains:

```text
Startpoint
Endpoint
Clock
Data Path Delay
Logic Delay
Routing Delay
Required Time
Arrival Time
Slack
```

These values help determine why a path is failing.

---

# 28. Example Failing Path

Suppose Vivado reports:

```text
Startpoint:
counter_reg[31]

Endpoint:
status_reg[0]

Logic Delay:
3.2 ns

Routing Delay:
7.1 ns

Total Data Path:
10.3 ns

Required:
9.5 ns

Slack:
-0.8 ns
```

Here, the problem is mostly:

```text
Routing Delay
```

rather than logic complexity.

---

# 29. Another Failing Path

Example:

```text
Logic Delay:
8.0 ns

Routing Delay:
1.5 ns
```

In this case, the problem is likely too much combinational logic.

The fix may require changing the RTL architecture.

---

# 30. Timing Closure

The process of fixing timing violations is called:

```text
Timing Closure
```

The goal is to reach:

```text
No unexplained timing violations
```

for all intended timing paths.

---

# 31. Timing Closure Is Iterative

Timing closure often looks like:

```text
Build
 │
 ▼
Check Timing
 │
 ▼
Find Critical Path
 │
 ▼
Change RTL / Constraints
 │
 ▼
Build Again
 │
 ▼
Check Timing
```

This process may repeat many times in a complex FPGA project.

---

# 32. Pipelining

One of the most powerful timing-closure techniques is:

```text
Pipelining
```

Suppose we have:

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

All logic must complete in one clock period.

---

# 33. Add Pipeline Registers

We can split the path:

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

Now each stage has less work to perform during one clock cycle.

---

# 34. Pipeline Example

Before:

```systemverilog
always_ff @(posedge clk) begin
    result <= ((a + b) * c) + d;
end
```

This may create a long combinational path.

A pipelined version could conceptually split the operation:

```systemverilog
logic [31:0] sum_stage;
logic [63:0] mult_stage;

always_ff @(posedge clk) begin

    sum_stage  <= a + b;
    mult_stage <= sum_stage * c;
    result     <= mult_stage + d;

end
```

This increases latency but may improve clock frequency.

---

# 35. Latency vs Throughput

Pipelining introduces:

```text
Latency
```

but can improve:

```text
Throughput
```

For example:

```text
Latency:
3 clock cycles

Throughput:
1 result per clock cycle
```

once the pipeline is full.

This is a fundamental FPGA architecture concept.

---

# 36. Reduce Logic Depth

Another timing technique is reducing:

```text
Combinational Logic Depth
```

For example, avoid excessively long chains of:

```text
if
else if
else if
else if
...
```

when a better parallel or pipelined structure can be used.

---

# 37. Large Multiplexers

A large multiplexer can become timing-critical.

Example:

```text
64 possible inputs
       │
       ▼
Large MUX
       │
       ▼
Output Register
```

Possible solutions include:

- Hierarchical muxing
- Pipelining
- Registering intermediate results
- Changing the architecture

---

# 38. Long Arithmetic Chains

Example:

```text
A
│
▼
Adder
│
▼
Adder
│
▼
Comparator
│
▼
MUX
│
▼
Register
```

This creates multiple logic levels.

Breaking arithmetic into pipeline stages can improve timing.

---

# 39. High Fanout

A high-fanout signal drives many loads.

Example:

```text
enable
 │
 ├──▶ Block 1
 ├──▶ Block 2
 ├──▶ Block 3
 ├──▶ ...
 └──▶ Block 500
```

This may increase routing delay.

---

# 40. High-Fanout Control Signals

Common high-fanout signals include:

```text
Reset
Enable
Global Status
Mode Select
Control Bits
```

Possible strategies include:

- Register duplication
- Hierarchical distribution
- Local enables
- Proper clock-enable resources

Vivado can also perform some optimization automatically.

---

# 41. Placement Problems

A timing path may fail because connected logic is placed too far apart.

Example:

```text
Source
[Left side of FPGA]

        Long Route

Destination
[Right side of FPGA]
```

Placement can sometimes be improved by:

- Better hierarchy
- Pipelining
- Reducing congestion
- Floorplanning
- Architectural changes

---

# 42. Floorplanning

Advanced designs may use:

```text
Floorplanning
```

to guide placement.

For example, specific modules may be constrained to particular FPGA regions.

Vivado provides concepts such as:

```text
Pblocks
```

for placement control.

Floorplanning should normally be used only when there is a clear reason.

---

# 43. Do Not Floorplan Too Early

Manual placement constraints can sometimes make implementation worse.

A useful rule is:

```text
Let Vivado place the design automatically first.
```

Only consider floorplanning when reports show a specific physical problem.

---

# 44. Clock Frequency Reduction

If a design cannot meet:

```text
250 MHz
```

but meets:

```text
200 MHz
```

one possible solution is reducing the required clock frequency.

For example:

```text
250 MHz
→ 4 ns period

200 MHz
→ 5 ns period
```

The additional 1 ns may make timing significantly easier.

However, this reduces performance.

---

# 45. Constraints Must Be Correct

Timing analysis is only meaningful when the constraints are correct.

For example:

```tcl
create_clock -period 10.000 [get_ports clk]
```

for a real:

```text
200 MHz
```

clock would be wrong.

Vivado would analyze the design as if the requirement were only:

```text
100 MHz
```

and could report a false sense of success.

---

# 46. Over-Constraining

The opposite problem is:

```text
Over-Constraining
```

For example, a real:

```text
100 MHz
```

clock constrained as:

```text
300 MHz
```

creates an unnecessarily strict requirement.

This may make timing closure much harder than necessary.

Constraints should describe the real hardware requirements.

---

# 47. False Paths

A false path tells Vivado not to perform normal timing analysis on a particular path.

Example conceptually:

```tcl
set_false_path ...
```

This is powerful but dangerous.

A false path does not fix timing.

It tells the timing engine:

```text
This path does not require normal timing analysis.
```

Only use it when the hardware architecture justifies that assumption.

---

# 48. Multicycle Paths

Some paths are intentionally allowed more than one clock cycle.

These can sometimes be constrained using:

```text
Multicycle Paths
```

For example:

```text
Operation requires 2 cycles
```

rather than one.

Again, this must reflect the actual RTL behavior.

Do not use multicycle constraints simply to hide a failing path.

---

# 49. Asynchronous Clock Crossings

Timing paths between unrelated asynchronous clock domains should not be treated like normal synchronous paths.

Example:

```text
Clock A
   │
   ▼
CDC Logic
   │
   ▼
Clock B
```

Correct CDC architecture should be used.

Then the clock relationship should be constrained appropriately.

---

# 50. CDC Is Not Timing Closure

It is important to separate:

```text
Timing Closure
```

from:

```text
Clock Domain Crossing
```

A CDC signal can be timing-exempt between asynchronous domains but still be functionally unsafe.

For example:

```text
set_clock_groups -asynchronous
```

does not create a synchronizer.

The RTL must already contain proper CDC logic.

---

# 51. Timing and PCIe

PCIe FPGA designs can have strict timing requirements because they may operate at relatively high user-clock frequencies.

Example architecture:

```text
PCIe IP
   │
   ▼
PCIe User Clock
   │
   ▼
TLP Logic
   │
   ▼
BAR Logic
```

If too much logic exists between pipeline registers, PCIe user logic may fail timing.

---

# 52. PCIe Data Width

A wider PCIe streaming interface may process many bits simultaneously.

Example:

```text
64-bit
128-bit
256-bit
512-bit
```

depending on the FPGA/IP architecture.

Wider interfaces can increase routing pressure and combinational complexity.

Good pipelining becomes increasingly important.

---

# 53. BAR Decoder Timing

A simple BAR decoder might contain:

```systemverilog
case (address)

    16'h0000: read_data = device_id;
    16'h0004: read_data = version;
    16'h0008: read_data = control;
    16'h000C: read_data = status;

endcase
```

This is usually small.

But if the register map grows to hundreds or thousands of complex conditions, address decoding may become timing-critical.

Hierarchical decoding can help.

---

# 54. Hierarchical Address Decoding

Instead of one huge decoder:

```text
Address
  │
  ▼
Huge Decoder
  │
  ├── Register 1
  ├── Register 2
  ├── ...
  └── Register 1000
```

a design might use:

```text
Address
  │
  ▼
Region Decoder
  │
  ├── Control Block
  ├── Status Block
  ├── Memory Block
  └── Debug Block
```

Each block then performs local address decoding.

This improves scalability.

---

# 55. Register Critical Outputs

Sometimes timing improves by registering long combinational outputs.

Before:

```text
Complex Logic
     │
     ▼
Interface
```

After:

```text
Complex Logic
     │
     ▼
Register
     │
     ▼
Interface
```

The additional pipeline stage creates a clean timing boundary.

---

# 56. Timing Reports by Clock

In multi-clock designs, review timing per clock domain.

Example:

```text
Clock: pcie_user_clk
WNS: +0.12 ns

Clock: user_clk
WNS: +2.31 ns
```

This immediately shows which domain is closest to its limit.

---

# 57. Clock Interaction

Vivado:

```text
Report Clock Interaction
```

can help identify relationships between clock domains.

This is useful for designs containing:

```text
PCIe Clock
System Clock
Memory Clock
External Clock
```

Review unexpected clock interactions carefully.

---

# 58. Timing Paths Through BRAM

Block RAM has defined timing characteristics.

A BRAM-based path might look like:

```text
Address Register
      │
      ▼
BRAM
      │
      ▼
Output Register
```

Using BRAM output registers can sometimes improve timing.

---

# 59. Timing Paths Through DSP

DSP resources often support internal pipeline registers.

For high-frequency arithmetic, enabling these pipeline stages can significantly improve timing.

Conceptually:

```text
Input Register
     │
     ▼
DSP
     │
     ▼
Pipeline Register
     │
     ▼
Output
```

---

# 60. Optimization Directives

Vivado provides implementation strategies and directives that can influence:

```text
Optimization
Placement
Routing
Physical Optimization
```

These can sometimes improve timing.

However:

```text
Tool options cannot replace a bad RTL architecture.
```

Fix structural problems first.

---

# 61. Physical Optimization

Vivado can perform:

```text
Physical Optimization
```

to improve difficult timing paths.

Techniques may include:

- Register replication
- Logic optimization
- Placement improvement
- Routing optimization

This can help close small remaining violations.

---

# 62. Timing Regression

A design may meet timing in one commit and fail after a later RTL change.

This is called a:

```text
Timing Regression
```

Therefore professional FPGA projects should monitor timing continuously.

For example:

```text
Version 1
WNS = +1.2 ns

Version 2
WNS = +0.4 ns

Version 3
WNS = -0.6 ns
```

Version 3 introduced a timing problem.

---

# 63. Keep Timing Reports

For important releases, it is useful to record:

```text
Vivado Version
FPGA Device
Clock Frequencies
WNS
TNS
Utilization
Build Commit
```

This makes firmware builds easier to compare.

---

# 64. Timing Closure Workflow

A practical timing-closure workflow is:

```text
Run Implementation
      │
      ▼
Open Timing Summary
      │
      ▼
Identify Worst Path
      │
      ▼
Check:
Logic or Routing?
      │
      ▼
Review RTL Architecture
      │
      ▼
Add Pipeline / Reduce Fanout / Fix Constraint
      │
      ▼
Rebuild
      │
      ▼
Compare WNS / TNS
```

---

# 65. Questions to Ask About a Failing Path

When timing fails, ask:

```text
Which clock domain is failing?

What is the startpoint?

What is the endpoint?

How much delay is logic?

How much delay is routing?

Is the path expected?

Are the constraints correct?

Can the path be pipelined?

Is fanout too high?

Is this actually a CDC path?

Is the clock frequency realistic?
```

---

# 66. Common Bad Approach

A bad timing workflow is:

```text
Timing Fails
    │
    ▼
Add False Path
    │
    ▼
Timing Warning Disappears
    │
    ▼
Assume Fixed
```

This may hide a real hardware problem.

Timing exceptions should only describe intentional design behavior.

---

# 67. Better Approach

A better workflow is:

```text
Timing Fails
    │
    ▼
Understand the Path
    │
    ▼
Check Constraints
    │
    ▼
Check Architecture
    │
    ▼
Fix Root Cause
    │
    ▼
Re-run Timing
```

---

# 68. When Is Timing Done?

For a basic project, timing can be considered clean when:

```text
All intended clock domains are correctly constrained

No unexplained setup violations exist

No unexplained hold violations exist

CDC paths are intentionally handled

Timing exceptions are justified

Critical paths have acceptable margin
```

---

# 69. Timing Clean Does Not Mean Functionally Correct

A design can meet timing and still contain logical bugs.

Timing analysis checks:

```text
Can signals arrive on time?
```

It does not check:

```text
Does the design perform the correct function?
```

Therefore reliable FPGA development also requires:

```text
Simulation
Hardware Testing
Protocol Verification
```

---

# 70. What We Learned

In this chapter, we learned:

```text
Timing Analysis
      │
      ├── Setup Time
      ├── Hold Time
      ├── Arrival Time
      ├── Required Time
      ├── Slack
      ├── WNS
      ├── TNS
      ├── Critical Paths
      ├── Logic Delay
      ├── Routing Delay
      ├── Clock Skew
      ├── Clock Uncertainty
      ├── Pipelining
      └── Timing Closure
```

Timing closure ensures that the implemented FPGA design can reliably operate at the required clock frequencies.

---

# Next Chapter

Continue to:

**[Chapter 13 — Generating the FPGA Bitstream](13-generate-bitstream.md)**

In the next chapter, we will learn how Vivado converts the implemented FPGA design into the configuration file that is loaded into the FPGA.

We will cover:

```text
Bitstream Generation
.bit Files
.bin Files
Configuration Memory
JTAG Programming
SPI Flash
Bitstream Properties
Build Outputs
Firmware Releases
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
