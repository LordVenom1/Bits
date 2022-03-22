# Bits - Ruby
This is a personal project to simulate a simple 8-bit computer in software, at the level of basic Combinatorial logic gates and latches.
The implemented computer resembles the "Simple as possible 2" (SAP-2), described in *Digital Computer Electronics 3rd Edition*.

## Getting started:
* Download this project to a local directory
* Download and install a recent version ruby
* Run *"test_components.rb"* to complete the test suite
* Enter the "sap2" subdirectory and run *"compsap2.rb fib --debug"*. Press 'enter' repeatedly to watch the computer in operation.
* Refer to *fib.src* to understand what code is being executed.
* Make changes to *fib.src*, run *"compile.rb fib"*, and then run *"compsap2.rb fib --debug"* again to see your new program in action.
* To add a new instruction, modify "write_microcode_sap2.rb" as-needed, then run it to update the ROM file.
	
## References:
- *Digital Computer Electronics 3rd Edition - Malvino and Brown*
- [beneater.net](https://eater.net/8bit)

## Background:
- Ever since taking an electrical engineering course in college, the experience of understanding and building a breadboard computer 
out of gates and latches has stuck with me, as it has for many other people:  
- [YouTube - James Bates - Ben Eater inspired 8-bit breadboard cpu](https://www.youtube.com/playlist?list=PL_i7PfWMNYobSPpg1_voiDe6qBcjvuVui)
- [YouTube - DerULF1 - 8-bit breadboard CPU](https://www.youtube.com/playlist?list=PL5-Ar_CvItgaP27eT_C7MnCiubkyaEqF0)
- [YouTube - Minecraft - Programmable 8-bit computer](https://youtu.be/ydd6l3iYOZE)
- [Github - EnigmaCurry/SAP](https://github.com/EnigmaCurry/SAP)
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

## Outcome:
- The goals of the project are met.
- The SAP2 computer is not fully implemented, but enough that we're able to compile and execute a simple program to generate the 8-bit Fibonacci sequence.


