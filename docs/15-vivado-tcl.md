# Chapter 15 — Automating Vivado Builds with Tcl

[← Previous Chapter](14-program-debug.md) | [Back to README](../README.md)

---

## Introduction

Vivado can be used entirely through the graphical interface.

However, professional FPGA projects often automate the build process using:

```text
Tcl
```

Tcl scripts allow developers to recreate a Vivado project, add source files, run synthesis, perform implementation, generate reports and produce a bitstream automatically.

This improves:

- Reproducibility
- Collaboration
- Version control
- Continuous integration
- Release management

In this chapter, we will cover:

- Vivado Tcl
- Tcl Console
- Project creation
- Adding sources
- Adding constraints
- Setting the top module
- Synthesis
- Implementation
- Timing reports
- Bitstream generation
- Build directories
- Batch mode
- Reproducible builds
- Common scripting mistakes

---

# 1. What Is Tcl?

Tcl stands for:

```text
Tool Command Language
```

Vivado uses Tcl extensively.

Many actions performed in the GUI correspond to Tcl commands.

For example:

```text
Create Project
```

can be performed using:

```tcl
create_project
```

Likewise:

```text
Run Synthesis
```

can be controlled from Tcl.

---

# 2. Why Use Tcl?

A GUI project is convenient during development.

But GUI-only workflows can become difficult to reproduce.

For example:

```text
Developer A
    │
    ▼
Changes Vivado Setting
    │
    ▼
Developer B
    │
    ▼
Does Not Know Setting Changed
```

A scripted build makes the configuration explicit.

---

# 3. Reproducible Build

A reproducible build means another developer can use:

```text
Source Code
+
Constraints
+
Tcl Script
```

to recreate the project.

Conceptually:

```text
Git Repository
      │
      ▼
build.tcl
      │
      ▼
Vivado
      │
      ▼
Project
      │
      ▼
Bitstream
```

---

# 4. Vivado Tcl Console

Vivado contains an interactive:

```text
Tcl Console
```

Usually visible near the bottom of the interface.

You can type commands directly.

Example:

```tcl
pwd
```

This prints the current working directory.

---

# 5. Useful Basic Tcl Commands

Examples include:

```tcl
pwd
```

Show current directory.

```tcl
cd C:/FPGA
```

Change directory.

```tcl
puts "Hello FPGA"
```

Print text.

```tcl
file mkdir build
```

Create a directory.

---

# 6. Vivado-Specific Tcl Commands

Vivado adds FPGA-specific Tcl commands.

Examples:

```tcl
create_project
add_files
read_xdc
set_property
synth_design
opt_design
place_design
route_design
report_timing_summary
write_bitstream
```

These commands can automate most of the normal build flow.

---

# 7. Recommended Project Structure

Our project can eventually use:

```text
caesar-fpga-tutorial/
│
├── src/
│   ├── top.sv
│   └── modules/
│
├── constraints/
│   └── board.xdc
│
├── scripts/
│   └── build.tcl
│
├── docs/
│
├── images/
│
├── build/
│
├── .gitignore
└── README.md
```

The important automation file is:

```text
scripts/build.tcl
```

---

# 8. Keep Generated Files Separate

A good build script should place generated files in:

```text
build/
```

rather than mixing them with source files.

Conceptually:

```text
Source
│
├── src/
├── constraints/
└── scripts/

Generated
│
└── build/
```

This keeps Git clean.

---

# 9. Determine Script Location

A useful Tcl pattern is determining where the script itself is located.

Example:

```tcl
set script_dir [file dirname [file normalize [info script]]]
```

Now:

```text
script_dir
```

contains the directory of:

```text
build.tcl
```

---

# 10. Determine Repository Root

If the script lives in:

```text
scripts/build.tcl
```

then the repository root is one directory above it.

Example:

```tcl
set repo_dir [file normalize "$script_dir/.."]
```

This avoids depending on the directory from which Vivado was launched.

---

# 11. Define Build Directory

