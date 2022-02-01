require "test/unit"
require './components.rb'

# expose input and outputs for direct access
# class Component
	# attr_reader :inputs, :outputs
# end

# DEBUG = false
DEBUG = true

class TestSimple < Test::Unit::TestCase

	def help_test_case(sim, component, i, o)
			puts "start scenario - input: " + i.join(",") if DEBUG
			component.set_input_values(i)
			sim.check()
			sim.update	
			puts component.dump	if DEBUG and component.class.to_s.start_with?("ram")		
			puts component.to_s if DEBUG
			assert_equal(o, component.get_outputs().collect do |val| val ? 1 : 0 end, "input: " + i.join(","))
	end

	def help_test_logic_table(sim, component, cases)
		
		cases.each do |i,o|
			help_test_case(sim,component,i,o)
		end
	
	end
	
	def test_or		
		s = Simulation.new
		c = OrGate.new(s)		
		help_test_logic_table(s,c,
		{
			#[0,0] => [0],
			[1,0] => [1],
			[0,1] => [1],
			[1,1] => [1]
		})
		
	end
	
	def test_and
		s = Simulation.new	
		c = AndGate.new(s)
		help_test_logic_table(s,c,
			{
				[0,0] => [0],
				[1,0] => [0],
				[0,1] => [0],
				[1,1] => [1]
			}
		)
	end
	
	def test_xor		
		s = Simulation.new	
		c = XorGate.new(s)
		help_test_logic_table(s,c,
			{
				[0,0] => [0],
				[1,0] => [1],
				[0,1] => [1],
				[1,1] => [0]
			}
		)
	end
	
	def test_nand	
		s = Simulation.new	
		c = NandGate.new(s)
		help_test_logic_table(s,c,
			{
				[0,0] => [1],
				[1,0] => [1],
				[0,1] => [1],
				[1,1] => [0]
			}
		)
	end
	
	def test_not
		s = Simulation.new	
		c = NotGate.new(s)
		help_test_logic_table(s,c,
			{
				[1] => [0],
				[0] => [1]
							
			}
		)		
	end
	
	def test_register
		s = Simulation.new
		c = Register.new(s)
		
		c.set_input_values([1,0])
		s.update
		# puts c.to_s
		assert_equal(false, c.get_output(0), "input doesn't do anything until load is set")
		
		c.set_input_values([1,1])
		s.update
		# puts c.to_s
		assert_equal(true, c.get_output(0), "load reg, out should reflect it")
		
		c.set_input_values([0,0])
		s.update		
		assert_equal(true, c.get_output(0), "output sticks even when input changes")
	end
	
	def test_register8
		s = Simulation.new
		c = Register8.new(s)
				
		c.set_input_values([1,1,1,1,1,1,1,1,0])
		s.update		
		assert_equal([0,0,0,0,0,0,0,0], c.get_outputs().collect do |val| val ? 1 : 0 end, "input doens't matter until input is set")
		
		c.set_input_values([1,1,1,1,1,1,1,1,1])
		s.update
		assert_equal([1,1,1,1,1,1,1,1], c.get_outputs().collect do |val| val ? 1 : 0 end, "now output is showing input")
				
		c.set_input_values([0,1,1,1,0,0,0,1,0])
		s.update	
		assert_equal([1,1,1,1,1,1,1,1], c.get_outputs().collect do |val| val ? 1 : 0 end, "output is still showing old output in spite of input changing")

		c.set_input_values([1,1,1,1,0,0,0,1,1])
		s.update	
		assert_equal([1,1,1,1,0,0,0,1], c.get_outputs().collect do |val| val ? 1 : 0 end, "output is still showing old output in spite of input changing")
				
	end
	
	def test_datareg
		s = Simulation.new
		c = DataLatch.new(s)
		c.inputs[0].set_source(s.true_signal.outputs[0])		
		s.update
		assert_equal(true, c.get_output(0))		
	end
	
	def test_buffer
		s = Simulation.new
		c = BufferGate.new(s)
		help_test_logic_table(s,c,
			{
				[1] => [1],
				[0] => [0]			
			}
		)
	end
	
	def test_datareg_not
		s = Simulation.new
		c = DataLatch.new(s)		
		
		n = NotGate.new(s)
		n.inputs[0].set_source(c.outputs[0])
		c.inputs[0].set_source(n.outputs[0])
		
		s.update
		assert_equal(true, c.get_output(0))
		s.update
		assert_equal(false, c.get_output(0))
		s.update
		assert_equal(true, c.get_output(0))
		s.update
		assert_equal(false, c.get_output(0))		
				
	end
	
	def test_halfadder
		s = Simulation.new
		c = HalfAdder.new(s)
		
		help_test_logic_table(s,c,
		{
			[0,0] => [0,0],
			[0,1] => [1,0],
			[1,0] => [1,0],
			[1,1] => [0,1]
		})
	end
	
	def test_fulladder
		s = Simulation.new
		c = FullAdder.new(s)
		
		help_test_logic_table(s,c,
		{
			[0,0,0] => [0,0],
			[0,0,1] => [1,0],
			[0,1,0] => [1,0],
			[0,1,1] => [0,1],
			[1,0,0] => [1,0],
			[1,0,1] => [0,1],
			[1,1,0] => [0,1],
			[1,1,1] => [1,1]			
		})
	end
	
	def test_fulladder8
		s = Simulation.new()
		c = FullAdder8.new(s)
		
		help_test_logic_table(s,c,
		{
			#                                  CI
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0] => [0,0,0,0,0,0,0,0,  0],
			[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,  0] => [0,0,0,0,0,0,0,1,  0],
			[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,  0] => [0,0,0,0,0,0,1,0,  0],
			[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0] => [1,0,0,0,0,0,0,0,  0],
			[1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,  0] => [0,0,0,0,0,0,0,0,  1],
			[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  0] => [1,1,1,1,1,1,1,0,  1],
			[0,0,0,0,1,1,0,0,0,0,0,0,1,0,0,1,  0] => [0,0,0,1,0,1,0,1,  0],			
			[1,1,0,0,0,1,0,1,1,0,0,1,1,1,1,0,  0] => [0,1,1,0,0,0,1,1,  1],
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  1] => [0,0,0,0,0,0,0,1,  0],
			[1,1,0,0,0,1,0,1,1,0,0,1,1,1,1,0,  1] => [0,1,1,0,0,1,0,0,  1]			
		})
	end
	
	def test_fulladdersub8
		s = Simulation.new
		c = FullAdderSub8.new(s)

		help_test_logic_table(s,c,
		{
			#                                  CI
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0] => [0,0,0,0,0,0,0,0,  0],
			[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,  0] => [0,0,0,0,0,0,0,1,  0],
			[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,  0] => [0,0,0,0,0,0,1,0,  0],
			[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0] => [1,0,0,0,0,0,0,0,  0],
			[1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,  0] => [0,0,0,0,0,0,0,0,  1],
			[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  0] => [1,1,1,1,1,1,1,0,  1],
			[0,0,0,0,1,1,0,0,0,0,0,0,1,0,0,1,  0] => [0,0,0,1,0,1,0,1,  0],			
			[1,1,0,0,0,1,0,1,1,0,0,1,1,1,1,0,  0] => [0,1,1,0,0,0,1,1,  1]			
		})
			
		help_test_logic_table(s,c,
		{                   #
			[0,0,0,1,1,0,0,0,0,0,0,0,1,0,0,0,1] => [0,0,0,1,0,0,0,0,1], # not sure what carry means yet
			[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1] => [0,0,0,0,0,0,0,0,1],			
			[1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1] => [0,0,0,0,0,0,0,0,1],			
			[1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1] => [1,1,1,1,1,1,1,1,0]		
			
		})
	end	
	
	def test_and4
		s = Simulation.new	
		c = And4Gate.new(s)
		
		help_test_logic_table(s,c,
			{
				[0,0,0,0] => [0],
				[1,0,0,0] => [0],
				[0,1,0,0] => [0],
				[1,1,0,0] => [0],
				[0,0,0,1] => [0],
				[1,0,0,1] => [0],
				[0,1,0,1] => [0],
				[1,1,0,1] => [0],
				[0,0,1,0] => [0],
				[1,0,1,0] => [0],
				[0,1,1,0] => [0],
				[1,1,1,0] => [0],
				[0,0,1,1] => [0],
				[1,0,1,1] => [0],
				[0,1,1,1] => [0],
				[1,1,1,1] => [1],				
			}
		)
	end
	
	def test_mux2
		s = Simulation.new
		c = Multiplexer2.new(s)
		
		help_test_logic_table(s,c,
			{
				[0,0,0] => [0],
				[1,0,0] => [0],
				[0,1,0] => [1],
				[1,1,0] => [1],
				[0,0,1] => [0],
				[1,0,1] => [1],
				[0,1,1] => [0],
				[1,1,1] => [1],
			}
		)
	end
	
	def test_mux4
		s = Simulation.new
		c = Multiplexer4.new(s)
		
		help_test_logic_table(s,c,
			{
				[0,0,0,0,0,0] => [0],
				[1,0,0,0,0,0] => [0],
				[0,1,0,0,0,0] => [0],
				[1,1,0,0,0,0] => [0],
				[0,0,1,0,0,0] => [0],
				[1,0,1,0,0,0] => [0],
				[0,1,1,0,0,0] => [0],
				[1,1,1,0,0,0] => [0],
				[0,0,0,1,0,0] => [1],
				[1,0,0,1,0,0] => [1],
				[0,1,0,1,0,0] => [1],
				[1,1,0,1,0,0] => [1],
				[0,0,1,1,0,0] => [1],
				[1,0,1,1,0,0] => [1],
				[0,1,1,1,0,0] => [1],
				[1,1,1,1,0,0] => [1],	
				[0,0,0,0,0,1] => [0],
				[1,0,0,0,0,1] => [0],
				[0,1,0,0,0,1] => [0],
				[1,1,0,0,0,1] => [0],
				[0,0,1,0,0,1] => [1],
				[1,0,1,0,0,1] => [1],
				[0,1,1,0,0,1] => [1],
				[1,1,1,0,0,1] => [1],
				[0,0,0,1,0,1] => [0],
				[1,0,0,1,0,1] => [0],
				[0,1,0,1,0,1] => [0],
				[1,1,0,1,0,1] => [0],
				[0,0,1,1,0,1] => [1],
				[1,0,1,1,0,1] => [1],
				[0,1,1,1,0,1] => [1],
				[1,1,1,1,0,1] => [1],				
				[0,0,0,0,1,0] => [0],
				[1,0,0,0,1,0] => [0],
				[0,1,0,0,1,0] => [1],
				[1,1,0,0,1,0] => [1],
				[0,0,1,0,1,0] => [0],
				[1,0,1,0,1,0] => [0],
				[0,1,1,0,1,0] => [1],
				[1,1,1,0,1,0] => [1],
				[0,0,0,1,1,0] => [0],
				[1,0,0,1,1,0] => [0],
				[0,1,0,1,1,0] => [1],
				[1,1,0,1,1,0] => [1],
				[0,0,1,1,1,0] => [0],
				[1,0,1,1,1,0] => [0],
				[0,1,1,1,1,0] => [1],
				[1,1,1,1,1,0] => [1],		
				[0,0,0,0,1,1] => [0],
				[1,0,0,0,1,1] => [1],
				[0,1,0,0,1,1] => [0],
				[1,1,0,0,1,1] => [1],
				[0,0,1,0,1,1] => [0],
				[1,0,1,0,1,1] => [1],
				[0,1,1,0,1,1] => [0],
				[1,1,1,0,1,1] => [1],
				[0,0,0,1,1,1] => [0],
				[1,0,0,1,1,1] => [1],
				[0,1,0,1,1,1] => [0],
				[1,1,0,1,1,1] => [1],
				[0,0,1,1,1,1] => [0],
				[1,0,1,1,1,1] => [1],
				[0,1,1,1,1,1] => [0],
				[1,1,1,1,1,1] => [1]					
			}
		)
	end	
	
	def test_demux2
		s = Simulation.new()
		c = Demux2.new(s)
		help_test_logic_table(s,c,
			{
				[0,0] => [0,0],
				[1,0] => [0,1],
				[0,1] => [0,0],
				[1,1] => [1,0]
			}
		)
	end
	
	def test_demux4
		s = Simulation.new()
		c = Demux4.new(s)
		help_test_logic_table(s,c,
		{
			[0,0,0] => [0,0,0,0],
			[0,0,1] => [0,0,0,0],
			[0,1,0] => [0,0,0,0],
			[0,1,1] => [0,0,0,0],
			[1,0,0] => [0,0,0,1],
			[1,0,1] => [0,0,1,0],
			[1,1,0] => [0,1,0,0],
			[1,1,1] => [1,0,0,0]
		})
	end

	def test_mux8
		s = Simulation.new()
		c = Multiplexer8.new(s)
		help_test_logic_table(s,c,		
			{
			[0,0,0,0,0,0,0,0,  0,0,0] => [0],
			[1,1,1,1,1,1,1,0,  0,0,0] => [0],
			[1,1,1,1,1,1,1,1,  0,0,0] => [1],
			[0,0,0,1,0,0,0,0,  1,0,0] => [1] # lsb?			
			}
		)
	end	
	
	def test_demux8
		s = Simulation.new()
		c = Demux8.new(s)
		help_test_logic_table(s,c,
			{
				[0, 0,0,0] => [0,0,0,0,0,0,0,0],
				[0, 1,0,1] => [0,0,0,0,0,0,0,0],
				[1, 0,0,0] => [0,0,0,0,0,0,0,1], 
				[1, 0,0,1] => [0,0,0,0,0,0,1,0], 
				[1, 1,0,0] => [0,0,0,1,0,0,0,0], 
				[1, 1,0,1] => [0,0,1,0,0,0,0,0], 
				[1, 1,1,1] => [1,0,0,0,0,0,0,0]  
			}
		)
	end
	
	def test_ram8x8load
		s = Simulation.new()
		c = RAM8x8.new(s)	
		
		c.set_input_values([0,0,0,0,0,0,0,0,  0,0,0, 0])
		c.override(["00000000","00000001","00000010","00000011","00000100","00000101","00000110","00000111"])
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  1,0,1, 0],[0,0,0,0,0,1,0,1]) 
		# puts c.dump
	end
	
	def test_ram8x64load
		s = Simulation.new()
		c = RAM8x64.new(s)
				
		c.set_input_values([0,0,0,0,0,0,0,0,  0,0,0,0,0,0, 0])
		c.load_file("debug64.txt")
		
		help_test_case(s,c,[1,1,1,1,1,1,1,1,  0,0,1,1,1,0, 0],[0,0,0,0,1,1,1,0]) # load num into addr 6
	end
	
	def test_ram8x8
		s = Simulation.new()
		c = RAM8x8.new(s)							
		#                 ## data               sel   ld
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  0,0,0, 0],[0,0,0,0,0,0,0,0]) # sanity check
		help_test_case(s,c,[0,0,0,0,0,0,0,1,  0,0,0, 1],[0,0,0,0,0,0,0,1]) # load 1 into addr 0
		help_test_case(s,c,[0,1,0,1,0,1,0,1,  0,1,0, 0],[0,0,0,0,0,0,0,0]) # verify addr 2 is empty
		help_test_case(s,c,[0,0,0,0,0,0,0,1,  0,0,0, 0],[0,0,0,0,0,0,0,1]) # verify 1 still in addr 0 
		help_test_case(s,c,[0,1,0,1,0,1,0,1,  0,1,0, 1],[0,1,0,1,0,1,0,1]) # load num into addr 2
		help_test_case(s,c,[0,0,0,0,1,1,0,1,  1,0,1, 1],[0,0,0,0,1,1,0,1]) # load num into addr 5
		help_test_case(s,c,[0,0,0,1,0,1,1,0,  1,1,0, 1],[0,0,0,1,0,1,1,0]) # load num into addr 6
		help_test_case(s,c,[0,0,1,0,0,1,1,1,  1,1,1, 1],[0,0,1,0,0,1,1,1]) # load num into addr 7

		
		# puts c.dump
	end 
	
	def test_ram8x64
		s = Simulation.new()
		c = RAM8x64.new(s)	

		c.load_file("debug64.txt")
		
		#                 ## data               sel        ld
		help_test_case(s,c,[1,1,0,0,0,0,0,0,  0,0,0,0,0,0, 0],[0,0,0,0,0,0,0,0]) # sanity check
		help_test_case(s,c,[1,1,0,0,0,0,0,0,  0,0,0,0,0,0, 1],[1,1,0,0,0,0,0,0]) # sanity check		
		help_test_case(s,c,[0,0,0,0,0,0,0,1,  0,0,0,0,0,0, 1],[0,0,0,0,0,0,0,1]) # load 1 into addr 0
		help_test_case(s,c,[0,1,0,1,0,1,0,1,  0,0,0,0,1,0, 0],[0,0,0,0,0,0,1,0]) # verify addr 2 is empty
		help_test_case(s,c,[0,0,0,0,0,0,0,1,  0,0,0,0,0,0, 0],[0,0,0,0,0,0,0,1]) # verify 1 still in addr 0 
		help_test_case(s,c,[0,1,0,1,0,1,0,1,  0,0,0,0,1,0, 1],[0,1,0,1,0,1,0,1]) # load num into addr 2
		help_test_case(s,c,[0,0,0,0,0,1,0,1,  0,0,0,1,0,1, 1],[0,0,0,0,0,1,0,1]) # load num into addr 5
		help_test_case(s,c,[0,0,0,0,0,1,1,0,  0,0,0,1,1,0, 1],[0,0,0,0,0,1,1,0]) # load num into addr 6
		help_test_case(s,c,[0,0,0,0,0,1,1,1,  0,0,0,1,1,1, 1],[0,0,0,0,0,1,1,1]) # load num into addr 7
		
		help_test_case(s,c,[0,1,0,1,0,1,0,1,  1,0,0,0,1,0, 0],[0,0,1,0,0,0,1,0]) # test high bits
		help_test_case(s,c,[0,0,0,0,0,1,0,1,  1,0,0,1,0,1, 0],[0,0,1,0,0,1,0,1]) # test high bits
		help_test_case(s,c,[0,0,0,0,0,1,1,0,  0,1,0,1,1,0, 0],[0,0,0,1,0,1,1,0]) # test high bits
		help_test_case(s,c,[0,0,0,0,0,1,1,1,  1,1,1,1,1,1, 0],[0,0,1,1,1,1,1,1]) # test high bits
		help_test_case(s,c,[0,1,0,1,0,1,0,1,  1,0,1,0,1,0, 0],[0,0,1,0,1,0,1,0]) # test high bits
		help_test_case(s,c,[0,0,0,0,0,1,0,1,  0,0,1,1,0,1, 0],[0,0,0,0,1,1,0,1]) # test high bits
		help_test_case(s,c,[0,0,0,0,0,1,1,0,  1,0,0,1,1,0, 0],[0,0,1,0,0,1,1,0]) # test high bits
		help_test_case(s,c,[0,0,0,0,0,1,1,1,  0,0,1,1,1,1, 0],[0,0,0,0,1,1,1,1]) # test high bits
		
		
	end 	
	
	def test_programcounter
		s = Simulation.new()
		c = ProgramCounter.new(s)
		
		#                                   inc,jmp
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  0,0],[0,0,0,0,0,0,0,0])
		#                                   inc,jmp
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  1,0],[0,0,0,0,0,0,0,1])	
		#                                   inc,jmp
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  1,0],[0,0,0,0,0,0,1,0])	
		#                                   inc,jmp
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  0,0],[0,0,0,0,0,0,1,0])			
		#                                   inc,jmp
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  0,0],[0,0,0,0,0,0,1,0])	
		#                                   inc,jmp
		help_test_case(s,c,[0,0,0,0,0,0,0,0,  1,0],[0,0,0,0,0,0,1,1])	
	end
	
	def teardown
	end
end
