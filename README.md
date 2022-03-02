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
[beneater.net](https://eater.net/8bit)
Digital Computer Electronics 3rd Edition - Malvino and Brown

Background:
Ever since taking an electrical engineering course in college, the experience of understanding and building a breadboard computer 
out of gates and latches has stuck with me, as it has for many other people:  [YouTube - Minecraft - Programmable 8-bit computer](https://youtu.be/ydd6l3iYOZE)
This project is an attempt to build a simple 8-bit computer, but by simulating the behavior in code instead of on a breadboard.
Not only is it a fun project, I find that it's an interesting project to explore different ways to structure the code.

Goals:
* "Simulate" a computer in software using only a small set of "Physical" gates.
* All other gates are made up of combinations of those.
* Get to the point of being able to see a complete "program" execute.
* Have a test suite to exercise the individal components.

Design Notes:
* Written in Ruby.  No other dependencies.
* Physical components and inputs represent the same physical chips you'd use on a breadboard.  They "just work", in this case via their "update" methods.
* Physical components are still abstract.  They have no notion of being wired to power or to a clock or to non-binary voltages, they just work.
* Logical components are everything else.  They are logical groupings of physical and/or other logical sub-components.
* Physical outputs store their own state.  While not necessary, this approach allows me to display intermediate values without re-doing work.
* Inputs don't store state, they just point to an output.

Outcome:
* The goals of the project are met.
* I'd like to take it a little bit further to get a more complete instruction set and a more non-trivial program.
* Performance is poor, but unfortunately the ruby profilers don't play well with Windows so my plan is to explore further on.
* This design is just one approach, I'd like to explore other approaches and have higher-level ways to specify logical components.  For example a way to hook up a range of inputs/outputs at once.

