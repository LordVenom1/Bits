# Bits - 8-bit Computer Simulation
This is a project to simulate a 8-bit computer in software, built up from Combinatorial logic gates and latches implemented in native code.
The design is a modification of the "Simple as possible 2" (SAP-2), described in *Digital Computer Electronics 3rd Edition*.

Example of the computer generating the 8-bit Fibonacci sequence:  
![Computer simulating Fibonacci](/images/sap2fib.gif?raw=true "Computer Operation")  

## Getting started:
* Download this project to a local directory: *git clone https://github.com/LordVenom1/Bits.git*
* Download and install a recent version ruby, if not already installed.
* Run *"test_components.rb"* to complete the test suite
* Enter the "sap2" subdirectory and run *"run.rb test --debug"* and/or *"run.rb fib --debug"*.
* Refer to *test.src* or *fib.src* to understand what code is being executed.
* If you make changes to *test.src*: run *"compile.rb test"*, and then run *"run.rb test --debug"* again to see your new program in action.
* To add a new instruction, modify *"write_language.rb"* as-needed, run it to produce a new *language.yaml*, then run *"write_microcode.rb"* to produce a new *sap2.rom* that includes your new instruction.

Diagram of Project Components |  Diagram of Computer Architecture 
------------------------------|-----------------------------------
![Diagram of Project Architecture](/images/software_arch.png?raw=true "Project Architecture")|![Diagram of Computer Architecture](/images/sap2_arch.png?raw=true "SAP-2-like Computer Architecture")  

## References:
- *Digital Computer Electronics 3rd Edition - Malvino and Brown*
- [beneater.net](https://eater.net/8bit)

## Background:
- Since taking an electrical engineering course in college, the experience of building a breadboard computer out of gates and latches has stuck with me, as it has for many other people:
  YouTube - Minecraft - Programmable 8-bit computer:  
  [![YouTube - Michael Roberts - Minecraft - Programmable 8-bit computer](/images/youtube_ydd6l3iYOZE.png?raw=true)](https://www.youtube.com/watch?v=ydd6l3iYOZE)  
  [YouTube - James Bates - Ben Eater inspired 8-bit breadboard cpu](https://www.youtube.com/playlist?list=PL_i7PfWMNYobSPpg1_voiDe6qBcjvuVui)  
  [YouTube - DerULF1 - 8-bit breadboard CPU](https://www.youtube.com/playlist?list=PL5-Ar_CvItgaP27eT_C7MnCiubkyaEqF0)      
  [Github - EnigmaCurry/SAP](https://github.com/EnigmaCurry/SAP)  
- While building a physical breadboard computer is an added challenge, simulating one in software is still a rewarding project, and is still very much analogous to the way 1980's-era computers operated.  Electrical engineering considerations are replaced with that of software design.

## Goals:
- "Simulate" a computer in software using only a small set of "physical" gates.  These gates are implemented in native code, outside the simulation.
- Get to the point of being able to observe a complete "program" execute.
- Have a basic compiler to convert an assembly language into the machine binary.
- Have a test suite to exercise the components.

## Design Notes:
- Written in Ruby 2.6.6.  No other dependencies.
- Components represent physical components that each have a single output and one or more inputs.  
- This includes basic "And", "Or", etc gates, as well as DataLatch components.
- The computers state is stored in the DataLatch components.  The entire simulation is updated during clock pulses, via the *update* methods.
- Each DataLatch pulls its new value via its single input, calling .output on the component it points to.
- This starts a chain of .output calls until a stable value is reached (either a previous DataLatch value or a constant True or False component)
- DataLatches are updated in a two-phase approach so that some outputs don't start changing mid-clock pulse and affecting other DataLatches prematurely.
- All other higher-level components are made up of combinations of these low-level components, with build_* factory functions used to help set them up.
- All intermediate "binary" files are not stored in actual binary, but as text 1's and 0's for ease of understanding and modification.

## Differences from SAP-2
- In SAP-2, certain components (Bus, PC, MAR) were labeled as 16-bit in a diagram in order to address the 64k RAM.  I didn't need such a large memory, so these components remain 8-bit.
- The RAM was described as 64K, with the first 2K pre-loaded with a "Monitor" program, which is a simple operating system.  However, the code for the monitor wasn't provided, so programs for our machine just fill the entire 2k RAM and start at address 0.
- The microcode for SAP-2 was also not provided, so the microcode was completely generated from scratch.
- The fetch cycle was three states (Address, Increment, Memory).  Incrementing the PC was combined with the memory step to save a state.
- A number of inputs and outputs were described, including handing serial data.  These were not implemented in favor of a single OUT register that displays values sent there to STDOUT.
- The ROM and RAM data are being loaded directly as the components are built, and not loaded within the simulation.
- The implementation of the jump instructions wasn't described in detail.  My solution was to watch for the JNE opcode in the IR and have the microcode counter jump away based on the zero flag.
- 7 instructions are not implemented (IN, JM, JZ, RAL, RAR, CALL, RET) and some additional instructions were added (LDB,STB,LDC,STC) at unused addresses.

## Outcome:
- The goals of the project are met.  The "SAP-2"-like computer simulation is working and can generate the 8-bit Fibonacci sequence to completion.
