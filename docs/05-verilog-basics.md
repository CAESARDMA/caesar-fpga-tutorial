# Chapter 05 — Verilog & SystemVerilog Basics

[← Previous Chapter](04-project-structure.md) | [Back to README](../README.md)

---

## Introduction

FPGA development is based on hardware description languages.

The two most common languages used in modern FPGA projects are:

- Verilog
- SystemVerilog

In this tutorial, we will mainly use:

```text
SystemVerilog
```

SystemVerilog extends Verilog with additional syntax and features that make RTL design easier to write, understand and maintain.

In this chapter, we will cover:

- Modules
- Inputs and outputs
- `logic`
- Continuous assignments
- Combinational logic
- Sequential logic
- Counters
- Registers
- Parameters
- Module instantiation
- Finite State Machines

---

# 1. What Is HDL?

HDL stands for:

```text
Hardware Description Language
```

Unlike normal software languages, HDL describes digital hardware.

For example:

```systemverilog
assign y = a & b;
```

does not mean:

```text
Run an AND instruction
```

Instead, it describes actual combinational logic:

```text
a ───┐
     AND ─── y
b ───┘
```

The FPGA implements this logic directly in hardware.

---

# 2. The Basic Module

The basic building block in Verilog and SystemVerilog is called a:

```text
module
```

Example:

```systemverilog
module example (
    input  logic a,
    input  logic b,
    output logic y
);

    assign y = a & b;

endmodule
```

The module has:

```text
Inputs:
a
b

Output:
y
```

The logic implements:

```text
y = a AND b
```

---

# 3. Module Structure

A simple module usually follows this structure:

```systemverilog
module module_name (
    // Ports
);

    // Internal signals

    // Logic

endmodule
```

For example:

```systemverilog
module caesar_example (
    input  logic clk,
    input  logic reset_n,
    output logic led
);

    // Logic goes here

endmodule
```

---

# 4. Inputs and Outputs

Module ports connect hardware blocks together.

Example:

```systemverilog
module example (
    input  logic clk,
    input  logic reset_n,
    output logic status
);
```

This defines:

```text
clk       → input
reset_n   → input
status    → output
```

Port directions include:

```text
input
output
inout
```

For most internal FPGA logic, `input` and `output` are used most often.

---

# 5. What Is `logic`?

SystemVerilog introduces:

```systemverilog
logic
```

Example:

```systemverilog
logic enable;
```

A signal can also contain multiple bits:

```systemverilog
logic [7:0] data;
```

This creates an 8-bit signal:

```text
data[7]
data[6]
data[5]
data[4]
data[3]
data[2]
data[1]
data[0]
```

---

# 6. Single-Bit and Multi-Bit Signals

Single-bit:

```systemverilog
logic ready;
```

8-bit:

```systemverilog
logic [7:0] value;
```

16-bit:

```systemverilog
logic [15:0] value;
```

32-bit:

```systemverilog
logic [31:0] value;
```

The general form is:

```text
[MSB:LSB]
```

For example:

```systemverilog
logic [31:0] data;
```

means:

```text
Most Significant Bit = 31
Least Significant Bit = 0
```

---

# 7. Binary, Hex and Decimal Values

HDL values can be written using different number formats.

Binary:

```systemverilog
8'b10101010
```

Hexadecimal:

```systemverilog
8'hAA
```

Decimal:

```systemverilog
8'd170
```

All three represent the same value.

General syntax:

```text
<width>'<base><value>
```

Examples:

```systemverilog
4'b1111
8'hFF
16'd1000
32'h12345678
```

---

# 8. Continuous Assignment

Combinational logic can be written using:

```systemverilog
assign
```

Example:

```systemverilog
assign y = a & b;
```

Other operators include:

```text
&   AND
|   OR
^   XOR
~   NOT
```

Example:

```systemverilog
assign result = (a & b) | c;
```

---

# 9. Basic Logic Operators

## AND

```systemverilog
assign y = a & b;
```

## OR

```systemverilog
assign y = a | b;
```

## XOR

```systemverilog
assign y = a ^ b;
```

## NOT

```systemverilog
assign y = ~a;
```

---

# 10. Comparisons

SystemVerilog supports comparisons such as:

```text
==
!=
<
>
<=
>=
```

Example:

```systemverilog
assign equal = (a == b);
```

Example:

```systemverilog
assign greater = (a > b);
```