Example:

```tcl
set build_dir "$repo_dir/build"
```

Then create it if necessary:

```tcl
file mkdir $build_dir
```

Now all generated output can be placed in:

```text
build/
```

---

# 12. Define Project Name

A project name can be stored in a variable.

Example:

```tcl
set project_name "caesar_fpga"
```

Using variables makes scripts easier to modify.

---

# 13. Define FPGA Part

Vivado projects must target a specific FPGA device.

Example:

```tcl
set fpga_part "xc7a35tcpg236-1"
```

Then:

```tcl
create_project \
    $project_name \
    "$build_dir/$project_name" \
    -part $fpga_part \
    -force
```

Important:

```text
The FPGA part must match the actual target hardware.
```

Do not copy this example part into a real board build without verification.

---

# 14. `create_project`

Basic syntax:

```tcl
create_project project_name project_directory
```

Example:

```tcl
create_project caesar_fpga ./build/caesar_fpga
```

With a device:

```tcl
create_project \
    caesar_fpga \
    ./build/caesar_fpga \
    -part xc7a35tcpg236-1
```

---

# 15. The `-force` Option

The:

```text
-force
```

option allows Vivado to overwrite an existing project directory when appropriate.

Example:

```tcl
create_project \
    $project_name \
    "$build_dir/$project_name" \
    -part $fpga_part \
    -force
```

Use this carefully because existing generated project data may be replaced.

---

# 16. Adding Source Files

Vivado Tcl can add RTL using:

```tcl
add_files
```

Example:

```tcl
add_files "$repo_dir/src/top.sv"
```

Another source:

```tcl
add_files "$repo_dir/src/modules/counter.sv"
```

---

# 17. Add Multiple Source Files

You can also use a list.

Example:

```tcl
add_files [list \
    "$repo_dir/src/top.sv" \
    "$repo_dir/src/modules/counter.sv" \
]
```

This is convenient for small projects.

---

# 18. Automatically Find Source Files

For larger projects, Tcl can search directories.

Example:

```tcl
set rtl_files [glob -nocomplain \
    "$repo_dir/src/*.sv" \
    "$repo_dir/src/modules/*.sv"]
```

Then:

```tcl
add_files $rtl_files
```

This automatically adds matching SystemVerilog files.

---

# 19. Recursive Source Discovery

If the RTL tree becomes larger, files may exist in:

```text
src/
src/modules/
src/pcie/
src/utils/
```

You can either:

```text
List source directories explicitly
```

or create a controlled recursive file-discovery function.

Explicit source lists are often easier to review in production projects.

---

# 20. Why Explicit Source Lists Can Be Better

Automatically adding every `.sv` file is convenient.

But it may accidentally include:

```text
Old Files
Experimental Files
Alternative Top Modules
Testbench Files
Unused Implementations
```

An explicit source list makes the build deterministic.

---

# 21. Source Order

HDL compilation order can matter in some projects.

Vivado can determine much of the dependency order automatically.

You can ask Vivado to update compile order:

```tcl
update_compile_order -fileset sources_1
```

This is useful after adding RTL files.

---

# 22. SystemVerilog File Type

Files ending in:

```text
.sv
```

are normally treated as SystemVerilog.

If necessary, file properties can also be controlled explicitly.

Example conceptually:

```tcl
set_property file_type SystemVerilog [get_files *.sv]
```

Usually `.sv` naming is sufficient.

---

# 23. Adding XDC Constraints

Constraints can be added using:

```tcl
add_files -fileset constrs_1
```

Example:

```tcl
add_files \
    -fileset constrs_1 \
    "$repo_dir/constraints/board.xdc"
```

This adds the XDC file to the project constraint set.

---

# 24. Alternative: `read_xdc`

In non-project Tcl flows, constraints are often loaded with:

```tcl
read_xdc
```

Example:

```tcl
read_xdc "$repo_dir/constraints/board.xdc"
```

The command used depends on whether you are using:

