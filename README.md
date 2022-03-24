# Bits - Ruby
This is a personal project to simulate a rudimentary 8-bit computer in software, using Combinatorial logic gates and latches.
The implemented computer is a modification of the "Simple as possible 2" (SAP-2), described in *Digital Computer Electronics 3rd Edition*.

Diagram of Project Components |  Diagram of Computer Architecture
------------------------------|-----------------------------------
![Diagram of Project Architecture](/images/software_arch.png?raw=true "Project Architecture")|![Diagram of Computer Architecture](/images/sap2_arch.png?raw=true "SAP-2-like Computer Architecture")

## Getting started:
* Download this project to a local directory
* Download and install a recent version ruby, if not already installed.
* Run *"test_components.rb"* to complete the test suite
* Enter the "sap2" subdirectory and run *"run.rb test --debug"* and/or *"run.rb fib --debug"*. Press 'enter' repeatedly to watch the computer in operation.
* Refer to *test.src* to understand what code is being executed.
* Make changes to *test.src*, run *"compile.rb test"*, and then run *"run.rb test --debug"* again to see your new program in action.
* To add a new instruction, modify *"write_language.rb"* as-needed, run it to produce a new *language.yaml*, then run *"write_microcode.rb"* to produce a new *sap2.rom* that contains your new instruction.

## References:
- *Digital Computer Electronics 3rd Edition - Malvino and Brown*
- [beneater.net](https://eater.net/8bit)

## Background:
- Ever since taking an electrical engineering course in college, the experience of understanding and building a breadboard computer 
out of gates and latches has stuck with me, as it has for many other people:  

[![YouTube - Michael Roberts - Minecraft - Programmable 8-bit computer](/images/youtube_ydd6l3iYOZE.png?raw=true)](https://www.youtube.com/watch?v=ydd6l3iYOZE)  
  [YouTube - James Bates - Ben Eater inspired 8-bit breadboard cpu](https://www.youtube.com/playlist?list=PL_i7PfWMNYobSPpg1_voiDe6qBcjvuVui)  
  [YouTube - DerULF1 - 8-bit breadboard CPU](https://www.youtube.com/playlist?list=PL5-Ar_CvItgaP27eT_C7MnCiubkyaEqF0)  
  [YouTube - Minecraft - Programmable 8-bit computer](https://youtu.be/ydd6l3iYOZE)  
  [Github - EnigmaCurry/SAP](https://github.com/EnigmaCurry/SAP)  
- This project is an attempt to build a simple 8-bit computer, but by simulating the execution in code, instead of on a breadboard.

## Goals:
- "Simulate" a computer in software using only a small set of "Physical" gates.
- Get to the point of being able to observe a complete "program" execute.
- Have a basic compiler to convert an assembly language into the machine binary.
- Have a test suite to exercise the individal components.

## Design Notes:
- Written in Ruby 2.6.6.  No other dependencies.
- Components represent physical components that each have a single output and one or more inputs.  
- This includes basic "And", "Or", etc gates, as well as DataLatch components.
- The computer state is stored in DataLatch components.  The entire simulation is updated during clock ticks via the *update* methods.
- Each DataLatch pulls its new value via its single input, calling .output on the component it points to.
- This starts a chain of .output calls until a stable value is reached (either a previous DataLatch value or a constant True or False component)
- DataLatches are updated in a two-phase approach so that some outputs don't start changing mid-clock pulse and affecting other DataLatches.
- All other higher-level components are made up of combinations of these low-level components, with build_* factory functions used to help set them up.

## Differences from SAP-2
- In SAP-2 certain components (Bus, PC, MAR) were labeled as 16-bit in a diagram.  I didn't find a use for these extra bits so these components remain 8-bit.
- The RAM was described as 64K, with the first 2K pre-loaded with a "Monitor" program, which is a simple operating system.  However the code for the monitor wasn't provided.
- The microcode for SAP-2 was also not provided, so the microcode was completely generated from scratch.
- The fetch cycle was three states (Address, Increment, Memory).  Incrementing the PC was combined with the memory step to save a state.
- A number of inputs and outputs were described, including handing serial data.  These were not implemented in favor of a single OUT register that displays values sent there to STDOUT.
- The ROM and RAM data are being loaded directly as the components are built and not loaded within the simulation.
- The implementation of the jump instructions wasn't described in detail.  My solution was to watch for the JNE opcode in the IR and have the micro-counter jump away based on the zero flag.
- 7 instructions are not implemented (IN, JM, JZ, RAL, RAR, CALL, RET) and some additional instructions were added (LDB,STB,LDC,STC) at unused addresses.

## Outcome:
- The goals of the project are met.  An SAP-2-like computer can be simulated to run a simple program to generate an 8-bit Fibonacci sequence.