---

# 11. Combinational Logic with `always_comb`

More complex combinational logic can use:

```systemverilog
always_comb
```

Example:

```systemverilog
module mux_example (
    input  logic a,
    input  logic b,
    input  logic select,
    output logic y
);

    always_comb begin
        if (select)
            y = b;
        else
            y = a;
    end

endmodule
```

This describes a:

```text
2-to-1 Multiplexer
```

Conceptually:

```text
        ┌─────────┐
a ─────▶│         │
        │   MUX   ├────▶ y
b ─────▶│         │
        └────┬────┘
             │
           select
```

---

# 12. Sequential Logic

Sequential logic usually depends on a clock.

In SystemVerilog, clocked logic can be written using:

```systemverilog
always_ff
```

Example:

```systemverilog
always_ff @(posedge clk) begin
    q <= d;
end
```

This describes a flip-flop.

Conceptually:

```text
d ─────▶ [ D Flip-Flop ] ─────▶ q
                ▲
                │
               clk
```

---

# 13. Blocking vs Non-Blocking Assignment

Two assignment operators are commonly seen in HDL:

```text
=
<=
```

For combinational logic:

```systemverilog
=
```

is commonly used.

Example:

```systemverilog
always_comb begin
    y = a & b;
end
```

For sequential clocked logic:

```systemverilog
<=
```

is normally used.

Example:

```systemverilog
always_ff @(posedge clk) begin
    q <= d;
end
```

A useful rule:

```text
Combinational logic → =
Sequential logic    → <=
```

---

# 14. Registers

A register stores a value between clock cycles.

Example:

```systemverilog
logic [7:0] data_reg;

always_ff @(posedge clk) begin
    data_reg <= data_in;
end
```

Conceptually:

```text
data_in
   │
   ▼
Register
   │
   ▼
data_reg
```

The register updates on the rising edge of the clock.

---

# 15. Reset Logic

Registers often require reset logic.

Example:

```systemverilog
always_ff @(posedge clk) begin
    if (!reset_n)
        data_reg <= 8'h00;
    else
        data_reg <= data_in;
end
```

When:

```text
reset_n = 0
```

the register becomes:

```text
0x00
```

Otherwise, it stores:

```text
data_in
```

---

# 16. Counters

A counter is one of the simplest sequential circuits.

Example:

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

Every rising edge of the clock increments:

```text
count
```

Example sequence:

```text
0
1
2
3
4
5
...
255
0
1
...
```

Because the counter is 8-bit, it wraps around after:

```text
255
```

---

# 17. Clock Frequency

Suppose the FPGA clock is:

```text
100 MHz
```

That means approximately:

```text
100,000,000 clock cycles per second
```

An 8-bit counter overflows every:

```text
256 clock cycles
```

At 100 MHz this happens very quickly.

Larger counters are often used for human-visible timing.

For example:

```systemverilog
logic [31:0] counter;
```

---

# 18. Counter Divider Example

A large counter can be used to create a slower signal.

Example:

```systemverilog
module clock_divider (
    input  logic clk,
    input  logic reset_n,
    output logic slow_signal
);

    logic [25:0] counter;

    always_ff @(posedge clk) begin
        if (!reset_n)
            counter <= '0;
        else
            counter <= counter + 1'b1;
    end

    assign slow_signal = counter[25];

endmodule
```

The upper counter bits change much more slowly than the input clock.

This technique is often used for simple demonstrations such as blinking an LED.

---

# 19. Parameters

Parameters allow modules to be configurable.

Example:

```systemverilog
module counter #(
    parameter WIDTH = 8
)(
    input  logic             clk,
    input  logic             reset_n,
    output logic [WIDTH-1:0] count
);

    always_ff @(posedge clk) begin
        if (!reset_n)
            count <= '0;
        else
            count <= count + 1'b1;
    end

endmodule
```

Now the same module can create different counter widths.

Example:

```systemverilog
counter #(
    .WIDTH(16)
) u_counter (
    .clk     (clk),
    .reset_n (reset_n),
    .count   (count)
);
```

This creates a:

```text
16-bit counter
```

---

# 20. Module Instantiation

Larger FPGA designs are created by connecting modules together.

Example:

```systemverilog
counter u_counter (
    .clk     (clk),
    .reset_n (reset_n),
    .count   (counter_out)
);
```

The syntax is:

```text
module_name instance_name (
    .module_port(signal),
    .module_port(signal)
);
```

This creates one instance of the hardware module.

---

# 21. Hierarchical Design

A project can contain multiple layers of modules.

Example:

```text
top
 │
 ├── clock_logic
 │
 ├── reset_logic
 │
 ├── counter
 │
 └── interface
```

A more advanced project might look like:

```text
top
 │
 ├── pcie_wrapper
 │    │
 │    ├── bar_controller
 │    └── register_block
 │
 ├── reset_sync
 │
 └── user_logic
```

This hierarchy allows complex designs to remain manageable.

---

# 22. `case` Statements

`case` is useful when one signal selects between several behaviors.

Example:

```systemverilog
always_comb begin
    case (select)
        2'b00: y = a;
        2'b01: y = b;
        2'b10: y = c;
        2'b11: y = d;
        default: y = '0;
    endcase
end
```

This describes a:

```text
4-to-1 multiplexer
```

---

# 23. Finite State Machines

A Finite State Machine, or:

```text
FSM
```

is a common FPGA design pattern.

An FSM moves between different states depending on inputs and events.

Example states:

```text
IDLE
  │
  ▼
START
  │
  ▼
WAIT
  │
  ▼
DONE
  │
  └────────────▶ IDLE
```

SystemVerilog provides the `enum` type, which is useful for state machines.

Example:

```systemverilog
typedef enum logic [1:0] {
    IDLE,
    START,
    WAIT_STATE,
    DONE
} state_t;

state_t state;
```

---

# 24. Simple FSM Example

```systemverilog
module simple_fsm (
    input  logic clk,
    input  logic reset_n,
    input  logic start,
    output logic done
);

    typedef enum logic [1:0] {
        IDLE,
        RUN,
        DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin
        if (!reset_n)
            state <= IDLE;
        else begin
            case (state)

                IDLE:
                    if (start)
                        state <= RUN;

                RUN:
                    state <= DONE;

                DONE:
                    state <= IDLE;

                default:
                    state <= IDLE;

            endcase
        end
    end

    always_comb begin
        done = 1'b0;

        if (state == DONE)
            done = 1'b1;
    end

endmodule
```

This design contains three states:

```text
IDLE
RUN
DONE
```

---

# 25. Why FSMs Matter

State machines are widely used in FPGA designs.

Examples include:

- Communication protocols
- PCIe control logic
- Memory controllers
- Initialization sequences
- Command processing
- Register interfaces
- Hardware control engines

Understanding FSMs is therefore an important FPGA development skill.

---

# 26. Common SystemVerilog Keywords

Some common keywords you will see throughout this tutorial:

```text
module
endmodule

input
output

logic

assign

always_comb
always_ff

if
else

case
endcase

parameter

typedef
enum
```

These are enough to build many basic RTL designs.

---

# 27. Example Source Structure

After adding more examples, our source tree may look like:

```text
src/
│
├── top.sv
│
└── modules/
    ├── counter.sv
    ├── mux.sv
    └── simple_fsm.sv
```

Each file should ideally contain one clearly defined hardware function.

---

# 28. Important HDL Design Principle

A useful rule when designing FPGA logic is:

```text
One module
    │
    ▼
One clear responsibility
```

For example:

```text
counter.sv
    ↓
Counter Logic

reset_sync.sv
    ↓
Reset Synchronization

register_block.sv
    ↓
Register Interface

pcie_wrapper.sv
    ↓
PCIe Interface
```

This makes larger FPGA projects easier to debug and maintain.

---

# 29. What We Learned

In this chapter, we covered:

```text
SystemVerilog
     │
     ├── Modules
     ├── Ports
     ├── logic
     ├── Combinational Logic
     ├── Sequential Logic
     ├── Registers
     ├── Counters
     ├── Parameters
     ├── Module Instantiation
     └── Finite State Machines
```

These concepts form the foundation of RTL development.

---

# Next Chapter

Continue to:

**[Chapter 06 — Creating a PCIe Endpoint](06-pcie-endpoint.md)**

In the next chapter, we will begin exploring PCI Express and learn how an FPGA can operate as a PCIe endpoint inside a host computer.

Topics will include:

```text
PCIe Architecture
Endpoint Devices
Root Complex
Configuration Space
Link Training
PCIe IP
FPGA PCIe Interfaces
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