```text
Project Mode
```

or:

```text
Non-Project Mode
```

---

# 25. Project Mode

Project Mode creates a standard Vivado project.

Conceptually:

```text
create_project
      │
      ▼
Add Sources
      │
      ▼
Run Managed Runs
```

Advantages include:

```text
GUI Integration

Run History

IP Management

Project Settings

Easy Beginner Workflow
```

---

# 26. Non-Project Mode

Vivado can also run without creating a traditional project.

Conceptually:

```text
read_verilog
      │
      ▼
read_xdc
      │
      ▼
synth_design
      │
      ▼
place_design
      │
      ▼
route_design
```

This is commonly called:

```text
Non-Project Mode
```

It gives more direct control over the flow.

---

# 27. Project Mode vs Non-Project Mode

Simplified:

```text
Project Mode
│
├── Easier GUI workflow
├── Managed runs
└── Good for tutorials

Non-Project Mode
│
├── Script-oriented
├── Direct build control
└── Useful for automation / CI
```

Both are valid approaches.

---

# 28. Setting the Top Module

Vivado needs to know the top-level RTL module.

Example:

```tcl
set_property top top [current_fileset]
```

Here:

```text
top
```

is the module name.

For example:

```systemverilog
module top (
    input logic clk
);
```

---

# 29. Compile Order

After adding sources:

```tcl
update_compile_order -fileset sources_1
```

This allows Vivado to update source dependencies.

---

# 30. Save Project

In Project Mode, Vivado normally tracks project state automatically.

You can also use commands such as:

```tcl
save_project_as
```

when needed.

However, if the project is generated entirely from a script, the script itself should remain the main source of truth.

---

# 31. Running Synthesis

In Project Mode, synthesis can be launched with:

```tcl
launch_runs synth_1
```

Then wait for completion:

```tcl
wait_on_run synth_1
```

Conceptually:

```text
Launch Synthesis
      │
      ▼
Wait
      │
      ▼
Synthesis Complete
```

---

# 32. Check Synthesis Status

You can inspect run properties.

Example:

```tcl
get_property STATUS [get_runs synth_1]
```

This may report information about the synthesis run.

Automated scripts should stop when a required build stage fails.

---

# 33. Open Synthesized Run

After synthesis:

```tcl
open_run synth_1
```

Now reports can be generated from the synthesized design.

For example:

```tcl
report_utilization
```

---

# 34. Run Implementation

In Project Mode:

```tcl
launch_runs impl_1
```

To continue all the way to bitstream generation:

```tcl
launch_runs impl_1 -to_step write_bitstream
```

Then:

```tcl
wait_on_run impl_1
```

---

# 35. Implementation Flow

The implementation run includes stages such as:

```text
opt_design
      │
      ▼
place_design
      │
      ▼
route_design
      │
      ▼
write_bitstream
```

Vivado manages these stages in the standard implementation run.

---

# 36. Open Implemented Design

After implementation:

```tcl
open_run impl_1
```

This allows reports to be generated against the final routed design.

---

# 37. Generate Timing Report

Example:

```tcl
report_timing_summary \
    -file "$build_dir/timing_summary.txt"
```

This saves the timing report into the build directory.

---

# 38. Generate Utilization Report

Example:

```tcl
report_utilization \
    -file "$build_dir/utilization.txt"
```

Now the build creates a record of FPGA resource usage.

---

# 39. Generate DRC Report

Example:

```tcl
report_drc \
    -file "$build_dir/drc.txt"
```

This saves Design Rule Check results.

---

# 40. Create Reports Directory

A cleaner structure is:

```text
build/
│
├── project/
├── reports/
└── output/
```

Tcl:

```tcl
set report_dir "$build_dir/reports"
set output_dir "$build_dir/output"

file mkdir $report_dir
file mkdir $output_dir
```

---

# 41. Save Reports

Example:

```tcl
report_timing_summary \
    -file "$report_dir/timing_summary.txt"

report_utilization \
    -file "$report_dir/utilization.txt"

report_drc \
    -file "$report_dir/drc.txt"
```

This creates organized build artifacts.

---

# 42. Copy Bitstream to Output Directory

Vivado's managed project normally creates the bitstream inside a generated run directory.

For a release-friendly build, you may copy it into:

```text
build/output/
```

Example conceptually:

```tcl
set bit_file \
    "$build_dir/$project_name/$project_name.runs/impl_1/top.bit"
```

Then:

```tcl
file copy -force \
    $bit_file \
    "$output_dir/caesar_fpga.bit"
```

The exact path depends on the generated project name and top module.

---

# 43. Better: Query Vivado Objects

Hardcoding generated Vivado paths can be fragile.

Where possible, use Vivado commands and project variables to determine generated outputs.

A robust script should minimize assumptions about temporary directory structure.

---

# 44. Direct `write_bitstream`

In a non-project flow, you can explicitly write the output:

```tcl
write_bitstream \
    -force \
    "$output_dir/caesar_fpga.bit"
```

This gives direct control over the output location.

---

# 45. Generate Binary Output

If the target workflow needs a `.bin` file, the design can enable binary output.

Example:

```tcl
set_property \
    BITSTREAM.GENERAL.BIN_FILE \
    true \
    [current_design]
```

Then generate the bitstream.

Exact behavior depends on the FPGA family and configuration flow.

---

# 46. Basic Non-Project Build

A simplified non-project flow may look like:

```tcl
read_verilog -sv "$repo_dir/src/top.sv"
read_verilog -sv "$repo_dir/src/modules/counter.sv"

read_xdc "$repo_dir/constraints/board.xdc"

synth_design \
    -top top \
    -part $fpga_part

opt_design

place_design

route_design

report_timing_summary \
    -file "$report_dir/timing_summary.txt"

write_bitstream \
    -force \
    "$output_dir/caesar_fpga.bit"
```

This represents the main FPGA build pipeline in a very clear form.

---

# 47. `read_verilog -sv`

For SystemVerilog:

```tcl
read_verilog -sv file.sv
```

Example:

```tcl
read_verilog -sv "$repo_dir/src/top.sv"
```

This tells Vivado to parse the source as SystemVerilog.

---

# 48. `synth_design`

In Non-Project Mode:

```tcl
synth_design
```

runs synthesis directly.

Example:

```tcl
synth_design \
    -top top \
    -part $fpga_part
```

The two critical values are:

```text
Top Module

FPGA Part
```

---

# 49. `opt_design`

After synthesis:

```tcl
opt_design
```

performs design optimization.

Conceptually:

```text
Synthesized Netlist
      │
      ▼
Optimization
      │
      ▼
Optimized Design
```

---

# 50. `place_design`

Next:

```tcl
place_design
```

Vivado assigns logic to physical FPGA resources.

---

# 51. `route_design`

After placement:

```tcl
route_design
```

Vivado connects the placed resources using programmable routing.

---

# 52. Write Design Checkpoint

A useful automated build may save checkpoints.

After synthesis:

```tcl
write_checkpoint \
    -force \
    "$build_dir/post_synth.dcp"
```

After placement:

```tcl
write_checkpoint \
    -force \
    "$build_dir/post_place.dcp"
```

After routing:

```tcl
write_checkpoint \
    -force \
    "$build_dir/post_route.dcp"
```

---

# 53. Why Checkpoints Are Useful

Checkpoints allow developers to inspect specific build stages without rebuilding everything.

For example:

```text
post_synth.dcp
post_place.dcp
post_route.dcp
```

They are especially useful when investigating implementation or timing problems.

---

# 54. Check Timing Automatically

A build should not blindly produce firmware while ignoring timing failures.

A release script can inspect timing information and stop if the design fails its required checks.

Conceptually:

```text
Build
  │
  ▼
Timing Analysis
  │
  ├── PASS → Generate Release
  │
  └── FAIL → Stop Build
```

