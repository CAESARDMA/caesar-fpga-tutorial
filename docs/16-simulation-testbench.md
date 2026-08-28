# Chapter 16 — Simulation and Testbenches

[← Previous Chapter](15-vivado-tcl.md) | [Back to README](../README.md)

---

## Introduction

Programming an FPGA every time you want to test a small logic change is slow.

A much better development workflow is:

```text
Write RTL
   │
   ▼
Simulate
   │
   ▼
Fix Logic Problems
   │
   ▼
Synthesize
   │
   ▼
Program Hardware
```

Simulation allows us to test FPGA logic before the design reaches real hardware.

A simulation environment usually contains:

```text
Design Under Test
+
Testbench
+
Stimulus
+
Waveform
+
Checks
```

In this chapter, we will cover:

- FPGA simulation
- Testbenches
- DUT
- Clock generation
- Reset generation
- Input stimulus
- Waveforms
- Timing in simulation
- Self-checking testbenches
- Assertions
- Counter testing
- Register testing
- BAR logic testing
- Simulation mistakes
- Vivado Simulator
- Simulation workflow

---

# 1. What Is Simulation?

Simulation executes a model of the HDL design on a computer.

Instead of configuring a real FPGA:

```text
SystemVerilog
      │
      ▼
Simulator
      │
      ▼
Waveforms
```

This lets developers observe internal signals over time.

---

# 2. Simulation Is Not FPGA Execution

It is important to understand:

```text
Simulation
≠
Real FPGA Hardware
```

Simulation models the behavior of the RTL.

Real hardware introduces additional factors such as:

```text
Physical Timing

Clock Jitter

Signal Integrity

Board Wiring

Power

PCIe Link Training

Metastability
```

Simulation is still one of the most important FPGA development tools.

---

# 3. What Is a Testbench?

A:

```text
Testbench
```

is HDL code written to test another HDL module.

The module being tested is commonly called:

```text
DUT
```

which stands for:

```text
Design Under Test
```

Conceptually:

```text
Testbench
   │
   ├── Clock
   ├── Reset
   ├── Inputs
   │
   ▼
DUT
   │
   ▼
Outputs
   │
   ▼
Testbench Checks
```

---

# 4. Testbench vs Synthesizable RTL

Normal FPGA RTL should describe hardware that can be synthesized.

A testbench does not need to be synthesizable.

For example, testbenches can use:

```systemverilog
#10;
```

for simulation delays.

This does not create FPGA hardware.

It only controls simulated time.

---

# 5. Testbench File Naming

A common convention is:

```text
tb_<module>.sv
```

Examples:

```text
tb_counter.sv

tb_register_block.sv

tb_top.sv
```

This makes simulation files easy to identify.

---

# 6. Recommended Simulation Directory

A clean repository may contain:

```text
sim/
│
├── tb_counter.sv
├── tb_register_block.sv
└── tb_top.sv
```

This keeps testbenches separate from synthesizable source code.

---

# 7. Basic Testbench Structure

A simple testbench might look like:

```systemverilog
module tb_counter;

    logic clk;
    logic reset_n;
    logic [7:0] count;

    counter dut (
        .clk     (clk),
        .reset_n (reset_n),
        .count   (count)
    );

endmodule
```

Here:

```text
dut
```

is the instance of the module being tested.

---

# 8. Testbench Has No Physical Ports

A typical testbench does not need top-level input or output ports.

For example:

```systemverilog
module tb_counter;
```

instead of:

```systemverilog
module tb_counter (
    input logic clk
);
```

The testbench itself generates the stimulus.

---

# 9. Clock Generation

A testbench can generate a clock.

Example:

```systemverilog
initial begin
    clk = 1'b0;

    forever #5 clk = ~clk;
end
```

This creates a clock with:

```text
5 ns LOW
5 ns HIGH
```

for a total period of:

```text
10 ns
```

which corresponds to:

```text
100 MHz
```

---

