require_relative '../simulation.rb'
require_relative 'language.rb'

$stdout.sync = true

###########################################################################################
# load the specfied program, then simulate the computer until a HLT is loaded into the IR #
###########################################################################################

# this is a computer modeled after the "simple as possible (SAP) 2" described in 
# Digital Computer Electronics 3d edition by Malvino, Brown, starting page 173
class ComputerSAP2
	
	def initialize(program)
		@sim = Simulation.new()
		
		#internal components
		@bus = ComponentGroup.build_bus8x8(@sim)
		@sim.show_gate_count("bus")
		@mar = ComponentGroup.build_register_n(@sim, 8)
		@sim.show_gate_count("mar")
		@ram = ComponentGroup.build_ram_n_m(@sim, 8, 256, :high, program)
		@sim.show_gate_count("ram")
		@pc = ComponentGroup.build_counter_register_n(@sim, 8)
		@sim.show_gate_count("pc")
		@a = ComponentGroup.build_register_n(@sim, 8)
		@sim.show_gate_count("a")
		@b = ComponentGroup.build_register_n(@sim, 8)
		@sim.show_gate_count("b")
		@c = ComponentGroup.build_register_n(@sim, 8)
		@sim.show_gate_count("c")
		@tmp = ComponentGroup.build_register_n(@sim, 8)
		@sim.show_gate_count("tmp")
		@alu = ComponentGroup.build_alu8_v2(@sim)
		@sim.show_gate_count("alu")
		@out = ComponentGroup.build_register_n(@sim, 8)		
		@sim.show_gate_count("out")
		@ir = ComponentGroup.build_register_n(@sim, 8)
		@sim.show_gate_count("ir")
		flag_zero = ComponentGroup.build_nor_n_gate(@sim, 8)		
		@flags = ComponentGroup.build_register_n(@sim, 3)
		@sim.show_gate_count("flags")
		
		microcode = File.readlines("sap2.rom").collect do |l| l.strip end
		@m_inst = RomChip.new(@sim, MC_INST_WIDTH, 4096, microcode)
		@m_cntr = ComponentGroup.build_counter_register_n(@sim, 4, :low) # 6-bit ring counter?
		@sim.show_gate_count("m_cntr")		
		
		#internal wiring		
		# setup bus "outputs": determine which component gets to write to the bus on this cycle
		(0...8).each do |idx| @bus.set_aliased_input(0 + idx, @pc.aliased_output(idx)) end				
		(0...8).each do |idx| @bus.set_aliased_input(8 + idx, @ram.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(16 + idx, @ir.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(24 + idx, @a.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(32 + idx, @alu.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(40 + idx, @b.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(48 + idx, @c.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(56 + idx, Simulation::FALSE) end	

		@bus.set_aliased_input(64 + 0, @m_inst.aliased_output(1))  # pc write to bus
		@bus.set_aliased_input(64 + 1, @m_inst.aliased_output(5))  # ram write to bus
		@bus.set_aliased_input(64 + 2, @m_inst.aliased_output(7))  # ir write to bus
		@bus.set_aliased_input(64 + 3, @m_inst.aliased_output(9))  # a write to bus
		@bus.set_aliased_input(64 + 4, @m_inst.aliased_output(16))  # alu write to bus		
		@bus.set_aliased_input(64 + 5, @m_inst.aliased_output(11))  # b write to bus
		@bus.set_aliased_input(64 + 6, @m_inst.aliased_output(13)) # c write to bus
		@bus.set_aliased_input(64 + 7, Simulation::FALSE) #unused		
		
		# connect components to input registers from bus. 
		# doesn't do anything unless these components have their load signals set
		(0...8).each do |idx|
			@a.set_aliased_input(idx,   @bus.aliased_output(idx))
			@b.set_aliased_input(idx,   @bus.aliased_output(idx))
			@c.set_aliased_input(idx,   @bus.aliased_output(idx))
			@tmp.set_aliased_input(idx, @bus.aliased_output(idx))
			@out.set_aliased_input(idx, @bus.aliased_output(idx))
			@ir.set_aliased_input(idx,  @bus.aliased_output(idx))							
			@ram.set_aliased_input(idx, @bus.aliased_output(idx))	
			@mar.set_aliased_input(idx, @bus.aliased_output(idx))
			@pc.set_aliased_input(idx,  @bus.aliased_output(idx))
		end
		
		# set control signals
		@pc.set_aliased_input(8,   @m_inst.aliased_output(1)) # pc jump
		@pc.set_aliased_input(9,   @m_inst.aliased_output(0)) # pc increment
		@pc.set_aliased_input(10,  Simulation::FALSE)         # pc zero
		@mar.set_aliased_input(8,  @m_inst.aliased_output(3)) # mar load from bus
		@ram.set_aliased_input(16, @m_inst.aliased_output(4)) # ram load from bus
		@ir.set_aliased_input(8,   @m_inst.aliased_output(6)) # ir load from bus
		@a.set_aliased_input(8,    @m_inst.aliased_output(8)) # a load from bus
		@b.set_aliased_input(8,    @m_inst.aliased_output(10))# b load from bus
		@c.set_aliased_input(8,    @m_inst.aliased_output(12))# c load from bus
		@out.set_aliased_input(8,  @m_inst.aliased_output(14))# out load from bus
		@tmp.set_aliased_input(8,  @m_inst.aliased_output(15))# tmp load from bus
		@alu.set_aliased_input(16, @m_inst.aliased_output(17))# alu operator
		@alu.set_aliased_input(17, @m_inst.aliased_output(18))# alu operator
		@alu.set_aliased_input(18, @m_inst.aliased_output(19))# alu operator
		
		# mc early reset, described on pg 163
		@mc_reset = ComponentGroup.build_nor_n_gate(@sim, MC_INST_WIDTH)		
		(0...MC_INST_WIDTH).each do |idx|
			@mc_reset.set_aliased_input(idx, @m_inst.aliased_output(idx))
		end
		
		# wire cntr jump to microinst 8
		(0...4).each do |idx|
			@m_cntr.set_aliased_input(idx, idx == 0 ? Simulation::TRUE : Simulation::FALSE)
		end
	
		# Handle Jump for JNE instruction		
		@mc_jump = ComponentGroup.build_compareset(@sim, "1100001000101")	
		
		#setup microcode counter control		
		@m_cntr.set_aliased_input(4, @mc_jump.aliased_output(0))      #jump
		@m_cntr.set_aliased_input(5, Simulation::TRUE)            #enable
		@m_cntr.set_aliased_input(6, @mc_reset.aliased_output(0)) #zero		
		
		# ALU inputs are A and TMP regs
		(0...8).each do |idx|
			@alu.set_aliased_input(idx, @a.aliased_output(idx))
			@alu.set_aliased_input(8 + idx, @tmp.aliased_output(idx))
		end	
		
		# connect MAR to RAM address
		(0...8).each do |idx|
			@ram.set_aliased_input(8 + idx, @mar.aliased_output(idx))
		end	
		
		# 8-bits in IR is the op-code
		(0...8).each do |idx|
			@m_inst.set_aliased_input(idx, @ir.aliased_output(idx))
			@mc_jump.set_aliased_input(idx, @ir.aliased_output(idx))
		end
		# pass micro loop counter into micro instruction
		(0...4).each do |idx| 
			@m_inst.set_aliased_input(8 + idx, @m_cntr.aliased_output(idx)) 
			@mc_jump.set_aliased_input(8 + idx, @m_cntr.aliased_output(idx))
		end
		@mc_jump.set_aliased_input(12, @flags.aliased_output(0))
		
		# flags
		(0...8).each do |idx|
			flag_zero.set_aliased_input(idx, @alu.aliased_output(idx))
		end
		@flags.set_aliased_input(0, flag_zero.aliased_output(0))
		@flags.set_aliased_input(1, @alu.aliased_output(8))
		@flags.set_aliased_input(2, @alu.aliased_output(0)) # MSB is sign bit
		@flags.set_aliased_input(3, @m_inst.aliased_output(16)) # save flags on alu write
		
		
		print "Computer setup is complete.  Press enter to start processing." if DEBUG
		STDIN.gets if DEBUG
		
	end
	
	def reg_decimal(reg)
		bin = (reg.outputs.collect do |o| o.output() ? '1' : '0'  end).join("")
		bin.to_i(2).to_s()
	end
	
	def reg_format(reg, decode = false)
		bin = (reg.outputs.collect do |o| o.output() ? '1' : '0'  end).join("")
		decode ? "#{bin} (#{bin.to_i(2).to_s().center(3,' ')})" : bin
	end	
	
	def cntr(idx)
		@m_inst.aliased_output(idx).output
	end
	
	def alu_op(c)
		case c
			when "000"
				"ADD"
			when "001"
				"SUB"
			when "010"
				"INC"
			when "011"
				"DEC"
			when "100"
				"NOT"
			when "101"
				"AND"
			when "110"
				"OR "
			when "111"
				"XOR"
		end
	end
	
	def format_flags
		f = reg_format(@flags)
		#"Z:#{f[0]} OF:#{f[1]} N:#{f[2]}"
		"Z:#{f[0]}"
	end
	
	def format_alu()		
		bin = (@alu.outputs[0,8].collect do |o| o.output() ? '1' : '0'  end).join("")
		"#{bin} (#{bin.to_i(2).to_s().center(3,' ')})"
	end
	
	def format_ir()
		o = reg_format(@ir)
		
		Operand::all.each do |op|
			if (o == op.decode_addr)				
				return o + " (#{op.opcode})"
			end
		end
		
		return o + "(UNKNOWN)"		
	end
	
	def display()
		system("clear") || system("cls") 
		puts "=================================="
		puts "          C O M P U T E R       "
		puts "=================================="
		c = reg_format(@m_inst)
		
		puts "  A#{(cntr(8) ? '*' : ' ')}: " + reg_format(@a,true) + "      B#{(cntr(10) ? '*' : ' ')}: " + reg_format(@b,true)
		puts "  C#{(cntr(12) ? '*' : ' ')}: " + reg_format(@c,true) + "    TMP#{(cntr(15) ? '*' : ' ')}: " + reg_format(@tmp,true)
		puts "ALU : #{format_alu}  Flags : #{format_flags}"				
		puts ""
		puts "MAR#{(cntr(3) ? '*' : ' ')}: " + reg_format(@mar,true) + " -> RAM : " + reg_format(@ram,true)
		puts ""
		puts "BUS : " + reg_format(@bus, true)		
		puts ""
		puts "PC#{(cntr(0) ? '+' : ' ')} : " + reg_format(@pc, true) 
		puts "IR#{(cntr(6) ? '*' : ' ')} : " + format_ir + " cnt " + reg_format(@m_cntr)		
		puts
		puts "Microcode Instruction ROM output:"
		puts "      "
		puts "   PC Jump: #{c[1]}   PC Write: #{c[2]}"
		puts "  MAR Load: #{c[3]}     PC Inc: #{c[0]}"
		puts "  RAM Load: #{c[4]}  RAM Write: #{c[5]}"
		puts "   IR Load: #{c[6]}   IR Write: #{c[7]}"
		puts "    A Load: #{c[8]}    A Write: #{c[9]}"
		puts "    B Load: #{c[10]}    B Write: #{c[11]}"
		puts "    C Load: #{c[12]}    C Write: #{c[13]}"
		puts "  OUT Load: #{c[14]}   TMP Load: #{c[15]}"
		puts " ALU Write: #{c[16]}     ALU Op: #{c[17,3]} #{alu_op(c[17,3])}"		
	end
	
	def run()
	
		display() if DEBUG	
		STDIN.gets if DEBUG
		
		while true do 						
			@sim.update(:low)
			display() if DEBUG				
			@sim.update(:high)
			
			puts "OUTPUT: #{reg_decimal(@out)}" if cntr(14)
			if reg_format(@ir) == "01110110" # 76 - halt instruction loaded in IR 
				puts "Program HALTed"
				break
			end
			
			STDIN.gets if DEBUG
		end
	end
end 

if (ARGV.size < 1)
	puts "Usage: run <program> [--debug]"
	exit 
end

DEBUG = (ARGV.include?('--debug'))

comp = ComputerSAP2.new(File.readlines("#{ARGV[0]}.bin").collect do |l| l.strip end)
comp.run