---

# 55. Why Build Failure Is Useful

A build script that fails when something is wrong is better than one that always produces a file.

For example:

```text
Wrong FPGA Part
Missing XDC
Synthesis Error
Implementation Failure
Timing Violation
```

should not silently become a release.

---

# 56. `puts`

Use:

```tcl
puts
```

to print useful build information.

Example:

```tcl
puts "======================================"
puts "CAESAR FPGA BUILD"
puts "======================================"
puts "Project: $project_name"
puts "Part:    $fpga_part"
puts "Build:   $build_dir"
```

This makes command-line build logs easier to understand.

---

# 57. Error Handling

Tcl supports:

```text
catch
```

for error handling.

Conceptually:

```tcl
if {[catch {
    synth_design ...
} result]} {

    puts "Synthesis failed"
    puts $result
    exit 1
}
```

For simple scripts, Vivado command failures may already stop the process.

More advanced build systems can add explicit checks.

---

# 58. Exit Codes

When using Vivado in automated environments, proper exit codes are important.

Conceptually:

```text
exit 0
→ Build successful

exit 1
→ Build failed
```

CI systems use these codes to determine whether a build passed.

---

# 59. Vivado Batch Mode

Vivado scripts can be executed without opening the full graphical interface.

A typical command is:

```text
vivado -mode batch -source scripts/build.tcl
```

This allows the entire project to be built from a terminal.

---

# 60. Why Batch Mode Is Important

Batch mode enables:

```text
Automated Builds

CI Pipelines

Remote Build Servers

Repeatable Releases

No Manual GUI Steps
```

This is extremely useful for open-source FPGA projects.

---

# 61. Example User Workflow

A user can clone the project:

```text
git clone ...
```

Then run:

```text
vivado -mode batch -source scripts/build.tcl
```

After the build:

```text
build/output/caesar_fpga.bit
```

is created.

That is a much cleaner experience than manually recreating the Vivado project.

---

# 62. Vivado Version Matters

FPGA builds can behave differently between Vivado versions.

Therefore document the expected version.

Example:

```text
Tested with:

AMD Vivado 2026.1
```

A build script can also print the Vivado version.

Example:

```tcl
puts "Vivado Version: [version -short]"
```

---

# 63. Version Check

For tightly controlled projects, a script can optionally check the Vivado version.

Conceptually:

```text
Required:
2026.1

Detected:
2026.1

→ Continue
```

or:

```text
Detected:
Different Version

→ Print Warning
```

Strict version checks can improve reproducibility.

---

# 64. Avoid Absolute Paths

Bad:

```tcl
add_files "C:/Users/Developer/Desktop/project/src/top.sv"
```

This only works on one computer.

Better:

```tcl
add_files "$repo_dir/src/top.sv"
```

Relative project paths make the repository portable.

---

# 65. Avoid User-Specific Directories

Do not depend on:

```text
Desktop

Downloads

Personal user folders
```

A repository should be buildable from any reasonable location.

For example:

```text
C:/FPGA/caesar-fpga
```

or:

```text
D:/Projects/caesar-fpga
```

should both work.

---

# 66. Avoid Manually Editing Generated Files

Generated Vivado project files should generally not become the source of truth.

Instead, edit:

```text
src/

constraints/

scripts/
```

and regenerate the build.

This reduces hidden project state.

---

# 67. IP Cores

FPGA projects often contain generated IP.

Examples:

```text
PCIe IP

Clocking Wizard

ILA

FIFO Generator
```

IP creates additional considerations for reproducible builds.

---

# 68. IP Configuration Files

Vivado IP commonly uses files such as:

```text
.xci
```

These contain IP configuration information.

For a reproducible source project, the necessary IP configuration should normally be version controlled.

---

# 69. Regenerate IP

A scripted workflow can load IP configuration and regenerate output products.

Conceptually:

```text
.xci
 │
 ▼
Vivado
 │
 ▼
Generate IP
 │
 ▼
Synthesis / Implementation
```