# 10. Shorter Clock Syntax

A common alternative is:

```systemverilog
always #5 clk = ~clk;
```

with an initial value:

```systemverilog
initial clk = 1'b0;
```

Together:

```systemverilog
initial clk = 1'b0;

always #5 clk = ~clk;
```

---

# 11. Timescale

Simulation delays require a time unit.

A SystemVerilog file may define:

```systemverilog
`timescale 1ns/1ps
```

This means:

```text
Time Unit:
1 ns

Time Precision:
1 ps
```

Then:

```systemverilog
#5
```

means:

```text
5 ns
```

---

# 12. Modern SystemVerilog Time Units

SystemVerilog also supports constructs such as:

```systemverilog
timeunit 1ns;
timeprecision 1ps;
```

For example:

```systemverilog
module tb_counter;

    timeunit 1ns;
    timeprecision 1ps;

```

Either style may be encountered in FPGA projects.

---

# 13. Reset Generation

A testbench should normally put the DUT into a known reset state.

Example:

```systemverilog
initial begin

    reset_n = 1'b0;

    #100;

    reset_n = 1'b1;

end
```

Conceptually:

```text
Simulation Starts
      │
      ▼
Reset Asserted
      │
      ▼
Wait
      │
      ▼
Reset Released
```

---

# 14. Reset Synchronized to Clock

For synchronous designs, reset stimulus can also be released relative to clock edges.

Example:

```systemverilog
initial begin

    reset_n = 1'b0;

    repeat (5)
        @(posedge clk);

    reset_n = 1'b1;

end
```

This waits for five rising clock edges before releasing reset.

---

# 15. `@(posedge clk)`

The statement:

```systemverilog
@(posedge clk);
```

means:

```text
Wait until the next rising edge of clk.
```

This is extremely useful in testbenches.

Example:

```systemverilog
@(posedge clk);
enable = 1'b1;
```

---

# 16. `repeat`

A testbench can wait for multiple events.

Example:

```systemverilog
repeat (10)
    @(posedge clk);
```

This means:

```text
Wait for 10 rising clock edges.
```

---

# 17. Complete Counter Testbench

For our counter module:

```systemverilog
module counter (
    input  logic       clk,
    input  logic       reset_n,
    output logic [7:0] count
);

    always_ff @(posedge clk) begin

        if (!reset_n)
            count <= 8'h00;
        else
            count <= count + 1'b1;

    end

endmodule
```

A simple testbench could be:

```systemverilog
`timescale 1ns/1ps

module tb_counter;

    logic clk;
    logic reset_n;

    logic [7:0] count;

    counter dut (
        .clk     (clk),
        .reset_n (reset_n),
        .count   (count)
    );

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    initial begin

        reset_n = 1'b0;

        repeat (5)
            @(posedge clk);

        reset_n = 1'b1;

        repeat (20)
            @(posedge clk);

        $finish;

    end

endmodule
```

---

# 18. `$finish`

The command:

```systemverilog
$finish;
```

ends the simulation.

Without an end condition, a clock generator such as:

```systemverilog
forever #5 clk = ~clk;
```

would continue forever.

---

# 19. `$display`

A testbench can print information.

Example:

```systemverilog
$display("Simulation started");
```

You can also print values:

```systemverilog
$display("count = %0d", count);
```

This is similar to logging in software.

---

# 20. `$monitor`

Another useful simulation task is:

```systemverilog
$monitor
```

Example:

```systemverilog
$monitor(
    "time=%0t reset_n=%b count=%0d",
    $time,
    reset_n,
    count
);
```

This prints a new message whenever one of the referenced signals changes.

---

# 21. `$time`

The system function:

```systemverilog
$time
```

returns the current simulation time.

Example:

```systemverilog
$display(
    "Time = %0t",
    $time
);
```

This helps correlate console messages with waveforms.

---

# 22. Waveforms

One of the main outputs of simulation is a waveform.

Example:

