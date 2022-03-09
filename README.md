# Bits - Ruby

This is a fun project to simulate a basic 8-bit computer in software, at the level of basic Combinatorial logic gates and latches.

To explore:
* Download this project to a local directory
* Download and install a recent version ruby
* Run "test_components.rb" to complete the test suite
* Run "comp.rb prog1"
* Make changes to prog1.src, run "compile.rb prog1", and then run comp.rb prog1 to watch your changes.
* To add a new instruction, modify "util/write_microcode_1024.rb" as needed, run it, and copy the new computer1a.rom and computer1b.rom down to the main folder.

References:
* [beneater.net](https://eater.net/8bit)
* Digital Computer Electronics 3rd Edition - Malvino and Brown

Background:
Ever since taking an electrical engineering course in college, the experience of understanding and building a breadboard computer 
out of gates and latches has stuck with me, as it has for many other people:  [YouTube - Minecraft - Programmable 8-bit computer](https://youtu.be/ydd6l3iYOZE)
This project is an attempt to build a simple 8-bit computer, but by simulating the processing in code, instead of on a breadboard.
Not only is it a fun project, I find that it's an interesting project to explore different ways to structure the simulation.

Goals:
* "Simulate" a computer in software using only a small set of "Physical" gates.
* All other gates are made up of combinations of those.
* Get to the point of being able to see a complete "program" execute.
* Have a test suite to exercise the individal components.

Design Notes:
* Written in Ruby.  No other dependencies.
* Components represent physical components that have a single output and one or more inputs.  
* This includes basic "And", "Or", etc gates, as well as DataLatch components.
* The only state is stored in DataLatch components.  The entire simulation is updated during clock ticks.  
* Each DataLatch pulls their new value via their single input, calling .output on the component it points to.
* This starts a chain of .output calls until a stable value is reached (either a previous DataLatch value or a constant True or False gate)
* All other higher-level components are made up of combinations of these low-level components via a factory build_ function.  
* A "ComponentGroup" object is returned, which is a set of aliases of inputs and outputs, and helper functions to set the underlying components.

Outcome:
* The goals of the project are met.
* I'd like to take it a little bit further to get a more complete instruction set and a more non-trivial program.
* I'd also like to display the output more clearly to more clearly illustrate what's happening.
* This design is just one approach, I'd like to explore other approaches and have higher-level ways to specify logical components.  For example a way to hook up a range of inputs/outputs at once.