This avoids relying only on previously generated IP outputs.

---

# 70. PCIe IP Automation

A future PCIe project might include:

```text
ip/
└── pcie_core/
```

The build script would then:

```text
Load PCIe IP

Generate Output Products

Add RTL Wrapper

Add Constraints

Run Build
```

The exact commands depend on FPGA family and selected PCIe IP.

---

# 71. Do Not Hardcode Unknown PCIe Settings

PCIe settings depend on:

```text
FPGA Family

PCIe Generation

Lane Width

Board Routing

Reference Clock

Target Device
```

Therefore a generic tutorial should not copy an arbitrary PCIe IP configuration and assume it is valid for every board.

---

# 72. Board-Specific Build Variables

A larger project may support multiple FPGA boards.

Example:

```text
boards/
│
├── board_a/
│   └── board.xdc
│
└── board_b/
    └── board.xdc
```

The script could select:

```text
FPGA Part

XDC File

Board Name
```

based on a build target.

---

# 73. Multiple Build Targets

Conceptually:

```text
Build Target:
board_a
    │
    ├── Part A
    └── board_a.xdc

Build Target:
board_b
    │
    ├── Part B
    └── board_b.xdc
```

This allows one HDL codebase to support multiple compatible boards.

---

# 74. Build Arguments

More advanced Tcl scripts can accept command-line arguments.

For example:

```text
vivado -mode batch \
       -source scripts/build.tcl \
       -tclargs board_a
```

Inside Tcl:

```tcl
set board [lindex $argv 0]
```

This can select different targets.

---

# 75. Debug vs Release Target

A script could also support:

```text
debug
```

and:

```text
release
```

builds.

For example:

```text
Debug
→ ILA enabled

Release
→ Debug instrumentation disabled
```

This makes hardware debugging easier without permanently increasing resource usage.

---

# 76. Clean Build

A clean build starts from generated files being absent.

Conceptually:

```text
Delete build/
      │
      ▼
Run build.tcl
      │
      ▼
Recreate Everything
```

If this succeeds, the project is much more reproducible.

---

# 77. Why Clean Builds Matter

An incremental Vivado project can accidentally depend on old generated files.

A clean build helps detect:

```text
Missing Source Files

Missing Constraints

Missing IP Configuration

Hidden Project Settings

Incorrect Dependencies
```

---

# 78. Add `build/` to `.gitignore`

Since:

```text
build/
```

contains generated files, it is usually excluded from Git.

For example:

```gitignore
# Generated build directory
build/
```

Stable release firmware can be published separately.

We will update the repository cleanup together at the end of the tutorial.

---

# 79. Build Script as Documentation

A good:

```text
build.tcl
```

file is also documentation.

It tells another developer:

```text
Which FPGA is targeted

Which RTL files are used

Which XDC is loaded

Which top module is used

How synthesis runs

How implementation runs

How the bitstream is generated
```

This greatly improves project credibility.

---

# 80. Example Complete Build Script

Below is a simplified educational example.