```text
clk
_|‾|_|‾|_|‾|_|‾|_|‾|_

reset_n
_____|‾‾‾‾‾‾‾‾‾‾‾‾‾

count
0000 0000 0001 0002 0003
```

Waveforms make digital logic behavior much easier to understand.

---

# 23. Vivado Simulator

Vivado includes a built-in simulator commonly used through:

```text
Run Simulation
```

In the Flow Navigator:

```text
SIMULATION
     │
     ▼
Run Simulation
     │
     ▼
Run Behavioral Simulation
```

This launches the RTL simulation environment.

---

# 24. Behavioral Simulation

Behavioral simulation runs before synthesis.

It primarily tests:

```text
RTL Functionality
```

This is usually the fastest and most common form of simulation during development.

---

# 25. Post-Synthesis Simulation

It is also possible to simulate a synthesized design.

Conceptually:

```text
RTL
 │
 ▼
Synthesis
 │
 ▼
Netlist
 │
 ▼
Simulation
```

This can help verify behavior after synthesis transformations.

For most everyday RTL development, behavioral simulation should come first.

---

# 26. Post-Implementation Simulation

More advanced workflows can simulate an implemented netlist.

This may include timing information.

Conceptually:

```text
Implemented Design
       │
       ▼
Timing Model
       │
       ▼
Simulation
```

These simulations can be much slower than behavioral simulation.

---

# 27. Add Simulation Sources

In Vivado:

```text
Add Sources
     │
     ▼
Add or Create Simulation Sources
```

Then add:

```text
tb_counter.sv
```

Vivado stores testbench files in the simulation source set.

---

# 28. Simulation Top Module

The simulation top is normally the testbench.

For example:

```text
tb_counter
```

rather than:

```text
counter
```

Vivado then launches the DUT through the testbench instance.

---

# 29. DUT Instantiation

The testbench connects signals to the DUT.

Example:

```systemverilog
counter dut (
    .clk     (clk),
    .reset_n (reset_n),
    .count   (count)
);
```

This connection is just like normal module hierarchy.

---

# 30. Generate Input Stimulus

A testbench controls DUT inputs.

Suppose a module contains:

```systemverilog
input logic enable;
```

The testbench can do:

```systemverilog
enable = 1'b0;

repeat (5)
    @(posedge clk);

enable = 1'b1;
```

This tests the module under different conditions.

---

# 31. Stimulus Sequence

A useful test sequence may look like:

```text
Reset DUT
    │
    ▼
Wait
    │
    ▼
Enable Feature
    │
    ▼
Send Input
    │
    ▼
Observe Output
    │
    ▼
Check Result
```

---

# 32. Manual Waveform Checking

The simplest simulation workflow is:

```text
Run Simulation

Look at Waveforms

Decide if Result Is Correct
```

This is useful while learning.

But larger projects should increasingly use automatic checks.

---

# 33. Self-Checking Testbench

A:

```text
Self-Checking Testbench
```

automatically determines whether the DUT behaves correctly.

Instead of manually viewing every waveform:

```text
Expected Result
      │
      ▼
Compare
      │
      ▼
Actual Result
      │
      ▼
PASS / FAIL
```

---

# 34. Simple Automatic Check

Example:

```systemverilog
if (count !== 8'd10) begin

    $error(
        "Expected count=10, got %0d",
        count
    );

end
```

This automatically reports an error when the output is incorrect.

---

# 35. `==` vs `===`

Simulation contains four-state values:

```text
0
1
X
Z
```

The normal equality operator:

```systemverilog
==
```

has different behavior around unknown values.

For strict testbench comparisons, developers often use:

```systemverilog
===
```

or:

```systemverilog
!==
```

to account explicitly for X and Z states.

---

# 36. `$error`

SystemVerilog provides:

```systemverilog
$error
```

Example:

```systemverilog
$error("Counter value incorrect");
```

This reports a simulation error.

---

# 37. `$fatal`

For serious failures:

```systemverilog
$fatal
```

