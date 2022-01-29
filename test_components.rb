require "test/unit"
require './components.rb'

# expose input and outputs for direct access
# class Component
	# attr_reader :inputs, :outputs
# end



class TestSimple < Test::Unit::TestCase

	def help_test_logic_table(component, cases)
		cases.each do |i,o|					
			
			component.set_inputs(i)
			
			# puts component.to_s
		
			if o.class == Array				
				assert_equal(o, component.outputs, i)			
			else
				assert_equal(o, component.get_output(0), i)
			end
		end
	end
	
	def test_dlatch
		l = DLatch.new()
		l.set = true
		assert_equal(false, l.value)
		l.enable = true
		l.enable = false
		assert_equal(true, l.value)		
	end
	
	def test_dflipflop
		c = Clock.new
		f = DFlipFlop.new(c)
		f.set = true
		assert_equal(false, f.value)
		c.full_pulse
		assert_equal(true, f.value)
	end

	def test_or		
		o = OrGate.new()
		help_test_logic_table(o,
			{
				[0,0] => false,
				[1,0] => true,
				[0,1] => true,
				[1,1] => true
			}
		)
	end
	
		def test_and		
		o = AndGate.new()
		help_test_logic_table(o,
			{
				[0,0] => false,
				[1,0] => false,
				[0,1] => false,
				[1,1] => true
			}
		)
	end
	
		def test_xor		
		o = XorGate.new()
		help_test_logic_table(o,
			{
				[0,0] => false,
				[1,0] => true,
				[0,1] => true,
				[1,1] => false
			}
		)
	end
	
	def test_nand	
		o = NandGate.new()
		help_test_logic_table(o,
			{
				[0,0] => true,
				[1,0] => true,
				[0,1] => true,
				[1,1] => false
			}
		)
	end
	
	def test_not
		c = NotGate.new()
		help_test_logic_table(c,
			{
				true => false,
				false => true
			}
		)		
	end
	
	def test_and4
		a4 = And4Gate.new()
		
		help_test_logic_table(a4,
			{
				[0,0,0,0] => false,
				[1,0,0,0] => false,
				[0,1,0,0] => false,
				[1,1,0,0] => false,
				[0,0,0,1] => false,
				[1,0,0,1] => false,
				[0,1,0,1] => false,
				[1,1,0,1] => false,
				[0,0,1,0] => false,
				[1,0,1,0] => false,
				[0,1,1,0] => false,
				[1,1,1,0] => false,
				[0,0,1,1] => false,
				[1,0,1,1] => false,
				[0,1,1,1] => false,
				[1,1,1,1] => true,				
			}
		)
	end
	
	def test_method_missing
		o = OrGate.new()
		o.a = true
		o.b = true			
		assert_raise NoMethodError do o.c = false end
	end

	def teardown
	end
end