```tcl
# ============================================================
# CAESAR FPGA Build Script
# ============================================================

set script_dir [file dirname [file normalize [info script]]]
set repo_dir   [file normalize "$script_dir/.."]

set build_dir  "$repo_dir/build"
set report_dir "$build_dir/reports"
set output_dir "$build_dir/output"

set project_name "caesar_fpga"

# Example only.
# Replace this with the exact FPGA used by your board.
set fpga_part "xc7a35tcpg236-1"

puts "======================================"
puts "CAESAR FPGA BUILD"
puts "======================================"

puts "Repository : $repo_dir"
puts "Build      : $build_dir"
puts "FPGA       : $fpga_part"
puts "Vivado     : [version -short]"

file mkdir $build_dir
file mkdir $report_dir
file mkdir $output_dir

# ------------------------------------------------------------
# Read RTL
# ------------------------------------------------------------

read_verilog -sv "$repo_dir/src/top.sv"
read_verilog -sv "$repo_dir/src/modules/counter.sv"

# ------------------------------------------------------------
# Read Constraints
# ------------------------------------------------------------

read_xdc "$repo_dir/constraints/board.xdc"

# ------------------------------------------------------------
# Synthesis
# ------------------------------------------------------------

puts "Running synthesis..."

synth_design \
    -top top \
    -part $fpga_part

write_checkpoint \
    -force \
    "$build_dir/post_synth.dcp"

report_utilization \
    -file "$report_dir/post_synth_utilization.txt"

# ------------------------------------------------------------
# Optimization
# ------------------------------------------------------------

puts "Running optimization..."

opt_design

# ------------------------------------------------------------
# Placement
# ------------------------------------------------------------

puts "Running placement..."

place_design

write_checkpoint \
    -force \
    "$build_dir/post_place.dcp"

# ------------------------------------------------------------
# Routing
# ------------------------------------------------------------

puts "Running routing..."

route_design

write_checkpoint \
    -force \
    "$build_dir/post_route.dcp"

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------

puts "Generating reports..."

report_timing_summary \
    -file "$report_dir/timing_summary.txt"

report_utilization \
    -file "$report_dir/utilization.txt"

report_drc \
    -file "$report_dir/drc.txt"

# ------------------------------------------------------------
# Bitstream
# ------------------------------------------------------------

puts "Generating bitstream..."

write_bitstream \
    -force \
    "$output_dir/caesar_fpga.bit"

puts "======================================"
puts "BUILD COMPLETE"
puts "======================================"

puts "Bitstream:"
puts "$output_dir/caesar_fpga.bit"
```

---

# 81. Important Warning About the Example

The line:

```tcl
set fpga_part "xc7a35tcpg236-1"
```

is only an example.

Before using the script on real hardware, replace it with the exact FPGA part used by the target board.

Likewise:

```text
constraints/board.xdc
```

must contain verified board-specific constraints.

---

# 82. Build from Command Line

Once the script exists, the project can be built with:

```text
vivado -mode batch -source scripts/build.tcl
```

Conceptually:

```text
Terminal
   │
   ▼
Vivado Batch Mode
   │
   ▼
build.tcl
   │
   ▼
RTL + XDC
   │
   ▼
Synthesis
   │
   ▼
Implementation
   │
   ▼
Reports
   │
   ▼
Bitstream
```

---

# 83. Build Output

After a successful scripted build:

```text
build/
│
├── post_synth.dcp
├── post_place.dcp
├── post_route.dcp
│
├── reports/
│   ├── post_synth_utilization.txt
│   ├── timing_summary.txt
│   ├── utilization.txt
│   └── drc.txt
│
└── output/
    └── caesar_fpga.bit
```

This gives a clean, organized output structure.

---

# 84. Rebuild from Scratch

To test reproducibility:

```text
Delete build/
```

Then run:

```text
vivado -mode batch -source scripts/build.tcl
```

If the firmware rebuilds successfully, the repository contains the important build inputs.

---

# 85. CI Concept

Once a project can build from a single command, it can later be integrated into:

```text
Continuous Integration
```

Conceptually:

```text
Git Commit
     │
     ▼
Build Server
     │
     ▼
Vivado
     │
     ▼
Synthesis
     │
     ▼
Implementation
     │
     ▼
Timing Check
     │
     ▼
Firmware Artifact
```

---

# 86. GitHub Workflow Concept

A future project could use automation to validate source changes.

For example:

```text
Push Code
    │
    ▼
Automated FPGA Build
    │
    ▼
Check Build Result
    │
    ▼
PASS / FAIL
```

Vivado licensing, installation and runner environment must be planned separately.

---

# 87. Release Automation

A mature build system could eventually generate:

```text
Firmware Bitstream

Timing Report

Utilization Report

Build Information

Release Archive
```

from one command.

This reduces manual mistakes during releases.

---

# 88. Build Version

A script can define:

```tcl
set firmware_version "1.0.0"
```

Then output:

```text
caesar_fpga-v1.0.0.bit
```

Example:

```tcl
write_bitstream \
    -force \
    "$output_dir/caesar_fpga-v${firmware_version}.bit"
```

---

# 89. Build Metadata File

The script can also create:

```text
build_info.txt
```

Example:

```tcl
set info_file [open "$output_dir/build_info.txt" "w"]

puts $info_file "Project: $project_name"
puts $info_file "FPGA: $fpga_part"
puts $info_file "Vivado: [version -short]"

close $info_file
```

This records useful release information.

---

# 90. Git Commit Information

Advanced builds can also record the source commit used for the build.

Conceptually:

```text
Firmware Version

Git Commit

Vivado Version

FPGA Device

Build Date
```

This makes a firmware artifact traceable back to its exact source.

---

# 91. Do Not Store Secrets in Build Scripts

Public Git repositories should not contain:

```text
Passwords

API Keys

Private Server Credentials

Signing Secrets

Private License Information
```

Build scripts should remain safe to publish.

---

# 92. Keep Hardware Configuration Explicit

A good build system should make important hardware assumptions obvious.

For example:

```tcl
set fpga_part ...
set board_xdc ...
set top_module ...
```

Hidden configuration makes FPGA projects difficult to reproduce.

---

# 93. Common Tcl Build Mistakes

Common mistakes include:

```text
Absolute paths

Wrong FPGA part

Missing XDC

Wrong top module

Depending on old generated files

Ignoring command failures

Ignoring timing reports

Committing the entire build directory

Using different Vivado versions without documenting them
```

---

# 94. Recommended Build Philosophy

A clean FPGA repository should aim for:

```text
Clone
  │
  ▼
Run One Command
  │
  ▼
Vivado Builds Project
  │
  ▼
Reports Generated
  │
  ▼
Bitstream Generated
```

The fewer hidden manual steps, the easier the project is to maintain.

---

# 95. Why This Matters for Open Source

For an open-source FPGA project, providing only RTL files may not be enough.

A strong project includes:

```text
Source Code

Constraints

IP Configuration

Build Script

Vivado Version

Hardware Documentation

Build Instructions
```

This allows others to actually reproduce and study the project.

---

# 96. Project Structure After Automation

A mature repository may look like:

```text
caesar-fpga/
│
├── src/
│   ├── top.sv
│   ├── modules/
│   ├── pcie/
│   └── utils/
│
├── constraints/
│   └── board.xdc
│
├── scripts/
│   └── build.tcl
│
├── ip/
│
├── docs/
│
├── images/
│
├── README.md
├── LICENSE
└── .gitignore
```

Generated files remain outside the source tree or inside ignored build directories.

---

# 97. What We Learned

In this chapter, we learned:

```text
Vivado Automation
       │
       ├── Tcl
       ├── Tcl Console
       ├── Project Creation
       ├── RTL Loading
       ├── XDC Loading
       ├── Synthesis
       ├── Implementation
       ├── Checkpoints
       ├── Timing Reports
       ├── Utilization Reports
       ├── Bitstream Generation
       ├── Batch Mode
       └── Reproducible Builds
```

A scripted build turns an FPGA project from a collection of manually configured files into a reproducible engineering project.

---

# Next Chapter

Continue to:

**[Chapter 16 — Simulation and Testbenches](16-simulation-testbench.md)**

In the next chapter, we will learn how to verify FPGA logic before programming real hardware.

We will cover:

```text
Simulation
Testbenches
Clock Generation
Reset Generation
Stimulus
Assertions
Waveforms
Register Testing
BAR Logic Testing
Self-Checking Testbenches
Debugging RTL Before Hardware
```

---

<div align="center">

### CAESAR

**FPGA · PCIe · Firmware · Hardware Engineering**

[Website](https://caesardma.store/) • [Discord](https://discord.gg/uqwZJg2RQ)

</div>
