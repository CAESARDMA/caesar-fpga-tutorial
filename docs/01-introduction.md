# Chapter 01 — How FPGA Firmware Is Actually Built

[← Back to README](../README.md)

---

## Introduction

FPGA firmware is very different from traditional software.

When you write a normal application, the CPU executes your instructions one by one.

An FPGA works differently.

Instead of executing software instructions, the FPGA is configured to behave like a custom digital circuit.

This means that HDL code does not simply become a normal executable file.

The development process looks more like this:

```text
HDL Source Code
      │
      ▼
Synthesis
      │
      ▼
Logical Netlist
      │
      ▼
Implementation
      │
      ▼
Placement & Routing
      │
      ▼
Timing Analysis
      │
      ▼
Bitstream
      │
      ▼
FPGA Configuration
