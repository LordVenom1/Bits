require "test/unit"
require './modern.rb'

class TestSimple < Test::Unit::TestCase

	def help_alu(a,b,s,m,ci,output, msg="", co = nil) # s is high to low...
		c = Circuit.new
		alu = Alu74181.new()
		
		c.add_wire(a[0,1] == "0" ? c.ground : c.power, alu.leads[:a1])
		c.add_wire(a[1,1] == "0" ? c.ground : c.power, alu.leads[:a2])
		c.add_wire(a[2,1] == "0" ? c.ground : c.power, alu.leads[:a3])
		c.add_wire(a[3,1] == "0" ? c.ground : c.power, alu.leads[:a4])
		
		c.add_wire(b[0,1] == "0" ? c.ground : c.power, alu.leads[:b1])
		c.add_wire(b[1,1] == "0" ? c.ground : c.power, alu.leads[:b2])
		c.add_wire(b[2,1] == "0" ? c.ground : c.power, alu.leads[:b3])
		c.add_wire(b[3,1] == "0" ? c.ground : c.power, alu.leads[:b4])
		
		c.add_wire(s[3,1] == "0" ? c.ground : c.power, alu.leads[:s1])
		c.add_wire(s[2,1] == "0" ? c.ground : c.power, alu.leads[:s2])
		c.add_wire(s[1,1] == "0" ? c.ground : c.power, alu.leads[:s3])
		c.add_wire(s[0,1] == "0" ? c.ground : c.power, alu.leads[:s4])
		
		c.add_wire(ci[0,1] == "1" ? c.ground : c.power, alu.leads[:carry_in])
		c.add_wire(m[0,1] == "0" ? c.ground : c.power, alu.leads[:mode])
		
		c.update()
		# puts s
		# puts alu.to_s
		
		assert_equal(output, (alu.leads[:o1].status ? "1" : "0") + (alu.leads[:o2].status ? "1" : "0") + (alu.leads[:o3].status ? "1" : "0") + (alu.leads[:o4].status ? "1" : "0"), msg)
		assert_equal(co, alu.leads[:carry_out].status ? "1" : "0", msg + " carry_out") if co

		# assert_equal(output[0,1] == "1", alu.leads[:o1].status, msg)
		# assert_equal(output[1,1] == "1", alu.leads[:o2].status, msg)
		# assert_equal(output[2,1] == "1", alu.leads[:o3].status, msg)
		# assert_equal(output[3,1] == "1", alu.leads[:o4].status, msg)
		return alu
	end
	
		# help_alu("0110","0000","0000","1","0", "1001") # logic 0000 = Not A
		# #help_alu("0000","0000","1111","0","1", "1000") # arith 1111 = a + 1 # don't know why this is 1110 but matches what i got by hand
		# help_alu("1100","1000","0111","0","0", "0100") # arith 0111 = subtraction.  1100 - 1000 = 0100
		# help_alu("1100","1000","1001","0","0", "0010") # arith 1001 = addition.  1100 + 1000 = 0010 (3+1=4)

	def test_alu_logic_0000	
		# logic
		help_alu("1100","1000","0000","1","0", "0011", "not A")
		help_alu("1100","1000","0001","1","0", "0011", "A nor B")
		help_alu("1100","1000","0010","1","0", "0000", "(not A) and B")
		help_alu("1100","1000","0011","1","0", "0000", "logic 0")
		help_alu("1100","1000","0100","1","0", "0111", "not (a&b)")
		help_alu("1100","1000","0101","1","0", "0111", "not b")
		help_alu("1100","1000","0110","1","0", "0100", "a xor b")
		help_alu("1100","1000","0111","1","0", "0100", "a and (not b)")		
	end
		
	def test_alu_logic_1000
		help_alu("1100","1000","1000","1","0", "1011", "(not a) or b")
	end
	def test_alu_logic_1001
		help_alu("1100","1000","1001","1","0", "1011", "not (a xor b)")
	end	
	def test_alu_logic_1010
		help_alu("1100","1000","1010","1","0", "1000", "b")
	end
	def test_alu_logic_1011
		help_alu("1100","1000","1011","1","0", "1000", "a and b")
	end
	def test_alu_logic_1100
		help_alu("1100","1000","1100","1","0", "1111", "logical 1") #logical 1
	end
	def test_alu_logic_1101
		help_alu("1100","1000","1101","1","0", "1111", "a or (not b)") 
	end
	def test_alu_logic_1110
		help_alu("1100","1000","1110","1","0", "1100", "a or b") 
	end
	def test_alu_logic_1111
		help_alu("1100","1000","1111","1","0", "1100", "a")
	end 
	
	def test_alu_arith
		# arith (carry in 1)
		help_alu("1100","1000","0000","0","0", "1100", "a")
		help_alu("1100","1000","0001","0","0", "1100", "A or B")
		help_alu("1100","1000","0010","0","0", "1111", "A or (not B)")
		help_alu("1100","1000","0011","0","0", "1111", "-1") 
		help_alu("1100","1000","0100","0","0", "1010", "a plus a and (not b)") 
		help_alu("1100","1000","0101","0","0", "1010", "(a or b) plus a and (not b)") 
		help_alu("1100","1000","0110","0","0", "1000", "a - b - 1")
	end
	
	def test_alu_arith_0111		
		help_alu("1110","1010","0111","0","0", "0000", "a and b - 1") # FAIL
	end	
	def test_alu_arith_1000
		help_alu("1100","1000","1000","0","0", "0010", "a + a&b") 
	end	
	def test_alu_arith_1001
		help_alu("1100","1000","1001","0","0", "0010", "a + b") 
	end
	def test_alu_arith_1010 # 15 + 1 = overflow?
		help_alu("1100","1000","1010","0","0", "0000", "(a or not b) + (a&b)") 
	end
	def test_alu_arith_1011
		help_alu("1100","1000","1011","0","0", "0000", "(a&b) - 1") 
	end
	def test_alu_arith_1100
		help_alu("1100","1000","1100","0","0", "0110", "a*2") 
	end
	def test_alu_arith_1101
		help_alu("1100","1000","1101","0","0", "0110", "(a or b) + a") 
	end
	def test_alu_arith_1110 # 15 + 3 = 18...
		help_alu("1100","1000","1110","0","0", "0100", "(a or not b) + a") 
	end
	def test_alu_arith_1000
		help_alu("1100","1000","1111","0","0", "0100", "a - 1") 
	end
	def test_alu_arith_1001
		help_alu("1100","1000","1001","0","0", "0010", "a + b") 
	end
	
	def test_alu_carry
		help_alu("1100","1000","1001","0","0", "0010", "a + b", "0") # 3 + 1 = 4
		help_alu("1100","1010","1001","0","0", "0001", "a + b", "0") # 3 + 5 = 8
		help_alu("1101","1110","1001","0","0", "0100", "a + b", "1") # 11 + 7 = 2 over
	end
	
	def test_equal
		alu = help_alu("1101", "1101", "0110", "0", "1", "0000", "equal")
		assert_equal("1", alu.leads[:equal].status ? "1" : "0", "equal zero")
	end
	
	def test_notequal
		alu = help_alu("1101", "0101", "0110", "0", "1", "1000", "not equal")
		assert_equal("0", alu.leads[:equal].status ? "1" : "0", "not equal zero")
	end
		# arith (carry in 0)
		# help_alu("1100","1000","0000","0","0", "0000", "") 
		# help_alu("1100","1000","0001","0","0", "0000", "") 
		# help_alu("1100","1000","0010","0","0", "0000", "") 
		# help_alu("1100","1000","0011","0","0", "0000", "") 
		# help_alu("1100","1000","0100","0","0", "0000", "") 
		# help_alu("1100","1000","0101","0","0", "0000", "") 
		# help_alu("1100","1000","0110","0","0", "0000", "") 
		# help_alu("1100","1000","0111","0","0", "0000", "") 
		# help_alu("1100","1000","1000","0","0", "0000", "") 
		# help_alu("1100","1000","1001","0","0", "0000", "") 
		# help_alu("1100","1000","1010","0","0", "0000", "") 
		# help_alu("1100","1000","1011","0","0", "0000", "") 
		# help_alu("1100","1000","1100","0","0", "0000", "") 
		# help_alu("1100","1000","1101","0","0", "0000", "") 
		# help_alu("1100","1000","1110","0","0", "0000", "") 
		# help_alu("1100","1000","1111","0","0", "0000", "") 		
	


	def test_intr_not_double
		c = Circuit.new
		n1 = NotGate.new()
		n2 = NotGate.new()		
		l = Led.new(:out)
		c.add_wire(c.power, n1.leads[:in])
		c.add_wire(n1.leads[:out], n2.leads[:in])		
		c.add_wire(n2.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(true, l.leads[:out].status)
	end
	
	def help_rom(s,o)
		c = Circuit.new	
		inst_set = Memory.new(128,16)		
		rc_0 = File.read("microcode_0.bin")[0,128].unpack("b8"*128)		
		rc_1 = File.read("microcode_1.bin")[0,128].unpack("b8"*128)		
		rom_code = []		
		(0...128).each do |idx|
			full = (rc_0.shift + rc_1.shift).reverse
			rom_code[idx.to_s(2).rjust(8,"0").reverse.to_i(2)] = full
		end
		inst_set.import(rom_code.join(""))
		
		c.add_wire(s[0,1] == "0" ? c.ground : c.power, inst_set.leads[:s1])
		c.add_wire(s[1,1] == "0" ? c.ground : c.power, inst_set.leads[:s2])
		c.add_wire(s[2,1] == "0" ? c.ground : c.power, inst_set.leads[:s3])
		c.add_wire(s[3,1] == "0" ? c.ground : c.power, inst_set.leads[:s4])
		c.add_wire(s[4,1] == "0" ? c.ground : c.power, inst_set.leads[:s5])
		c.add_wire(s[5,1] == "0" ? c.ground : c.power, inst_set.leads[:s6])
		c.add_wire(s[6,1] == "0" ? c.ground : c.power, inst_set.leads[:s7])		
		
		c.update
		r = (1..16).collect do |idx|
			inst_set.leads[("o" + idx.to_s).to_sym].status ? "1" : "0"
		end.join("")
		
		assert_equal(o,r,s)
	end
	
	def test_rom
		help_rom("0000000", "1111100000110111")
		help_rom("0100001", "0100011010111101")
	end

	def help_alu8(a,b,s,m,ci,output, msg="", co = nil)
		c = Circuit.new
		alu = Alu8.new()
		c.add_wire(a[0,1] == "0" ? c.ground : c.power, alu.leads[:a1])
		c.add_wire(a[1,1] == "0" ? c.ground : c.power, alu.leads[:a2])
		c.add_wire(a[2,1] == "0" ? c.ground : c.power, alu.leads[:a3])
		c.add_wire(a[3,1] == "0" ? c.ground : c.power, alu.leads[:a4])
		c.add_wire(a[4,1] == "0" ? c.ground : c.power, alu.leads[:a5])
		c.add_wire(a[5,1] == "0" ? c.ground : c.power, alu.leads[:a6])
		c.add_wire(a[6,1] == "0" ? c.ground : c.power, alu.leads[:a7])
		c.add_wire(a[7,1] == "0" ? c.ground : c.power, alu.leads[:a8])
		
		c.add_wire(b[0,1] == "0" ? c.ground : c.power, alu.leads[:b1])
		c.add_wire(b[1,1] == "0" ? c.ground : c.power, alu.leads[:b2])
		c.add_wire(b[2,1] == "0" ? c.ground : c.power, alu.leads[:b3])
		c.add_wire(b[3,1] == "0" ? c.ground : c.power, alu.leads[:b4])
		c.add_wire(b[4,1] == "0" ? c.ground : c.power, alu.leads[:b5])
		c.add_wire(b[5,1] == "0" ? c.ground : c.power, alu.leads[:b6])
		c.add_wire(b[6,1] == "0" ? c.ground : c.power, alu.leads[:b7])
		c.add_wire(b[7,1] == "0" ? c.ground : c.power, alu.leads[:b8])
		
		c.add_wire(s[3,1] == "0" ? c.ground : c.power, alu.leads[:s1])
		c.add_wire(s[2,1] == "0" ? c.ground : c.power, alu.leads[:s2])
		c.add_wire(s[1,1] == "0" ? c.ground : c.power, alu.leads[:s3])
		c.add_wire(s[0,1] == "0" ? c.ground : c.power, alu.leads[:s4])
		
		c.add_wire(ci[0,1] == "1" ? c.ground : c.power, alu.leads[:carry_in])
		c.add_wire(m[0,1] == "0" ? c.ground : c.power, alu.leads[:mode])
		
		c.update()
		# puts s
		# puts alu.to_s

		assert_equal(output, (alu.leads[:o1].status ? "1" : "0") + (alu.leads[:o2].status ? "1" : "0") + (alu.leads[:o3].status ? "1" : "0") + (alu.leads[:o4].status ? "1" : "0") +
							 (alu.leads[:o5].status ? "1" : "0") + (alu.leads[:o6].status ? "1" : "0") + (alu.leads[:o7].status ? "1" : "0") + (alu.leads[:o8].status ? "1" : "0"), msg)
		assert_equal(co, alu.leads[:carry_out].status ? "1" : "0", msg + " carry_out") if co

	end
	
	def test_alu8_1
		##        "12486248"  "12486248"                    "12486248" 
		help_alu8("00000100", "10000100", "1001", "0", "0", "10000010","32+32=64","0") # 32+32 = 64
	end 
	def test_alu8_2
		help_alu8("11010000", "10100000", "1001", "0", "0", "00001000","11+5=16","0") # 11 + 5 = 16
	end
	def test_alu8_3
		help_alu("1000", "1000", "1001", "0", "0", "0100","1+1=2","0")
		help_alu("1101", "1010", "1001", "0", "0", "0000","11+5=16","1") # 11 + 6 = 0 w/ carry out
		help_alu("1101", "0010", "1001", "0", "0", "1111","11+4=15","0") # 11 + 4 = 15 w/ no carry out FAIL
		help_alu8("11010000", "00100000", "1001", "0", "0", "11110000","11+4=15","0") # 11 + 4 = 15
		#help_alu8("11100000", "11000010", "1001", "0", "0", "01010010","11+4=15","0") # 7 + 67 = 74			
	end	
	def test_alu8_4
		help_alu8("00000000", "00000000", "1001", "0", "0", "00000000","0+0=0","0") # 0+0=0
	end
	def test_alu8_5
		help_alu8("00010000", "00010000", "1001", "0", "0", "00001000","8+8=16","0") # 8+8=16
	end
	def test_alu8_6
		help_alu8("01111000", "10110100", "1001", "0", "0", "11010010","30+45=75","0") # 30+45=75
	end
	
	def test_intr_not_triple
		c = Circuit.new
		n1 = NotGate.new()
		n2 = NotGate.new()
		n3 = NotGate.new()
		l = Led.new(:out)
		c.add_wire(c.power, n1.leads[:in])
		c.add_wire(n1.leads[:out], n2.leads[:in])
		c.add_wire(n2.leads[:out], n3.leads[:in])
		c.add_wire(n3.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(false, l.leads[:out].status)
	end
	
	def test_and_true
		c = Circuit.new
		a = AndGate.new()
		l = Led.new(:out)
		c.add_wire(c.power, a.leads[:i1])
		c.add_wire(c.power, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(true, l.leads[:out].status)
	end

	def test_and_false_a
		c = Circuit.new
		a = AndGate.new()
		l = Led.new(:out)
		c.add_wire(c.power, a.leads[:i1])
		c.add_wire(c.ground, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(false, l.leads[:out].status)
	end	
	
	def test_and_false_b
		c = Circuit.new
		a = AndGate.new()
		l = Led.new(:out)
		c.add_wire(c.ground, a.leads[:i1])
		c.add_wire(c.power, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(false, l.leads[:out].status)
	end		
	
	def test_and_false_both
		c = Circuit.new
		a = AndGate.new()
		l = Led.new(:out)
		c.add_wire(c.ground, a.leads[:i1])
		c.add_wire(c.ground, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(false, l.leads[:out].status)
	end	
	
	def test_nand_true
		c = Circuit.new
		a = NandGate.new()
		l = Led.new(:out)
		c.add_wire(c.power, a.leads[:i1])
		c.add_wire(c.power, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(false, l.leads[:out].status)
	end

	def test_nand_false_a
		c = Circuit.new
		a = NandGate.new()
		l = Led.new(:out)
		c.add_wire(c.power, a.leads[:i1])
		c.add_wire(c.ground, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(true, l.leads[:out].status)
	end	
	
	def test_nand_false_b
		c = Circuit.new
		a = NandGate.new()
		l = Led.new(:out)
		c.add_wire(c.ground, a.leads[:i1])
		c.add_wire(c.power, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(true, l.leads[:out].status)
	end		
	
	def test_nand_false_both
		c = Circuit.new
		a = NandGate.new()
		l = Led.new(:out)
		c.add_wire(c.ground, a.leads[:i1])
		c.add_wire(c.ground, a.leads[:i2])
		c.add_wire(a.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(true, l.leads[:out].status)
	end	
	
	def test_or_1
		c = Circuit.new
		o = OrGate.new()
		l = Led.new(:out)
		c.add_wire(c.power, o.leads[:i1])
		c.add_wire(c.ground, o.leads[:i2])
		c.add_wire(o.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(true, l.leads[:out].status)
	end
	
	def test_or_2
		c = Circuit.new
		o = OrGate.new()
		l = Led.new(:out)
		c.add_wire(c.ground, o.leads[:i1])
		c.add_wire(c.ground, o.leads[:i2])
		c.add_wire(o.leads[:out], l.leads[:in])
		c.add_wire(l.leads[:out], c.ground)
		c.update
		assert_equal(false, l.leads[:out].status)
	end	
	
	# def test_multi4
		# c = Circuit.new
		# m = Multiplexer.new(2)
		# l = Led.new(:out)
	# end
	
	def test_log
		assert_equal(2, Math::log2(4))
		assert_equal(3, Math::log2(8))
		assert_equal(4, Math::log2(16))
		assert_equal(5, Math::log2(32))
	end
	
	def help_mux4(input, value)
		c = Circuit.new
		m = Multiplexer.new(4)
				
		c.add_wire(input[0,1] == "0" ? c.ground : c.power, m.leads[:s1])
		c.add_wire(input[1,1] == "0" ? c.ground : c.power, m.leads[:s2])
		c.add_wire(input[2,1] == "0" ? c.ground : c.power, m.leads[:i1])
		c.add_wire(input[3,1] == "0" ? c.ground : c.power, m.leads[:i2])
		c.add_wire(input[4,1] == "0" ? c.ground : c.power, m.leads[:i3])
		c.add_wire(input[5,1] == "0" ? c.ground : c.power, m.leads[:i4])
		c.update
		
		assert_equal(value, m.leads[:out].status)
	end
	
	def help_demux4(input, output) # "ssd", "1234"
		c = Circuit.new
		d = Demultiplexer.new(4)
				
		c.add_wire(input[0,1] == "0" ? c.ground : c.power, d.leads[:s1])
		c.add_wire(input[1,1] == "0" ? c.ground : c.power, d.leads[:s2])
		c.add_wire(input[2,1] == "0" ? c.ground : c.power, d.leads[:in])
		c.update()
		
		# puts input, output
		# puts d.to_s
		
		assert_equal(output[0,1] == "1", d.leads[:o1].status)
		assert_equal(output[1,1] == "1", d.leads[:o2].status)
		assert_equal(output[2,1] == "1", d.leads[:o3].status)
		assert_equal(output[3,1] == "1", d.leads[:o4].status)
	end
	
	def test_multi4
		help_mux4("001000", true)
		help_mux4("000111", false)
		help_mux4("100100", true)
		help_mux4("101011", false)
		help_mux4("010010", true)
		help_mux4("011101", false)		
		help_mux4("110001", true)
		help_mux4("111110", false)		
	end
	
	def test_demux4
		help_demux4("000", "0000")
		help_demux4("001", "1000")
		help_demux4("100", "0000")
		help_demux4("101", "0100")
		help_demux4("010", "0000")
		help_demux4("011", "0010")
		help_demux4("110", "0000")
		help_demux4("111", "0001")
	end
	
	def test_clock
		c = Circuit.new
		ps = PowerSwitch.new()
		d = DFlipFlop.new()
		l = Led.new(:output)
		
		ps_sto = PowerSwitch.new()
		c.add_wire(ps_sto.leads[:out], d.leads[:store])			
		c.add_wire(ps.leads[:out], d.leads[:in])
		c.add_wire(d.leads[:out], l.leads[:in])
		c.update()
		c.clock.tick()
		c.update()

		assert_equal(false,l.leads[:out].status)

		c.update()		
		c.clock.tick()
		c.update()
		
		assert_equal(false,l.leads[:out].status)
		
		ps.on!
		c.update()				
		c.clock.tick()
		c.update()
		
		assert_equal(false,l.leads[:out].status)

		ps_sto.on!
		c.update()		
		c.clock.tick()
		c.update()
		
		assert_equal(true,l.leads[:out].status)
		
	end
	
	def test_switch
		c = Circuit.new()
		s = Switch.new(2,4)
		ps = PowerSwitch.new()
		c.add_wire(c.power, s.leads[:i11])
		c.add_wire(c.power, s.leads[:i12])
		c.add_wire(c.ground, s.leads[:i13])
		c.add_wire(c.ground, s.leads[:i14])
		c.add_wire(c.power, s.leads[:i21])
		c.add_wire(c.ground, s.leads[:i22])
		c.add_wire(c.power, s.leads[:i23])
		c.add_wire(c.power, s.leads[:i24])
		c.add_wire(ps.leads[:out], s.leads[:s1])
		ps.off!
		c.update()
		
		assert_equal(true,s.leads[:o1].status)
		assert_equal(true,s.leads[:o2].status)
		assert_equal(false,s.leads[:o3].status)
		assert_equal(false,s.leads[:o4].status)
		
		ps.on!
		c.update()
		
		assert_equal(true,s.leads[:o1].status)
		assert_equal(false,s.leads[:o2].status)
		assert_equal(true,s.leads[:o3].status)
		assert_equal(true,s.leads[:o4].status)
		
	end
	
	def test_register
		c = Circuit.new()
		r = Register.new(6)
		
		ps = PowerSwitch.new()
		
		c.add_wire(ps.leads[:out], r.leads[:store])
		
		c.add_wire(c.power, r.leads[:i1])
		c.add_wire(c.ground, r.leads[:i2])
		c.add_wire(c.power, r.leads[:i3])
		c.add_wire(c.ground, r.leads[:i4])
		c.add_wire(c.power, r.leads[:i5])
		c.add_wire(c.ground, r.leads[:i6])
		
		c.update()
		c.clock.tick()
		c.update()
		
		# r.display
		
		assert_equal(false, r.leads[:o1].status)
		assert_equal(false, r.leads[:o2].status)
		assert_equal(false, r.leads[:o3].status)
		assert_equal(false, r.leads[:o4].status)
		assert_equal(false, r.leads[:o5].status)
		assert_equal(false, r.leads[:o6].status)
		
		ps.on!
		
		c.update()
		c.clock.tick()
		c.update()
		
		# r.display
		
		assert_equal(true, r.leads[:o1].status)
		assert_equal(false, r.leads[:o2].status)
		assert_equal(true, r.leads[:o3].status)
		assert_equal(false, r.leads[:o4].status)
		assert_equal(true, r.leads[:o5].status)
		assert_equal(false, r.leads[:o6].status)
		
	end
		
	def test_memory		
	
		c = Circuit.new
		mem = Memory.new(4,2)
		
		ps_s1 = PowerSwitch.new()
		ps_s2 = PowerSwitch.new()		
		ps_sto = PowerSwitch.new()
		
		ps_d1 = PowerSwitch.new()
		ps_d2 = PowerSwitch.new()
				
		c.add_wire(ps_s1.leads[:out], mem.leads[:s1])
		c.add_wire(ps_s2.leads[:out], mem.leads[:s2])		
		c.add_wire(ps_sto.leads[:out], mem.leads[:store])
		
		c.add_wire(c.power, mem.leads[:i1])
		c.add_wire(c.power, mem.leads[:i2])
		
		c.add_wire(ps_d1.leads[:out], mem.leads[:i1])
		c.add_wire(ps_d2.leads[:out], mem.leads[:i2])		

		ps_s1.off!
		ps_s2.off!
		ps_d1.on!
		ps_d2.off!
		ps_sto.on!
				
		
		c.update
		c.clock.tick
		c.update				
		
		# mem.display
				
		assert_equal(true, mem.leads[:o1].status)
		assert_equal(false,mem.leads[:o2].status)
		
				
	end
	
	def test_xor
		c = Circuit.new
		x = XorGate.new(3)
		c.add_wire(c.power, x.leads[:i1])
		c.add_wire(c.power, x.leads[:i2])
		c.add_wire(c.power, x.leads[:i3])
		c.update		
		assert_equal(true, x.leads[:out].status)
		
		x = XorGate.new(3)
		c.add_wire(c.power, x.leads[:i1])
		c.add_wire(c.ground, x.leads[:i2])
		c.add_wire(c.power, x.leads[:i3])
		c.update		
		assert_equal(false, x.leads[:out].status)
	end
	
	def test_adder
		c = Circuit.new
		a = Adder.new(4)
		
		c.add_wire(c.ground, a.leads[:carry_in])
		c.add_wire(c.power, a.leads[:a1])
		c.add_wire(c.power, a.leads[:a2])
		c.add_wire(c.ground, a.leads[:a3])
		c.add_wire(c.ground, a.leads[:a4])
		
		c.add_wire(c.ground, a.leads[:b1])
		c.add_wire(c.power, a.leads[:b2])
		c.add_wire(c.ground, a.leads[:b3])
		c.add_wire(c.ground, a.leads[:b4])
		
		c.update	
		
		# puts
		# print a.leads[:a1].to_s + a.leads[:a2].to_s + a.leads[:a3].to_s + a.leads[:a4].to_s
		# puts
		# print a.leads[:b1].to_s + a.leads[:b2].to_s + a.leads[:b3].to_s + a.leads[:b4].to_s
		# puts
		# print a.leads[:o1].to_s + a.leads[:o2].to_s + a.leads[:o3].to_s + a.leads[:o4].to_s
		# puts
		
		assert_equal(true, a.leads[:o1].status)
		assert_equal(false, a.leads[:o2].status)
		assert_equal(true, a.leads[:o3].status)
		assert_equal(false, a.leads[:o4].status)
		assert_equal(false, a.leads[:carry].status)
		
	end
	
	# def test_alu_bitwise_and
		# c = Circuit.new()
		# alu = Alu.new(4)
		
		# c.add_wire(c.ground, alu.leads[:s1])
		# c.add_wire(c.ground, alu.leads[:s2])
		# c.add_wire(c.ground, alu.leads[:s3])
		
		# c.add_wire(c.power, alu.leads[:a1])
		# c.add_wire(c.power, alu.leads[:b1])
		# c.add_wire(c.power, alu.leads[:a2])
		# c.add_wire(c.ground, alu.leads[:b2])		
		# c.add_wire(c.power, alu.leads[:a3])
		# c.add_wire(c.power, alu.leads[:b3])
		# c.update
		
		# assert_equal(true, alu.leads[:o1].status)
		# assert_equal(false, alu.leads[:o2].status)		
		# assert_equal(true, alu.leads[:o3].status)		
	# end
	
	# def test_alu_bitwise_or
		# c = Circuit.new()
		# alu = Alu.new(4)
		
		# c.add_wire(c.power, alu.leads[:s1])
		# c.add_wire(c.ground, alu.leads[:s2])
		# c.add_wire(c.ground, alu.leads[:s3])
		
		# c.add_wire(c.power, alu.leads[:a1])
		# c.add_wire(c.power, alu.leads[:b1])
		# c.add_wire(c.power, alu.leads[:a2])
		# c.add_wire(c.ground, alu.leads[:b2])		
		# c.add_wire(c.power, alu.leads[:a3])
		# c.add_wire(c.power, alu.leads[:b3])
		# c.add_wire(c.ground, alu.leads[:a4])
		# c.add_wire(c.ground, alu.leads[:b4])
		# c.update
		
		# assert_equal(true, alu.leads[:o1].status)
		# assert_equal(true, alu.leads[:o2].status)		
		# assert_equal(true, alu.leads[:o3].status)		
		# assert_equal(false, alu.leads[:o4].status)	
	# end
	
	# def test_alu_bitwise_add_1_2
		# c = Circuit.new()
		# alu = Alu.new(4)
		
		# c.add_wire(c.ground, alu.leads[:s1])
		# c.add_wire(c.power,  alu.leads[:s2])
		# c.add_wire(c.ground, alu.leads[:s3])
		
		# c.add_wire(c.power,  alu.leads[:a1]); c.add_wire(c.ground, alu.leads[:b1])
		# c.add_wire(c.ground, alu.leads[:a2]); c.add_wire(c.power,  alu.leads[:b2])		
		# c.add_wire(c.ground, alu.leads[:a3]); c.add_wire(c.ground, alu.leads[:b3])
		# c.add_wire(c.ground, alu.leads[:a4]); c.add_wire(c.ground, alu.leads[:b4])
		# c.update
		
		# assert_equal(true, alu.leads[:o1].status)
		# assert_equal(true, alu.leads[:o2].status)		
		# assert_equal(false, alu.leads[:o3].status)		
		# assert_equal(false, alu.leads[:o4].status)	
	# end
	
	# def test_alu_bitwise_add_3_3
		# c = Circuit.new()
		# alu = Alu.new(4)
		
		# c.add_wire(c.ground, alu.leads[:s1])
		# c.add_wire(c.power,  alu.leads[:s2])
		# c.add_wire(c.ground, alu.leads[:s3])
		
		# c.add_wire(c.power,  alu.leads[:a1]); c.add_wire(c.power, alu.leads[:b1])
		# c.add_wire(c.power, alu.leads[:a2]); c.add_wire(c.power,  alu.leads[:b2])		
		# c.add_wire(c.ground, alu.leads[:a3]); c.add_wire(c.ground, alu.leads[:b3])
		# c.add_wire(c.ground, alu.leads[:a4]); c.add_wire(c.ground, alu.leads[:b4])
		# c.update
		
		# assert_equal(false, alu.leads[:o1].status)
		# assert_equal(true, alu.leads[:o2].status)		
		# assert_equal(true, alu.leads[:o3].status)		
		# assert_equal(false, alu.leads[:o4].status)	
	# end
	
	# def test_alu_bitwise_add_9_8
		# c = Circuit.new()
		# alu = Alu.new(4)
		
		# c.add_wire(c.ground, alu.leads[:s1])
		# c.add_wire(c.power,  alu.leads[:s2])
		# c.add_wire(c.ground, alu.leads[:s3])
		
		# c.add_wire(c.power,  alu.leads[:a1]); c.add_wire(c.ground, alu.leads[:b1])
		# c.add_wire(c.ground, alu.leads[:a2]); c.add_wire(c.ground,  alu.leads[:b2])		
		# c.add_wire(c.ground, alu.leads[:a3]); c.add_wire(c.ground, alu.leads[:b3])
		# c.add_wire(c.power, alu.leads[:a4]); c.add_wire(c.power, alu.leads[:b4])
		# c.update
		
		# assert_equal(true,  alu.leads[:o1].status)
		# assert_equal(false, alu.leads[:o2].status)		
		# assert_equal(false, alu.leads[:o3].status)		
		# assert_equal(false, alu.leads[:o4].status)	
		# assert_equal(true, alu.leads[:carry_out].status)
	# end
	
	# def test_alu_bitwise_sub_9_8
		# c = Circuit.new()
		# alu = Alu.new(4)
		
		# c.add_wire(c.power, alu.leads[:s1])
		# c.add_wire(c.power,  alu.leads[:s2])
		# c.add_wire(c.ground, alu.leads[:s3])
		
		# c.add_wire(c.power,  alu.leads[:a1]); c.add_wire(c.ground, alu.leads[:b1])
		# c.add_wire(c.ground, alu.leads[:a2]); c.add_wire(c.ground,  alu.leads[:b2])		
		# c.add_wire(c.ground, alu.leads[:a3]); c.add_wire(c.ground, alu.leads[:b3])
		# c.add_wire(c.power, alu.leads[:a4]); c.add_wire(c.power, alu.leads[:b4])
		# c.update
		
		# assert_equal(true,  alu.leads[:o1].status)
		# assert_equal(false, alu.leads[:o2].status)		
		# assert_equal(false, alu.leads[:o3].status)		
		# assert_equal(false, alu.leads[:o4].status)	
		# # assert_equal(true, alu.leads[:carry_out].status)
	# end
	
	# def test_alu_bitwise_sub_5_11
		# c = Circuit.new()
		# alu = Alu.new(4)
		
		# c.add_wire(c.power, alu.leads[:s1])
		# c.add_wire(c.power,  alu.leads[:s2])
		# c.add_wire(c.ground, alu.leads[:s3])
		
		# c.add_wire(c.power,  alu.leads[:a1]); c.add_wire(c.power,  alu.leads[:b1])
		# c.add_wire(c.ground, alu.leads[:a2]); c.add_wire(c.power,  alu.leads[:b2])		
		# c.add_wire(c.power,  alu.leads[:a3]); c.add_wire(c.ground, alu.leads[:b3])
		# c.add_wire(c.ground, alu.leads[:a4]); c.add_wire(c.power,  alu.leads[:b4])
		# c.update
		
		# # (1..4).each do |idx|
			# # puts alu.leads[("o" + idx.to_s).to_sym]
		# # end
		
		# assert_equal(false, alu.leads[:o1].status)
		# assert_equal(true,  alu.leads[:o2].status)		
		# assert_equal(false, alu.leads[:o3].status)		
		# assert_equal(true,  alu.leads[:o4].status)	
		# # assert_equal(true, alu.leads[:carry_out].status)
	# end
	
	def teardown
	end
end
