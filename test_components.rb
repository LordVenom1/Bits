require "test/unit"
require_relative 'simulation.rb'

class TestSimple < Test::Unit::TestCase

	def setup
		@sim = Simulation.new
	end
	
	def teardown
	end
	
	def help_test_component_case(comp, inputs, expected_output)		
		help_test_component_set_inputs(comp, inputs)
		@sim.update # pulse the clock in case we need it
		assert_equal(expected_output, comp.output ? "T" : "F")
	end
	
	def help_test_component_set_inputs(comp, inputs)
		inputs.split("").each_with_index do |i,n|			
			gate = Simulation::FALSE if ["0","F"].include? i
			gate = Simulation::TRUE if ["1","T"].include? i
			raise "invalid input #{inputs}" unless gate
			comp.set_input(n, gate)
		end
	end
	
	def help_test_component_cases(comp, cases)
		cases.each do |i,o|
			help_test_component_case(comp, i, o)
		end
	end
	
	def help_test_component_group_set_inputs(cg, inputs)
		inputs.split("").each_with_index do |i,n|			
			gate = Simulation::FALSE if ["0","F"].include? i
			gate = Simulation::TRUE if ["1","T"].include? i
			raise "invalid input #{inputs}" unless gate
			cg.set_aliased_input(n, gate)
		end	
	end

	def help_test_component_group_case(cg, inputs, expected_outputs)			
		
		# convert a string of T/F to actual gates and link them to the component inputs inside the component group
		help_test_component_group_set_inputs(cg,inputs)

		@sim.update		
		
		# calculate all the outputs of the component group		
		calculated_outputs = (0...expected_outputs.size).collect do |n|
			cg.aliased_output(n).output
		end
		
		# puts "#{inputs} => #{expected_outputs}  =? " + (calculated_outputs.collect do |o| o ? 'T' : 'F' end.join(""))
		assert_equal(expected_outputs.split("").collect do |o| ["1","T"].include? o end, calculated_outputs, inputs)
	end
	
	def help_test_component_group_cases(cg, cases)
		cases.each do |i,o|
			help_test_component_group_case(cg, i, o)
		end
	end
	
	#################################################################################
	#########  Test single gates
	#################################################################################
	
	def test_buffer
		comp = @sim.register_component(BufferGate.new())
		help_test_component_cases(comp,
		{
			"F" => "F",
			"T" => "T"							
		})		
	end
	
	def test_not		
		comp = @sim.register_component(NotGate.new())
		help_test_component_cases(comp,
		{
			"F" => "T",
			"T" => "F"							
		})		
	end
	
	def test_nand		
		comp = @sim.register_component(NandGate.new())
		help_test_component_cases(comp,
		{
			"FF" => "T",
			"TF" => "T",
			"FT" => "T",
			"TT" => "F"
		})
	end
	
	def test_xor		
		comp = @sim.register_component(XorGate.new())
		help_test_component_cases(comp,
		{
			"FF" => "F",
			"FT" => "T",
			"TF" => "T",
			"TT" => "F"
		})
	end
	
	def test_datalatch
		comp = @sim.register_clocked_component(DataLatch.new(),:high)
		
		help_test_component_case(comp, "F", "F")
		help_test_component_case(comp, "F", "F")
		help_test_component_case(comp, "T", "T")
		help_test_component_case(comp, "T", "T")
	end
	
	def test_datalatch_chain
	
		# this might not happen in a computer but conceptually chaining 
		# two latches together should require two update()s to shift 
		# changes through
		
		dl1 = @sim.register_clocked_component(DataLatch.new, :high)
		dl2 = @sim.register_clocked_component(DataLatch.new, :high)		
		n = @sim.register_component(NotGate.new)
		
		# DL > DL > Not ^
		
		dl1.set_input(0,n)
		dl2.set_input(0,dl1)
		n.set_input(0,dl2)
		
		assert_equal(false, dl1.output)
		assert_equal(false, dl2.output)
		@sim.update
		assert_equal(true, dl1.output)
		assert_equal(false, dl2.output)
		@sim.update
		assert_equal(true, dl1.output)
		assert_equal(true, dl2.output)
		@sim.update
		assert_equal(false, dl1.output)
		assert_equal(true, dl2.output)
		@sim.update
		assert_equal(false, dl1.output)
		assert_equal(false, dl2.output)
	end
	
	def test_datareg_chain_inverse	
	
		# # with the first datalatch updating on clock-low, both latches will populated 
		# # in a single update
		
		dl1 = @sim.register_clocked_component(DataLatch.new, :low)
		dl2 = @sim.register_clocked_component(DataLatch.new, :high)		
		n = @sim.register_component(NotGate.new)		
		
		# DL(:low) > DL(:high) > Not ^
		
		dl1.set_input(0,n)
		dl2.set_input(0,dl1)
		n.set_input(0,dl2)
	
		assert_equal(false, dl1.output)
		assert_equal(false, dl2.output)
		@sim.update
		assert_equal(true, dl1.output)
		assert_equal(true, dl2.output)
		@sim.update
		assert_equal(false, dl1.output)
		assert_equal(false, dl2.output)
		@sim.update
		assert_equal(true, dl1.output)
		assert_equal(true, dl2.output)
		@sim.update
		assert_equal(false, dl1.output)
		assert_equal(false, dl2.output)	
	end
		
	#################################################################################
	#########  Test component groups
	#################################################################################
	
	def test_or4
		comp = ComponentGroup.build_or4_gate(@sim)

		help_test_component_group_cases(comp,
		{
			"0000" => "0",
			"0001" => "1",
			"0010" => "1",
			"0011" => "1",
			"0100" => "1",
			"0101" => "1",
			"0110" => "1",
			"0111" => "1",
			"1000" => "1",
			"1001" => "1",
			"1010" => "1",
			"1011" => "1",
			"1100" => "1",
			"1101" => "1",
			"1110" => "1",
			"1111" => "1"
		})
	end	
	
	def test_and4
		comp = ComponentGroup.build_and4_gate(@sim)

		help_test_component_group_cases(comp,
		{
			"0000" => "0",
			"0001" => "0",
			"0010" => "0",
			"0011" => "0",
			"0100" => "0",
			"0101" => "0",
			"0110" => "0",
			"0111" => "0",
			"1000" => "0",
			"1001" => "0",
			"1010" => "0",
			"1011" => "0",
			"1100" => "0",
			"1101" => "0",
			"1110" => "0",
			"1111" => "1"
		})
	end	
	
	def test_and_n
		comp = ComponentGroup.build_and_n_gate(@sim, 5)
		
		help_test_component_group_cases(comp,
		{
			"00000" => "0",
			"00001" => "0",
			"00010" => "0",
			"00011" => "0",
			"00100" => "0",
			"00101" => "0",
			"00110" => "0",
			"00111" => "0",
			"01000" => "0",
			"01001" => "0",
			"01010" => "0",
			"01011" => "0",
			"01100" => "0",
			"01101" => "0",
			"01110" => "0",
			"01111" => "0",
			"10000" => "0",
			"10001" => "0",
			"10010" => "0",
			"10011" => "0",
			"10100" => "0",
			"10101" => "0",
			"10110" => "0",
			"10111" => "0",
			"11000" => "0",
			"11001" => "0",
			"11010" => "0",
			"11011" => "0",
			"11100" => "0",
			"11101" => "0",
			"11110" => "0",
			"11111" => "1"			
		})		
	end
	
	def test_or_n
		comp = ComponentGroup.build_or_n_gate(@sim, 4)
		
		help_test_component_group_cases(comp,
		{
			"0000" => "0",
			"0001" => "1",
			"0010" => "1",
			"0011" => "1",
			"0100" => "1",
			"0101" => "1",
			"0110" => "1",
			"0111" => "1",
			"1000" => "1",
			"1001" => "1",
			"1010" => "1",
			"1011" => "1",
			"1100" => "1",
			"1101" => "1",
			"1110" => "1",
			"1111" => "1"		
		})	
	end
	
	def test_nor_n
		comp = ComponentGroup.build_nor_n_gate(@sim, 4)		
		help_test_component_group_cases(comp,
		{
			"0000" => "1",
			"0001" => "0",
			"0010" => "0",
			"0011" => "0",
			"0100" => "0",
			"0101" => "0",
			"0110" => "0",
			"0111" => "0",
			"1000" => "0",
			"1001" => "0",
			"1010" => "0",
			"1011" => "0",
			"1100" => "0",
			"1101" => "0",
			"1110" => "0",
			"1111" => "0"		
		})
	end
	
	def test_bufferset
		comp = ComponentGroup.build_bufferset(@sim, 3)
		
		help_test_component_group_cases(comp,
		{
			"110" => "110",
			"000" => "000",
			"111" => "111",
			"100" => "100"
		})
	end
	
	def test_encoder4x2
		comp = ComponentGroup.build_encoder4x2(@sim)
		
		help_test_component_group_cases(comp,
			{
			"0000" => "00",  # unspecified
			"0001" => "00",
			"0010" => "01",
			"0100" => "10",
			"1000" => "11"
			}
		)
	end
	
	def test_encoder8x3 # MSB
		comp = ComponentGroup.build_encoder8x3(@sim)
		
		help_test_component_group_cases(comp,
			{
			"00000000" => "000",  # unspecified
			"10000000" => "000",
			"01000000" => "001",
			"00100000" => "010",
			"00010000" => "011",		
			"00001000" => "100",
			"00000100" => "101",
			"00000010" => "110",
			"00000001" => "111" 			
			}
		)
	end
	
	def test_halfadder
		# s = Simulation.new
		# c = HalfAdder.new(s,"comp",nil)
		comp = ComponentGroup.build_halfadder(@sim)
		
		help_test_component_group_cases(comp,
			{
				"00" => "00",
				"01" => "10",
				"10" => "10",
				"11" => "01"
			}
		)

	end
	
	def test_fulladder		
		comp = ComponentGroup.build_fulladder(@sim)		
		help_test_component_group_cases(comp,
			{
				"000" => "00",
				"001" => "10",
				"010" => "10",
				"011" => "01",
				"100" => "10",
				"101" => "01",
				"110" => "01",
				"111" => "11"				
			}
		)
	end
	
	def test_fulladder_n
		comp = ComponentGroup.build_fulladder_n(@sim, 8)
		help_test_component_group_cases(comp,
			{			
			"00000000000000000" => "000000000",
			"00000001000000000" => "000000010",
			"00000001000000010" => "000000100",
			"10000000000000000" => "100000000",
			"10000000100000000" => "000000001",
			"11111111111111110" => "111111101",
			"00001100000010010" => "000101010",		
			"11000101100111100" => "011000111",
			"00000000000000001" => "000000010",
			"11000101100111101" => "011001001"			
			}
		)
	end
	
	def test_fulladdersub8
		comp = ComponentGroup.build_fulladdersub8(@sim)		
		help_test_component_group_cases(comp,
			{			
			"00000000000000000" => "000000000",
			"00000001000000000" => "000000010",
			"00000001000000010" => "000000100",
			"10000000000000000" => "100000000",
			"10000000100000000" => "000000001",
			"11111111111111110" => "111111101",
			"00001100000010010" => "000101010",			
			"11000101100111100" => "011000111",			
			"00011000000010001" => "000100001",
			"00000000000000001" => "000000001",			
			"10000000100000001" => "000000001",			
			"10000000010000001" => "010000001",	
			"00000111000000011" => "000001101",
			"00000001000001111" => "111110100"		
			}
		)
	end
	
	def test_mux2
		comp = ComponentGroup.build_mux2(@sim)		
		help_test_component_group_cases(comp,
			{
				"000" => "0",
				"100" => "1",
				"010" => "0",
				"110" => "1",
				"001" => "0",
				"011" => "1",
				"101" => "0",
				"111" => "1"
			}
		)
	end
	
	def test_mux4
		comp = ComponentGroup.build_mux4(@sim)		
		help_test_component_group_cases(comp,
			{
				"000000" => "0",
				"100000" => "1",
				"010000" => "0",
				"110000" => "1",
				"001000" => "0",
				"101000" => "1",
				"011000" => "0",
				"111000" => "1",
				"000100" => "0",
				"100100" => "1",
				"010100" => "0",
				"110100" => "1",
				"001100" => "0",
				"101100" => "1",
				"011100" => "0",
				"111100" => "1",	
				"000001" => "0",
				"100001" => "0",
				"010001" => "1",
				"110001" => "1",
				"001001" => "0",
				"101001" => "0",
				"011001" => "1",
				"111001" => "1",
				"000101" => "0",
				"100101" => "0",
				"010101" => "1",
				"110101" => "1",
				"001101" => "0",
				"101101" => "0",
				"011101" => "1",
				"111101" => "1",				
				"000010" => "0",
				"100010" => "0",
				"010010" => "0",
				"110010" => "0",
				"001010" => "1",
				"101010" => "1",
				"011010" => "1",
				"111010" => "1",
				"000110" => "0",
				"100110" => "0",
				"010110" => "0",
				"110110" => "0",
				"001110" => "1",
				"101110" => "1",
				"011110" => "1",
				"111110" => "1",		
				"000011" => "0",
				"100011" => "0",
				"010011" => "0",
				"110011" => "0",
				"001011" => "0",
				"101011" => "0",
				"011011" => "0",
				"111011" => "0",
				"000111" => "1",
				"100111" => "1",
				"010111" => "1",
				"110111" => "1",
				"001111" => "1",
				"101111" => "1",
				"011111" => "1",
				"111111" => "1"					
			}
		)
	end
	
	def test_mux8
		comp = ComponentGroup.build_mux8(@sim)
		
		help_test_component_group_cases(comp,
			{
			"10000000000" => "1",
			"01000000001" => "1",
			"00100000010" => "1",
			"00010000011" => "1",
			"00001000100" => "1",
			"00000100101" => "1",
			"00000010110" => "1",
			"00000001111" => "1",
			"00000000000" => "0",
			"01111111000" => "0",
			"11111111000" => "1"	
			}
		)
	end	
	
	def test_mux16
		comp = ComponentGroup.build_mux16(@sim)		
		help_test_component_group_cases(comp,
			{
				"00000000000000000000" => "0",
				"10000000000000000000" => "1",
				"01111111111111110000" => "0",
				"00000000000000011111" => "1",
				"00000000010000001001" => "1",				
				"00000000000000101110" => "1"
			}
		)				
	end
	
	def test_mux_n_2
		comp = ComponentGroup.build_mux_n(@sim, 2)
		help_test_component_group_cases(comp,
			{
				"000" => "0",
				"100" => "1",
				"010" => "0",
				"110" => "1",
				"001" => "0",
				"011" => "1",
				"101" => "0",
				"111" => "1"
			}
		)
	end

	def test_mux_n_4
		comp = ComponentGroup.build_mux_n(@sim, 4)
		help_test_component_group_cases(comp,
			{
				"000000" => "0",
				"100000" => "1",
				"010000" => "0",
				"110000" => "1",
				"001000" => "0",
				"101000" => "1",
				"011000" => "0",
				"111000" => "1",
				"000100" => "0",
				"100100" => "1",
				"010100" => "0",
				"110100" => "1",
				"001100" => "0",
				"101100" => "1",
				"011100" => "0",
				"111100" => "1",	
				"000001" => "0",
				"100001" => "0",
				"010001" => "1",
				"110001" => "1",
				"001001" => "0",
				"101001" => "0",
				"011001" => "1",
				"111001" => "1",
				"000101" => "0",
				"100101" => "0",
				"010101" => "1",
				"110101" => "1",
				"001101" => "0",
				"101101" => "0",
				"011101" => "1",
				"111101" => "1",				
				"000010" => "0",
				"100010" => "0",
				"010010" => "0",
				"110010" => "0",
				"001010" => "1",
				"101010" => "1",
				"011010" => "1",
				"111010" => "1",
				"000110" => "0",
				"100110" => "0",
				"010110" => "0",
				"110110" => "0",
				"001110" => "1",
				"101110" => "1",
				"011110" => "1",
				"111110" => "1",		
				"000011" => "0",
				"100011" => "0",
				"010011" => "0",
				"110011" => "0",
				"001011" => "0",
				"101011" => "0",
				"011011" => "0",
				"111011" => "0",
				"000111" => "1",
				"100111" => "1",
				"010111" => "1",
				"110111" => "1",
				"001111" => "1",
				"101111" => "1",
				"011111" => "1",
				"111111" => "1"					
			}
		)
	end
	
	def test_demux2
		comp = ComponentGroup.build_demux2(@sim)		
		help_test_component_group_cases(comp,
			{
				"00" => "00",
				"10" => "10",
				"01" => "00",
				"11" => "01"
			}
		)
	end
	
	def test_demux4
		comp = ComponentGroup.build_demux4(@sim)		
		help_test_component_group_cases(comp,
			{
			"000" => "0000",
			"001" => "0000",
			"010" => "0000",
			"011" => "0000",
			"100" => "1000",
			"101" => "0100",
			"110" => "0010",
			"111" => "0001"
		})
	end

	def test_demux8
		comp = ComponentGroup.build_demux8(@sim)		
		help_test_component_group_cases(comp,
			{
				"0000" => "00000000",
				"0101" => "00000000",
				"1000" => "10000000", 
				"1001" => "01000000", 
				"1100" => "00001000", 
				"1101" => "00000100", 
				"1110" => "00000010",
				"1111" => "00000001"  
			}
		)
	end
	
	def test_demux16
		comp = ComponentGroup.build_demux16(@sim)		
		help_test_component_group_cases(comp,
			{
				"00000" => "0000000000000000",
				"00101" => "0000000000000000",
				"10000" => "1000000000000000", 
				"10001" => "0100000000000000", 
				"10100" => "0000100000000000", 
				"10101" => "0000010000000000", 
				"10111" => "0000000100000000"  
			}
		)
	end
	
	def test_demux_n_2
		comp = ComponentGroup.build_demux_n(@sim, 2)
		help_test_component_group_cases(comp,
			{
				"00" => "00",
				"10" => "10",
				"01" => "00",
				"11" => "01"
			}
		)
	end
	
	def test_demux_n_8
		comp = ComponentGroup.build_demux_n(@sim, 8)		
		help_test_component_group_cases(comp,
			{
				"0000" => "00000000",
				"0101" => "00000000",
				"1000" => "10000000", 
				"1001" => "01000000", 
				"1100" => "00001000", 
				"1101" => "00000100", 
				"1110" => "00000010",
				"1111" => "00000001"  
			}
		)
	end
	
	def test_bus8x8
		comp = ComponentGroup.build_bus8x8(@sim)

		setup = "01000001" + # 1
			    "01000010" + # 2
			    "01000011" + # 3
			    "01000100" + # 4
			    "01000101" + # 5
			    "01000110" + # 6
			    "01000111" + # 7
			    "01001000"   # 8

		help_test_component_group_cases(comp,
			{
				setup + "10000000" => "01000001",
				setup + "01000000" => "01000010",
				setup + "00100000" => "01000011",
				setup + "00010000" => "01000100",
				setup + "00001000" => "01000101",
				setup + "00000100" => "01000110",
				setup + "00000010" => "01000111",
				setup + "00000001" => "01001000"
			}
		)
	end
	
	def test_bus8x16
		comp = ComponentGroup.build_bus8x16(@sim)

		setup = "0010011101000001" + # 1
			    "0010011101000010" + # 2
			    "0010011101000011" + # 3
			    "0010011101000100" + # 4
			    "0010011101000101" + # 5
			    "0010011101000110" + # 6
			    "0010011101000111" + # 7
			    "0010011101001000"  # 8

		help_test_component_group_cases(comp,
			{
				setup + "10000000" => "0010011101000001",
				setup + "01000000" => "0010011101000010",
				setup + "00100000" => "0010011101000011",
				setup + "00010000" => "0010011101000100",
				setup + "00001000" => "0010011101000101",
				setup + "00000100" => "0010011101000110",
				setup + "00000010" => "0010011101000111",
				setup + "00000001" => "0010011101001000"
			}
		)
	end
	
	def test_bus_n_m_3_2
		comp = ComponentGroup.build_bus_n_m(@sim, 3, 2)
		
		setup = "01" + # 1
		        "10" + # 2
				"11"   # 3
		
		help_test_component_group_cases(comp,
			{
				setup + "100" => "01",
				setup + "001" => "11",
				setup + "010" => "10",
			}
		)
	end
	
	#################################################################################
	#########  Test clocked component groups
	#################################################################################
	
	def test_bit_register		
	
		comp = ComponentGroup.build_bit_register(@sim, :high)
		
		help_test_component_group_case(comp,"10","0") # inpu1 doesn'1 do any1hing un1il load is se1
		help_test_component_group_case(comp,"11","1") # load reg, ou1 should re0lec1 1he new value
		help_test_component_group_case(comp,"00","1") # ou1pu1 s1icks even when inpu1 changes

	end
	
	def test_register8		
		comp = ComponentGroup.build_register_n(@sim, 8)
		
		help_test_component_group_case(comp,"111111110","00000000") # inpu1 doesn'1 do any1hing un1il load is se1
		help_test_component_group_case(comp,"111111111","11111111") # load se1, ou1 should re0lec1 1he new value
		help_test_component_group_case(comp,"100101010","11111111") # ou1pu1 is s1ill showing old ou1pu1 in spi1e o0 inpu1 changing
		help_test_component_group_case(comp,"000111011","00011101") # load set, out should reflect the new value
	end
	
	#################################################################################
	#########  Test RAM Components
	#################################################################################	

	def test_ram8x8
		comp = ComponentGroup.build_ram8x8(@sim)#    ADRL				
		help_test_component_group_case(comp,"000000000000","00000000") # sanity check
		help_test_component_group_case(comp,"000000010001","00000001") # load 1 into addr 0
		help_test_component_group_case(comp,"010101010100","00000000") # verify addr 2 is empty
		help_test_component_group_case(comp,"000000010000","00000001") # verify 1 still in addr 0 
		help_test_component_group_case(comp,"010101010101","01010101") # load num into addr 2
		help_test_component_group_case(comp,"000011011011","00001101") # load num into addr 5
		help_test_component_group_case(comp,"000101101101","00010110") # load num into addr 6
		help_test_component_group_case(comp,"001001111111","00100111") # load num into addr 7		
	end 
		
	def test_ram8x64
		initial_data = File.readlines("util/debug64.txt").collect do |line| line.strip end		
		comp = ComponentGroup.build_ram8x64(@sim, :high, initial_data)		

		
		#                 ## data               sel        ld
		help_test_component_group_case(comp,"110000000000000","00000000") # sanity check
		help_test_component_group_case(comp,"110000000000001","11000000") # sanity check		
		help_test_component_group_case(comp,"000000010000001","00000001") # load 1 into addr 0
		help_test_component_group_case(comp,"010101010000100","00000010") # verify addr 2 is empty
		help_test_component_group_case(comp,"000000010000000","00000001") # verify 1 still in addr 0 
		help_test_component_group_case(comp,"010101010000101","01010101") # load num into addr 2
		help_test_component_group_case(comp,"000001010001011","00000101") # load num into addr 5
		help_test_component_group_case(comp,"000001100001101","00000110") # load num into addr 6
		help_test_component_group_case(comp,"000001110001111","00000111") # load num into addr 7
		help_test_component_group_case(comp,"010101011000100","00100010") # test high bits
		help_test_component_group_case(comp,"000001011001010","00100101")
		help_test_component_group_case(comp,"000001100101100","00010110")
		help_test_component_group_case(comp,"000001111111110","00111111")
		help_test_component_group_case(comp,"010101011010100","00101010")
		help_test_component_group_case(comp,"000001010011010","00001101")
		help_test_component_group_case(comp,"000001101001100","00100110")
		help_test_component_group_case(comp,"000001110011110","00001111")		
		
	end 	
		
	def test_ram8x256
		initial_data = File.readlines("util/debug256.txt").collect do |line| line.strip end	
		comp = ComponentGroup.build_ram8x256(@sim, :high, initial_data)		

		#reads
		help_test_component_group_case(comp,"10000110000000000","00000000") 
		help_test_component_group_case(comp,"10000110001000100","00100010") 
		help_test_component_group_case(comp,"10000110001001010","00100101") 
		help_test_component_group_case(comp,"10000110000101100","00010110") 
		help_test_component_group_case(comp,"10000110001111110","00111111")
		help_test_component_group_case(comp,"10000110100000000","10000000") 
		help_test_component_group_case(comp,"10000110011000100","01100010") 
		help_test_component_group_case(comp,"10000110101001010","10100101") 
		help_test_component_group_case(comp,"10000110010101100","01010110") 
		help_test_component_group_case(comp,"10000110101111110","10111111")
		# writes
		help_test_component_group_case(comp,"10000110000000001","10000110") 
		help_test_component_group_case(comp,"10000110001000101","10000110") 
		help_test_component_group_case(comp,"10000110001001011","10000110") 
		help_test_component_group_case(comp,"10000110000101101","10000110") 
		help_test_component_group_case(comp,"10000110001111111","10000110")
		help_test_component_group_case(comp,"10000110100000001","10000110") 
		help_test_component_group_case(comp,"10000110011000101","10000110") 
		help_test_component_group_case(comp,"10000110101001011","10000110") 
		help_test_component_group_case(comp,"10000110010101101","10000110") 
		help_test_component_group_case(comp,"10000110101111111","10000110")
	end
	
	def test_ram8x1024
		initial_data = File.readlines("util/debug1024.txt").collect do |line| line.strip end	
		comp = ComponentGroup.build_ram8x1024(@sim, :high, initial_data)
		
		#reads                               __data_||__addr__|L
		help_test_component_group_case(comp,"1000011000000000000","00000000") 
		help_test_component_group_case(comp,"1000011000001000100","00100010") 
		help_test_component_group_case(comp,"1000011000001001010","00100101") 
		help_test_component_group_case(comp,"1000011000000101100","00010110") 
		help_test_component_group_case(comp,"1000011000001111110","00111111")
		help_test_component_group_case(comp,"1000011000100000000","10000000") 
		help_test_component_group_case(comp,"1000011000011000100","01100010") 
		help_test_component_group_case(comp,"1000011000101001010","10100101") 
		help_test_component_group_case(comp,"1000011000010101100","01010110") 
		help_test_component_group_case(comp,"1000011000101111110","10111111")
		# writes
		help_test_component_group_case(comp,"1000011000000000001","10000110") 
		help_test_component_group_case(comp,"1000011000001000101","10000110") 
		help_test_component_group_case(comp,"1000011000001001011","10000110") 
		help_test_component_group_case(comp,"1000011000000101101","10000110") 
		help_test_component_group_case(comp,"1000011000001111111","10000110")
		help_test_component_group_case(comp,"1000011000100000001","10000110") 
		help_test_component_group_case(comp,"1000011000011000101","10000110") 
		help_test_component_group_case(comp,"1000011000101001011","10000110") 
		help_test_component_group_case(comp,"1000011000010101101","10000110") 
		help_test_component_group_case(comp,"1000011000101111111","10000110")
	end
	
	def test_ram_n_m_8_8
		comp = ComponentGroup.build_ram_n_m(@sim, 8, 8)#    ADRL				
		help_test_component_group_case(comp,"000000000000","00000000") # sanity check
		help_test_component_group_case(comp,"000000010001","00000001") # load 1 into addr 0
		help_test_component_group_case(comp,"010101010100","00000000") # verify addr 2 is empty
		help_test_component_group_case(comp,"000000010000","00000001") # verify 1 still in addr 0 
		help_test_component_group_case(comp,"010101010101","01010101") # load num into addr 2
		help_test_component_group_case(comp,"000011011011","00001101") # load num into addr 5
		help_test_component_group_case(comp,"000101101101","00010110") # load num into addr 6
		help_test_component_group_case(comp,"001001111111","00100111") # load num into addr 7		
	end 
	
		
	def test_ram_n_m_2_3
		comp = ComponentGroup.build_ram_n_m(@sim, 3, 2)#    ADRL				
		help_test_component_group_case(comp,"00000","000") # sanity check
		help_test_component_group_case(comp,"00101","001") # load 1 into addr 0
		help_test_component_group_case(comp,"00100","001") # verify addr 2 is empty
		help_test_component_group_case(comp,"01011","010") # verify 1 still in addr 0 
	end 
	
	def test_rom_n_2x3
		addr_n = 2
		data_n = addr_n ** 2
		width_n = 3
		data = File.readlines("util/debug1024.txt").first(data_n).collect do |line| line.strip[-width_n..-1] end
		comp = ComponentGroup.build_rom_n_m(@sim, width_n, data_n, data)
		
		help_test_component_group_case(comp, "00", "000")
		help_test_component_group_case(comp, "01", "001")
		help_test_component_group_case(comp, "10", "010")
		help_test_component_group_case(comp, "11", "011")
	end
	
	def test_rom_n_4x3
		
		addr_n = 4
		data_n = addr_n ** 2
		width_n = 3
		data = File.readlines("util/debug1024.txt").first(data_n).collect do |line| line.strip[-width_n..-1] end
		comp = ComponentGroup.build_rom_n_m(@sim, width_n, data_n, data)
		
		help_test_component_group_case(comp, "0000", "000")
		help_test_component_group_case(comp, "0001", "001")
		help_test_component_group_case(comp, "0010", "010")
		help_test_component_group_case(comp, "0011", "011")
		help_test_component_group_case(comp, "1100", "100")
		help_test_component_group_case(comp, "1101", "101")
		help_test_component_group_case(comp, "1110", "110")
		help_test_component_group_case(comp, "1111", "111")		
		help_test_component_group_case(comp, "1000", "000")
		help_test_component_group_case(comp, "1001", "001")
		help_test_component_group_case(comp, "1010", "010")
		help_test_component_group_case(comp, "1011", "011")		
	end
	
	def test_rom_n_4x5
		addr_n = 4
		data_n = addr_n ** 2
		width_n = 5
		data = File.readlines("util/debug1024.txt").first(data_n).collect do |line| line.strip[-width_n..-1] end
		comp = ComponentGroup.build_rom_n_m(@sim, width_n, data_n, data)
		
		help_test_component_group_case(comp, "0000", "00000")
		help_test_component_group_case(comp, "0001", "00001")
		help_test_component_group_case(comp, "0010", "00010")
		help_test_component_group_case(comp, "0011", "00011")
		help_test_component_group_case(comp, "1100", "01100")
		help_test_component_group_case(comp, "1101", "01101")
		help_test_component_group_case(comp, "1110", "01110")
		help_test_component_group_case(comp, "1111", "01111")		
		help_test_component_group_case(comp, "1000", "01000")
		help_test_component_group_case(comp, "1001", "01001")
		help_test_component_group_case(comp, "1010", "01010")
		help_test_component_group_case(comp, "1011", "01011")		
	end	
	
	def test_rom8x16
		data = File.readlines("util/debug1024.txt").first(16).collect do |line| line.strip end
		comp = ComponentGroup.build_rom8x16(@sim,data)
		
		help_test_component_group_case(comp,"0000","00000000") 
		help_test_component_group_case(comp,"0010","00000010") 
		help_test_component_group_case(comp,"0101","00000101") 
		help_test_component_group_case(comp,"0110","00000110") 
		help_test_component_group_case(comp,"1111","00001111")
	end
	
	def test_rom8x256
		data = File.readlines("util/debug1024.txt").first(256).collect do |line| line.strip end
		comp = ComponentGroup.build_rom8x256(@sim,data)
		
		help_test_component_group_case(comp,"00000000","00000000") 
		help_test_component_group_case(comp,"00000001","00000001") 
		help_test_component_group_case(comp,"00000101","00000101")
		help_test_component_group_case(comp,"00100010","00100010") 
		help_test_component_group_case(comp,"01010101","01010101") 
		help_test_component_group_case(comp,"01100110","01100110") 
		help_test_component_group_case(comp,"11111111","11111111")
	end	
	
	def test_rom8x1024
		data = File.readlines("util/debug1024.txt").collect do |line| line.strip end	
		comp = ComponentGroup.build_rom8x1024(@sim, data)
		
		#reads
		help_test_component_group_case(comp,"0000000000","00000000") 
		help_test_component_group_case(comp,"0000100010","00100010") 
		help_test_component_group_case(comp,"0000100101","00100101") 
		help_test_component_group_case(comp,"0000010110","00010110") 
		help_test_component_group_case(comp,"0000111111","00111111")
		help_test_component_group_case(comp,"0010000000","10000000") 
		help_test_component_group_case(comp,"0001100010","01100010") 
		help_test_component_group_case(comp,"0010100101","10100101") 
		help_test_component_group_case(comp,"0001010110","01010110") 
		help_test_component_group_case(comp,"0010111111","10111111")
	end
	
	def test_counter
		comp = ComponentGroup.build_counter_n(@sim, 8)
		
		help_test_component_group_case(comp, "0000000000","00000000")
		help_test_component_group_case(comp, "0000000000","00000000")
		help_test_component_group_case(comp, "0000000010","00000001")			
		help_test_component_group_case(comp, "0000000010","00000010")			
		help_test_component_group_case(comp, "0000000000","00000010")					
		help_test_component_group_case(comp, "0000000000","00000010")	
		help_test_component_group_case(comp, "0000000010","00000011")	
	end
	
	def test_programcounterjump
		comp = ComponentGroup.build_counter_n(@sim, 8)
		
		help_test_component_group_case(comp, "0000000000","00000000")
		help_test_component_group_case(comp, "0000000000","00000000")
		help_test_component_group_case(comp, "0000000010","00000001")			
		help_test_component_group_case(comp, "0000000010","00000010")
		help_test_component_group_case(comp, "0000000010","00000011")		
		help_test_component_group_case(comp, "0000100011","00001000")
		help_test_component_group_case(comp, "0010100011","00101000")
		help_test_component_group_case(comp, "1110100001","00101000")
		help_test_component_group_case(comp, "0000000010","00101001")
		help_test_component_group_case(comp, "0000000010","00101010")
		help_test_component_group_case(comp, "0000000010","00101011")
	end
	
	def test_microcounter
		comp = ComponentGroup.build_counter_register_n(@sim, 4)
		
		#                           J E Z
		help_test_component_group_case(comp,"0000000","0000")
		help_test_component_group_case(comp,"0000010","0001")
		help_test_component_group_case(comp,"0000010","0010")
		help_test_component_group_case(comp,"0000010","0011")
		help_test_component_group_case(comp,"0000010","0100")
		help_test_component_group_case(comp,"0000010","0101")
		help_test_component_group_case(comp,"0000010","0110")
		help_test_component_group_case(comp,"0000010","0111")			
	end
	
	def test_microcounterjump
		comp = ComponentGroup.build_counter_register_n(@sim, 4)
		
		#                           J E Z
		help_test_component_group_case(comp,"0000000","0000")
		help_test_component_group_case(comp,"0000010","0001")
		help_test_component_group_case(comp,"0000010","0010")
		help_test_component_group_case(comp,"0000110","0000")
		help_test_component_group_case(comp,"0000010","0001")
		help_test_component_group_case(comp,"0000010","0010")
	end
	
	def test_microcounterzero
		comp = ComponentGroup.build_counter_register_n(@sim, 4)
		
		#                           J E Z
		help_test_component_group_case(comp,"0100000","0000")
		help_test_component_group_case(comp,"0100010","0001")
		help_test_component_group_case(comp,"0100010","0010")
		help_test_component_group_case(comp,"0100011","0000")
		help_test_component_group_case(comp,"0100111","0000") # zero overrides jump
		help_test_component_group_case(comp,"0100010","0001")
		help_test_component_group_case(comp,"0100010","0010")
	end	
	
	def test_microcode
		data_in = File.readlines("basic/computer1a.rom").collect do |l| l.strip end
		data_out = File.readlines("basic/computer1b.rom").collect do |l| l.strip end
	
		comp = ComponentGroup.build_microcode(@sim, 6,4,16,data_in, data_out)
	
		# no real tests to be done, but exercise the component
		help_test_component_group_set_inputs(comp, "0000100000")
		(0...16).collect do |n|
			comp.aliased_output(n).output
		end
	end

	def test_alu8
		comp = ComponentGroup.build_alu8(@sim)
		
		help_test_component_group_cases(comp,
			{			
			"00000000000000000" => "00000000",
			"00000001000000000" => "00000001",
			"00000001000000010" => "00000010",
			"10000000000000000" => "10000000",
			"10000000100000000" => "00000000",
			"11111111111111110" => "11111110",
			"00001100000010010" => "00010101",			
			"11000101100111100" => "01100011",			
			"00011000000010001" => "00010000",
			"00000000000000001" => "00000000",			
			"10000000100000001" => "00000000",			
			"10000000010000001" => "01000000",	
			"00000111000000011" => "00000110",
			"00000001000001111" => "11111010"		
			}
		)
	end
	
	def test_alu8_v2
		comp = ComponentGroup.build_alu8_v2(@sim)
		help_test_component_group_cases(comp,
			{	
    		#AAAAAAAABBBBBBBBOOO     #	
			"0000000000000000000" => "00000000", # add 0 + 0
			"0000000100000000000" => "00000001", # add 1 + 0
			"0000000100000001000" => "00000010", # add 1 + 1
			"1000000000000000000" => "10000000", # add 128 + 0
			"1000000010000000000" => "00000000", # add 128 + 128 = 0 w/ overflow
			"1111111111111111000" => "11111110", # add 255 + 255 = 254 w/ overflow
			"0000110000001001000" => "00010101", # add 12 + 9 = 21
			"1100010110011110000" => "01100011", # add 197 + 158 = 355
			"0001100000001000001" => "00010000", # sub 48 - 16 = 32
			"0000000000000000001" => "00000000", # sub 0 - 0 = 0
			"1000000010000000001" => "00000000", # sub 128 - 128 = 0
			"1000000001000000001" => "01000000", # sub 128 - 64 = 64	
			"0000011100000001001" => "00000110", # sub 7 - 1 = 6
			"0000000100000111001" => "11111010", # sub 1 - 7 = -6
			"0011100000001000010" => "00001001", # inc 8 = 9
			"0010110100001001010" => "00001010", # inc 9 = 10
			"0101100000001000011" => "00000111", # dec 8 = 7
			"0010100100001001011" => "00001000", # dec 9 = 8
			"0011100000000000100" => "11000111", # not
			"0010110100000000100" => "11010010", # not
			"0100100001011100101" => "01001000", # and 
			"0010100100011111101" => "00001001", # and 
			"0011100000000000110" => "00111000", # or  
			"0010110110000000110" => "10101101", # or  
			"1101100110000001111" => "01011000", # xor 
			"0010100100100000111" => "00001001"  # xor 
			}
		)
	end
	
	def test_romchip
		comp = RomChip.new(@sim, 4, 4, ["0001","0010","0100","1000"])
		
		help_test_component_group_cases(comp,
			{			
			"00" => "0001",
			"01" => "0010",
			"10" => "0100",
			"11" => "1000"
			}
		)
	end
	# def test_computer		
	# end
	

end