can stop the test.

Example:

```systemverilog
if (device_id !== 32'h43414553)
    $fatal("DEVICE_ID is incorrect");
```

---

# 38. `$warning`

Tests can also report:

```systemverilog
$warning
```

for non-fatal conditions.

Example:

```systemverilog
$warning("Unexpected status value");
```

---

# 39. Testbench PASS Message

A successful test can print:

```systemverilog
$display("==============================");
$display("TEST PASSED");
$display("==============================");

$finish;
```

A clear final status makes automated simulation logs easier to read.

---

# 40. Improved Counter Testbench

A self-checking counter testbench:

```systemverilog
`timescale 1ns/1ps

module tb_counter;

    logic clk;
    logic reset_n;

    logic [7:0] count;

    counter dut (
        .clk     (clk),
        .reset_n (reset_n),
        .count   (count)
    );

    initial clk = 1'b0;

    always #5 clk = ~clk;

    initial begin

        reset_n = 1'b0;

        repeat (3)
            @(posedge clk);

        reset_n = 1'b1;

        repeat (10)
            @(posedge clk);

        if (count !== 8'd10) begin

            $fatal(
                "TEST FAILED: Expected 10, got %0d",
                count
            );

        end

        $display("TEST PASSED");

        $finish;

    end

endmodule
```

---

# 41. Watch for Simulation Scheduling

When testing sequential logic, remember that nonblocking assignments:

```systemverilog
<=
```

update later in the current simulation time step.

For example:

```systemverilog
@(posedge clk);

$display("%0d", count);
```

may observe the value before the DUT's nonblocking assignment has completed, depending on the intended sampling point.

Testbenches should account for simulation event scheduling.

---

# 42. Safer Sampling

One approach is to check signals after the active clock edge has settled.

For educational testbenches, you may use a small simulation delay:

```systemverilog
@(posedge clk);
#1;

if (count !== expected)
    $error("Wrong value");
```

The `#1` is testbench-only logic.

It is not synthesized.

---

# 43. Clocking Blocks

More advanced SystemVerilog verification environments may use:

```text
Clocking Blocks
```

to define testbench sampling and driving relationships.

For a beginner FPGA tutorial, simple event-based testbenches are usually easier to understand.

---

# 44. Assertions

SystemVerilog supports:

```text
Assertions
```

which automatically verify properties of the design.

A simple immediate assertion looks like:

```systemverilog
assert (count == expected)
else
    $error("Count mismatch");
```

---

# 45. Example Assertion

```systemverilog
assert (device_id == 32'h43414553)
else
    $fatal("DEVICE_ID mismatch");
```

Assertions make expected behavior explicit.

---

# 46. Concurrent Assertions

SystemVerilog also supports more advanced temporal assertions.

These can describe relationships across clock cycles.

Conceptually:

```text
If Request Happens
      │
      ▼
Response Must Follow
```

This is extremely powerful for protocol verification.

However, detailed SystemVerilog Assertion language is beyond the scope of this introductory tutorial.

---

# 47. Testing Reset

A good testbench should verify reset behavior.

For example:

```systemverilog
reset_n = 1'b0;

@(posedge clk);
#1;

assert (count == 8'h00)
else
    $fatal("Counter did not reset");
```

This confirms that the reset path works.

---

# 48. Testing Reset More Than Once

Do not assume reset only occurs at simulation startup.

A stronger test may:

```text
Start

Reset

Run

Reset Again

Run Again
```

This can reveal state machines or counters that do not reset correctly.

---

# 49. Example Second Reset

```systemverilog
reset_n = 1'b1;

repeat (10)
    @(posedge clk);

reset_n = 1'b0;

repeat (2)
    @(posedge clk);

reset_n = 1'b1;
```

Then verify the design returns to the expected state.

---

# 50. Register Block Simulation

Earlier we introduced a register map:

```text
0x0000 DEVICE_ID
0x0004 VERSION
0x0008 CONTROL
0x000C STATUS
```

A testbench can verify this logic without requiring a PCIe connection.

Conceptually:

```text
Testbench
   │
   ├── Address
   ├── Read Enable
   ├── Write Enable
   └── Write Data
        │
        ▼
Register Block
        │
        ▼
Read Data
```

---

# 51. Test the DEVICE_ID Register

A test might drive:

```text
Address = 0x0000
Read Enable = 1
```

Then expect:

```text
Read Data = 0x43414553
```

This verifies address decoding and register values.

---

# 52. Example Register Read Task

Testbenches can define reusable tasks.

Example:

```systemverilog
task automatic read_register(
    input logic [15:0] address,
    input logic [31:0] expected
);

    read_addr = address;
    read_en   = 1'b1;

    @(posedge clk);
    #1;

    read_en = 1'b0;

    if (read_data !== expected)
        $fatal(
            "Read failed: address=%h expected=%h actual=%h",
            address,
            expected,
            read_data
        );

endtask
```

This lets us reuse the same test logic.

---

# 53. What Is a Task?

A SystemVerilog:

```text
task
```

is useful for grouping repeated simulation actions.

Example use cases:

```text
Register Read

Register Write

Send Packet

Wait for Ready

Check Output
```

Tasks make testbenches cleaner.

---

# 54. Register Write Task

Conceptually:

```systemverilog
task automatic write_register(
    input logic [15:0] address,
    input logic [31:0] data
);

    write_addr = address;
    write_data = data;
    write_en   = 1'b1;

    @(posedge clk);

    write_en = 1'b0;

endtask
```

Then the testbench can simply call:

```systemverilog
write_register(
    16'h0008,
    32'h00000001
);
```

---

# 55. Register Readback Test

After writing:

```text
CONTROL = 1
```

read it back.

Conceptually:

```systemverilog
write_register(
    16'h0008,
    32'h00000001
);

read_register(
    16'h0008,
    32'h00000001
);
```

This tests both read and write paths.

---

# 56. BAR Logic Without PCIe Hardware

It is important to separate:

```text
PCIe Transport Logic
```

from:

```text
Register / BAR Logic
```

Then BAR-related application logic can be simulated independently.

Conceptually:

```text
PCIe Interface
      │
      ▼
Simple Internal Register Interface
      │
      ▼
Register Block
```

The testbench can drive that internal interface directly.

---

# 57. Layered Verification

A scalable verification strategy tests modules individually.

Example:

```text
counter
   │
   ▼
Unit Test

register_block
   │
   ▼
Unit Test

bar_controller
   │
   ▼
Unit Test

pcie_wrapper
   │
   ▼
Integration Test

top
   │
   ▼
System Test
```

This makes bugs much easier to locate.

---

# 58. Unit Testing

A:

```text
Unit Test
```

tests one module or small block.

Examples:

```text
Counter Test

Reset Synchronizer Test

Register Block Test

FIFO Test
```

Unit tests should be:

```text
Small

Fast

Focused

Repeatable
```

---

# 59. Integration Testing

An:

```text
Integration Test
```

tests multiple connected modules.

Example:

```text
BAR Controller
      │
      ▼
Register Block
      │
      ▼
Application Logic
```

This verifies that interfaces between modules work correctly.

---

# 60. Simulation Hierarchy

A testbench may instantiate the complete top-level design.

Example:

```text
tb_top
  │
  ▼
top
  │
  ├── pcie_wrapper
  ├── register_block
  └── user_logic
```

This gives more complete coverage but is usually more complex than unit testing.

---

# 61. Unknown Values

Simulation may show:

```text
X
```

which means:

```text
Unknown
```

Example:

```text
count = XXXXXXXX
```

This often indicates:

```text
Signal Never Initialized

Reset Missing

Multiple Drivers

Incomplete Logic

Unknown Input
```

Do not automatically ignore X values.

---

# 62. High-Impedance Values

Simulation can also show:

```text
Z
```

which means:

```text
High Impedance
```

This is commonly associated with:

```text
Tri-State Signals

Undriven Nets
```

Internal FPGA designs usually avoid unnecessary tri-state logic.

---

# 63. X Propagation

An unknown input may propagate through logic.

Example:

```text
Input = X
   │
   ▼
AND / MUX / Arithmetic
   │
   ▼
Output = X
```

This can help reveal missing initialization.

---

# 64. Do Not Initialize Everything Just to Hide X

If you see:

```text
X
```

do not simply assign random initial values everywhere.

First determine why the value is unknown.

Ask:

```text
Should this register be reset?

Is the input being driven?

Is the state machine initialized?

Is there a missing branch?
```

---

# 65. FSM Simulation

State machines should be tested through expected transitions.

Example:

```text
IDLE
 │
 ▼
WAIT
 │
 ▼
TRANSFER
 │
 ▼
IDLE
```

The testbench can drive inputs and check the resulting states.

---

# 66. Illegal FSM States

If a state machine supports an:

```text
ERROR
```

state, tests should intentionally exercise error conditions.

Good verification includes both:

```text
Normal Behavior
```

and:

```text
Failure Behavior
```

---

# 67. Boundary Testing

Registers and counters should be tested around boundaries.

For example, an 8-bit counter eventually moves:

```text
254
255
0
1
```

A test can verify rollover behavior.

---

# 68. Test More Than the Happy Path

A weak test only verifies:

```text
Normal Input
→ Normal Output
```

A stronger test also checks:

```text
Reset

Invalid Address

Maximum Value

Minimum Value

Repeated Transactions

Back-to-Back Operations
```

---

# 69. Invalid Address Test

For a register map, test an undefined address.

Example:

```text
0x00FC
```

Expected behavior might be:

```text
Read returns 0
```

or another documented value.

The important point is that behavior should be defined and tested.

---

# 70. Byte Enable Testing

If the register block supports:

```text
Byte Enables
```

test partial writes.

For example:

```text
Initial:
0x11223344

Write only low byte:
0x000000AA

Result:
0x112233AA
```

This verifies byte-level write behavior.

---

# 71. Back-to-Back Transactions

Test consecutive operations:

```text
Write
Write
Write
Read
Read
```

without large idle gaps.

This can reveal interface logic that only works when transactions are widely separated.

---

# 72. Randomized Testing

More advanced testbenches may generate randomized input values.

Example:

```systemverilog
data = $urandom;
```

Random testing can discover corner cases that hand-written tests miss.

However, random tests should still have automatic result checking.

---

# 73. `$urandom`

SystemVerilog provides:

```systemverilog
$urandom
```

for pseudo-random values.

Example:

```systemverilog
logic [31:0] random_data;

random_data = $urandom;
```

You can write the value and then verify it reads back correctly.

---

# 74. Deterministic Tests

For bug reproduction, deterministic simulation is very useful.

If using random stimulus, record or control the random seed.

This allows:

```text
Failing Test
→ Run Again
→ Same Stimulus
→ Same Failure
```

---

# 75. Test Timeout

A testbench should avoid waiting forever.

For example:

```systemverilog
initial begin

    #100000;

    $fatal(
        "Simulation timeout"
    );

end
```

If the main test never finishes, the timeout stops the simulation and reports a failure.

---

# 76. Why Timeouts Matter

Suppose the testbench waits for:

```text
ready == 1
```

but the DUT contains a bug and never asserts ready.

Without a timeout:

```text
Simulation Runs Forever
```

A timeout converts the hang into a useful failure.

---

# 77. Wait for Conditions

Testbenches may use:

```systemverilog
wait (ready == 1'b1);
```

This pauses until the condition becomes true.

Use it together with timeouts when there is a possibility the condition never occurs.

---

# 78. Expected Values

A testbench often maintains its own expected value.

Example:

```systemverilog
logic [7:0] expected_count;
```

Each cycle:

```systemverilog
expected_count++;
```

Then compare:

```systemverilog
assert (count == expected_count);
```

This creates a simple reference model.

---

# 79. Reference Model

A:

```text
Reference Model
```

predicts what the DUT should produce.

Conceptually:

```text
Input
 ├──────────────▶ DUT
 │                 │
 │                 ▼
 │              Actual
 │
 └──────────────▶ Reference Model
                   │
                   ▼
                Expected

Expected
   │
   ▼
Compare
   ▲
   │
Actual
```

This is the foundation of sophisticated verification systems.

---

# 80. Scoreboards

More advanced testbenches use:

```text
Scoreboards
```

to compare expected and actual transactions.

For a simple tutorial, direct assertions and tasks are usually sufficient.

But the underlying concept is the same:

```text
Predict

Observe

Compare
```

---

# 81. Simulation Logging

Useful simulation logs should clearly identify:

```text
Test Name

Operation

Expected Value

Actual Value

Simulation Time
```

Example:

```text
[120 ns] READ 0x0000 = 0x43414553 PASS
```

This makes failures much easier to understand.

---

# 82. Example Test Sequence

A register-block simulation could run:

```text
1. Assert reset

2. Release reset

3. Read DEVICE_ID

4. Read VERSION

5. Read CONTROL reset value

6. Write CONTROL

7. Read CONTROL back

8. Test invalid address

9. Assert reset again

10. Verify CONTROL reset value

11. PASS
```

This is already much stronger than simply looking at one waveform.

---

# 83. Example Testbench Structure

A structured testbench may look like:

```systemverilog
module tb_register_block;

    // Signals

    // DUT

    // Clock generation

    // Tasks

    // Timeout

    // Main test

endmodule
```

Keeping these sections organized makes the testbench easier to maintain.

---

# 84. Example Main Test

Conceptually:

```systemverilog
initial begin

    reset_n = 1'b0;

    repeat (5)
        @(posedge clk);

    reset_n = 1'b1;

    read_register(
        16'h0000,
        32'h43414553
    );

    read_register(
        16'h0004,
        32'h00010000
    );

    write_register(
        16'h0008,
        32'h12345678
    );

    read_register(
        16'h0008,
        32'h12345678
    );

    $display("TEST PASSED");

    $finish;

end
```

---

# 85. Simulation Before Hardware

A useful engineering rule is:

```text
If logic can be tested in simulation,
test it in simulation first.
```

Hardware debugging is valuable, but it is slower and introduces more variables.

Simulation is excellent for isolating pure RTL problems.

---

# 86. Simulation Cannot Verify Board Pins

Simulation cannot prove that:

```text
The LED is really connected to A10

The PCIe lane is routed correctly

The board oscillator is present
```

Those are physical hardware questions.

Simulation verifies digital design behavior.

---

# 87. Simulation Cannot Replace Timing Analysis

A behavioral simulation may appear correct even if the FPGA cannot meet its required clock frequency.

Therefore the complete workflow is:

```text
Simulation
+
Synthesis
+
Implementation
+
Timing Analysis
+
Hardware Test
```

Each stage answers a different question.

---

# 88. Simulation and PCIe

A complete PCIe protocol simulation can become complex.

Professional PCIe verification may use:

```text
Bus Functional Models

Verification IP

Protocol Models
```

For an introductory project, it is often better to test custom logic behind the PCIe interface separately.

---

# 89. Separate PCIe Transport from Application Logic

A clean architecture may look like:

```text
PCIe IP
   │
   ▼
PCIe Protocol Adapter
   │
   ▼
Internal Request Interface
   │
   ▼
BAR / Register Logic
```

Then simulation can directly drive the internal request interface.

This keeps the testbench manageable.

---

# 90. Example Internal Interface

A simple internal register interface might use:

```text
req_valid

req_write

req_addr

req_wdata

req_be

rsp_valid

rsp_rdata
```

The PCIe transport converts TLPs into this simpler internal interface.

The application logic does not need to understand every PCIe packet field.

---

# 91. Benefits of Interface Separation

This allows:

```text
PCIe Transport
→ Test separately

Register Logic
→ Test separately

Application Logic
→ Test separately
```

Good module boundaries improve both development and verification.

---

# 92. Simulation Files in Git

Testbenches are source code and should normally be stored in Git.

For example:

```text
sim/
├── tb_counter.sv
└── tb_register_block.sv
```

Unlike generated simulator output, the testbench itself should be version controlled.

---

# 93. Generated Simulation Files

Vivado simulation may create generated directories and logs.

These should usually remain excluded by:

```text
.gitignore
```

The important files are:

```text
RTL

Testbench

Scripts

Expected Test Data
```

not temporary simulator output.

---

# 94. Automating Simulation

Just like synthesis, simulation can eventually be automated.

Conceptually:

```text
Run Testbench
     │
     ▼
Assertions
     │
     ▼
PASS / FAIL
```

This allows tests to run automatically after RTL changes.

---

# 95. Regression Testing

A collection of automated simulations is often called a:

```text
Regression
```

Example:

```text
Test 1:
Counter

Test 2:
Register Block

Test 3:
FIFO

Test 4:
BAR Decoder

Test 5:
Integration
```

Run all tests after significant changes.

---

# 96. Why Regression Tests Matter

Suppose you modify the BAR controller.

The new version fixes one issue but accidentally breaks register writes.

A regression suite can detect this immediately.

Conceptually:

```text
Change RTL
   │
   ▼
Run Tests
   │
   ├── Counter PASS
   ├── Registers FAIL
   ├── FIFO PASS
   └── Integration FAIL
```

This helps prevent old bugs from returning.

---

# 97. A Good Test Is Repeatable

A useful test should produce the same result when nothing relevant changes.

Avoid tests that depend on:

```text
Manual GUI interaction

Uncontrolled random behavior

Undefined initialization

Hidden external state
```

Repeatability makes debugging easier.

---

# 98. Name Tests Clearly

Instead of:

```text
test1.sv
test2.sv
```

prefer:

```text
tb_counter.sv

tb_register_block.sv

tb_bar_controller.sv
```

Clear naming makes a repository easier to understand.

---

# 99. Document What Each Test Proves

For example:

```text
tb_counter.sv
→ Verifies reset and increment behavior

tb_register_block.sv
→ Verifies DEVICE_ID, VERSION and CONTROL registers

tb_bar_controller.sv
→ Verifies BAR address decoding
```

This helps contributors understand the verification strategy.

---

# 100. Recommended Verification Workflow

A practical FPGA verification process is:

```text
Write Module
     │
     ▼
Write Testbench
     │
     ▼
Run Behavioral Simulation
     │
     ▼
Check Assertions
     │
     ▼
Fix RTL
     │
     ▼
Run Regression
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
Test Hardware
```

---

# 101. What We Learned

In this chapter, we learned:

```text
FPGA Verification
       │
       ├── Simulation
       ├── Testbenches
       ├── DUT
       ├── Clock Generation
       ├── Reset Generation
       ├── Stimulus
       ├── Waveforms
       ├── Tasks
       ├── Assertions
       ├── Self-Checking Tests
       ├── Register Testing
       ├── BAR Logic Testing
       ├── Unit Testing
       ├── Integration Testing
       └── Regression Testing
```

Simulation helps detect RTL bugs before they become hardware-debugging problems.

---

# Next Chapter

Continue to:

**[Chapter 17 — Final Build, Verification, and Project Packaging](17-final-project.md)**

In the final chapter, we will combine everything from the tutorial into a complete FPGA development workflow.

We will cover:

```text
Final Repository Structure
Source Organization
Constraints
Simulation
Vivado Build
Timing Verification
Bitstream Generation
Hardware Verification
Release Packaging
Documentation
Versioning
Open-Source Project Structure
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
