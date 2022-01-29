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
		
			puts "sim: #{sim.to_s}" if DEBUG
			puts "comp: #{component.to_s}"	if DEBUG
		
			component.set_input_values(i.collect do |val| val == 0 ? false : true end)
						
			puts "sim: #{sim.to_s}" if DEBUG
			puts "comp: #{component.to_s}"	if DEBUG
			
			sim.update				
			
			puts "sim: #{sim.to_s}" if DEBUG
			puts "comp: #{component.to_s}"	if DEBUG
			
			assert_equal(o, component.get_output_values().collect do |val| val ? 1 : 0 end, i.join(","))
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
			[0,0] => [0],
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
	
	def test_datareg
		s = Simulation.new
		c = DataLatch.new(s)
		c.set = true		
		assert_equal(false, c.value)		
		s.update(true)
		assert_equal(true, c.value)		
	end
	
	def test_datareg_not
		s = Simulation.new
		c = DataLatch.new(s)		
		
		n = NotGate.new(s)
		n.set_input_pointer(0,c.get_output_pointers[0])		
		c.set_input_pointer(0,n.get_output_pointers[0])
		s.update # latch value starts as off, so output from not gate should be true, so input to latch should be true
		assert_equal(false, c.value)
		assert_equal(true, n.x)
		s.update(true) # finish the previous update by storing true in the latch, making not input true		
		s.update(true) # now we need to propogate that through the not gate so it outputs false		
		assert_equal(false, c.value)
		s.update(true)
		assert_equal(true, c.value)
		s.update(true)
		assert_equal(false, c.value)
		s.update(true)
		assert_equal(true, c.value)
		s.update(true)
		assert_equal(false, c.value)		
				
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
	
	# def test_method_missing
		# o = OrGate.new()
		# o.a = true
		# o.b = true			
		# assert_raise NoMethodError do o.c = false end
	# end

	def teardown
	end
end
