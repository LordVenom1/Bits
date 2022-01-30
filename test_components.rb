require "test/unit"
require './components.rb'

# expose input and outputs for direct access
# class Component
	# attr_reader :inputs, :outputs
# end

DEBUG = false

class TestSimple < Test::Unit::TestCase

	def help_test_logic_table(sim, component, cases)
		
		cases.each do |i,o|
		
			component.set_input_values(i.collect do |val| val == 0 ? false : true end)	
			sim.update		
			# puts component.to_s
			
			#puts component.get_input_value(0)
			#puts component.get_input_value(1)
			
			# puts "comp: #{component.to_s}"
			
			assert_equal(o, component.get_outputs().collect do |val| val ? 1 : 0 end, i.join(","))
		end
	
	end
	
	# def test_dlatch
		# l = DLatch.new()
		# l.set = true
		# assert_equal(false, l.value)
		# l.enable = true
		# l.enable = false
		# assert_equal(true, l.value)		
	# end
	
	# def test_dflipflop
		# c = Clock.new
		# f = DFlipFlop.new(c)
		# f.set = true
		# assert_equal(false, f.value)
		# c.full_pulse
		# assert_equal(true, f.value)
	# end

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
		puts c.to_s
		assert_equal(false, c.get_output(0), "input doesn't do anything until load is set")
		
		c.set_input_values([1,1])
		s.update
		puts c.to_s
		assert_equal(true, c.get_output(0), "load reg, out should reflect it")
		
		
		
		c.set_input_values([0,0])
		s.update		
		assert_equal(true, c.get_output(0), "output sticks even when input changes")
	end
	
	def test_register8
		s = Simulation.new
		c = Register8.new(s)
				
		c.set_input_values([0,0,0,0,0,0,0,1,0])
		s.update		
		puts c.to_s
		assert_equal([0,0,0,0,0,0,0,0], c.get_outputs().collect do |val| val ? 1 : 0 end, "input doens't matter until input is set")
		
		c.set_input_values([1,1,1,1,1,1,1,1,1])
		s.update
		puts c.to_s
		assert_equal([0,0,0,0,0,0,0,1], c.get_outputs().collect do |val| val ? 1 : 0 end, "now output is showing input")
				
		c.set_input_values([0,1,1,1,0,0,0,1,0])
		s.update
		puts c.to_s		
		assert_equal([0,0,0,0,0,0,0,1], c.get_outputs().collect do |val| val ? 1 : 0 end, "output is still showing old output in spite of input changing")
				
	end
	
	def test_datareg
		s = Simulation.new
		c = DataLatch.new(s)
		c.set_input_to_output(0,s.true_signal,0)
		assert_equal(false, c.get_output(0))		
		s.update(true)
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
		n.set_input_to_output(0, c, 0)
		c.set_input_to_output(0, n, 0)
		
		s.update # latch value starts as off, so output from not gate should be true, so input to latch should be true
		assert_equal(false, c.get_output(0))
		assert_equal(true, n.get_output(0))
		s.update(true) # finish the previous update by storing true in the latch, making not input true		
		s.update(true) # now we need to propogate that through the not gate so it outputs false		
		assert_equal(false, c.get_output(0))
		s.update(true)
		assert_equal(true, c.get_output(0))
		s.update(true)
		assert_equal(false, c.get_output(0))
		s.update(true)
		assert_equal(true, c.get_output(0))
		s.update(true)
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
	
	# def test_fulladder
		# s = Simulation.new
		# c = FullAdder.new(s)
		
		# help_test_logic_table(s,c,
		# {
			# [0,0,0] => [0,0],
			# [0,0,1] => [1,0],
			# [0,1,0] => [1,0],
			# [0,1,1] => [0,1],
			# [1,0,0] => [1,0],
			# [1,0,1] => [0,1],
			# [1,1,0] => [0,1],
			# [1,1,1] => [1,1]			
		# })
	# end
	
	# def test_fulladdersub8
		# s = Simulation.new
		# c = FullAdderSub8.new(s)

		# help_test_logic_table(s,c,
		# {
			# [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] => [0,0,0,0,0,0,0,0,0],
			# [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] => [1,0,0,0,0,0,0,0,0],
			# [1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0] => [0,1,0,0,0,0,0,0,0],
			# [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0] => [0,1,1,1,1,1,1,1,1],
			# [0,0,0,0,1,1,0,0,0,0,0,0,1,0,0,1,0] => [0,0,0,0,0,0,1,1,0],			
			# [1,1,0,0,0,1,0,1,1,0,0,1,1,1,1,0,0] => [0,0,1,1,1,0,0,0,1]			
		# })
			
		
		# help_test_logic_table(s,c,
		# {                   #
			# [0,0,0,1,1,0,0,0,0,0,0,0,1,0,0,0,1] => [0,0,0,1,0,0,0,0,1], # not sure what carry means yet
			# [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1] => [0,0,0,0,0,0,0,0,1],			
			# [1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1] => [0,0,0,0,0,0,0,0,1],			
			# [1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1] => [1,1,1,1,1,1,1,1,0]		
			
		# })
	# end	
	
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
	
	# def test_method_missing
		# o = OrGate.new()
		# o.a = true
		# o.b = true			
		# assert_raise NoMethodError do o.c = false end
	# end

	def teardown
	end
end
