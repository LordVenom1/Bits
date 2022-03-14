require_relative '../simulation.rb'

$stdout.sync = true

# this is a computer call the "simple as possible (SAP) 1" described in 
# Digital Computer Electronics 3d edition by Malvino, Brown, starting page 140

class ComputerSAP1
	
	def initialize(program)
		@sim = Simulation.new()
		
		#internal components
		@bus = ComponentGroup.build_bus8x8(@sim)
		@mar = ComponentGroup.build_register_n(@sim, 4)
		@ram = ComponentGroup.build_ram_n_m(@sim, 8, 16, :high, program)
		@pc = ComponentGroup.build_counter_n(@sim, 4)
		
		@a = ComponentGroup.build_register_n(@sim, 8)
		@b = ComponentGroup.build_register_n(@sim, 8)
		@alu = ComponentGroup.build_alu8(@sim)
		@out = ComponentGroup.build_register_n(@sim, 8)		
		@ir = ComponentGroup.build_register_n(@sim, 8)
		#binary display?
		
		microcode = File.readlines("sap1.rom").collect do |l| l.strip end
		@m_inst = ComponentGroup.build_rom_n_m(@sim, 12, 128 ,microcode)
	
		@m_cntr = ComponentGroup.build_counter_register_n(@sim, 3, :low) # 6-bit ring counter?
		
		#internal wiring		
		# setup bus "outputs": determine which component gets to write to the bus on this cycle
		(0...8).each do |idx| @bus.set_aliased_input(0  + idx, idx < 4 ? @pc.aliased_output(idx) : Simulation::FALSE) end				
		(0...8).each do |idx| @bus.set_aliased_input(8  + idx, @ram.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(16 + idx, idx < 4 ? @ir.aliased_output(idx + 4) : Simulation::FALSE) end
		(0...8).each do |idx| @bus.set_aliased_input(24 + idx, @a.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(32 + idx, @alu.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(40 + idx, Simulation::FALSE) end
		(0...8).each do |idx| @bus.set_aliased_input(48 + idx, Simulation::FALSE) end
		(0...8).each do |idx| @bus.set_aliased_input(56 + idx, Simulation::FALSE) end	

		@bus.set_aliased_input(64 + 0, @m_inst.aliased_output(1)) # pc write to bus
		@bus.set_aliased_input(64 + 1, @m_inst.aliased_output(3)) # ram write to bus
		@bus.set_aliased_input(64 + 2, @m_inst.aliased_output(5)) # ir write to bus
		@bus.set_aliased_input(64 + 3, @m_inst.aliased_output(7)) # a write to bus
		@bus.set_aliased_input(64 + 4, @m_inst.aliased_output(9)) # alu write to bus		
		@bus.set_aliased_input(64 + 5, Simulation::FALSE) #unused
		@bus.set_aliased_input(64 + 6, Simulation::FALSE) #unused
		@bus.set_aliased_input(64 + 7, Simulation::FALSE) #unused		
		
		# connect components to input registers from bus. 
		# doesn't do anything unless these components have their load signals set
		(0...8).each do |idx| 			
			@a.set_aliased_input(idx, @bus.aliased_output(idx))
			@b.set_aliased_input(idx, @bus.aliased_output(idx))
			@out.set_aliased_input(idx, @bus.aliased_output(idx))
			@ir.set_aliased_input(idx, @bus.aliased_output(idx))				
			@mar.set_aliased_input(idx, @bus.aliased_output(idx)) if idx < 4
		end		
		
		# set control signals
		@pc.set_aliased_input(4, @m_inst.aliased_output(0))   # pc increment
		@mar.set_aliased_input(4, @m_inst.aliased_output(2))  # mar load from bus
		@ir.set_aliased_input(8, @m_inst.aliased_output(4))   # ir load from bus
		@a.set_aliased_input(8, @m_inst.aliased_output(6))    # a load from bus
		@alu.set_aliased_input(16, @m_inst.aliased_output(8)) # subtraction
		@b.set_aliased_input(8, @m_inst.aliased_output(10))   # b load from bus
		@out.set_aliased_input(8, @m_inst.aliased_output(11)) # out load from bus
		
		# wire pc jump to false
		(0...4).each do |idx|
			@pc.set_aliased_input(idx, Simulation::FALSE)
		end
		@pc.set_aliased_input(5, Simulation::FALSE)
		
		# wire cntr jump to false
		(0...6).each do |idx|
			@m_cntr.set_aliased_input(idx, Simulation::FALSE)
		end
		# mc cntr to high
		@m_cntr.set_aliased_input(4, Simulation::TRUE)
		
		# ALU inputs are A and B regs
		(0...8).each do |idx|
			@alu.set_aliased_input(idx, @a.aliased_output(idx))
			@alu.set_aliased_input(8 + idx, @b.aliased_output(idx))
		end	
		
		# connect MAR to RAM address
		(0...4).each do |idx|
			@ram.set_aliased_input(8 + idx, @mar.aliased_output(idx))
		end	
		
		# high 4 bits in IR is the op-code
		(0...4).each do |idx|
			@m_inst.set_aliased_input(idx, @ir.aliased_output(idx))
		end
		# pass micro loop counter into micro instruction
		(0...3).each do |idx| 
			@m_inst.set_aliased_input(4 + idx, @m_cntr.aliased_output(idx)) 
		end
		
		# disable ram input
		(0...8).each do |idx|
			@ram.set_aliased_input(idx, Simulation::FALSE)
		end
		@ram.set_aliased_input(12, Simulation::FALSE)

	end
	
	def reg_decimal(reg)
		bin = (reg.outputs.collect do |o| o.output() ? '1' : '0'  end).join("")
		bin.to_i(2).to_s()
	end
	
	def reg_format(reg, decode = false)
		bin = (reg.outputs.collect do |o| o.output() ? '1' : '0'  end).join("")
		decode ? "#{bin} (#{bin.to_i(2).to_s()})" : bin
	end	
	
	def cntr(idx)
		@m_inst.aliased_output(idx).output
	end	
	
	def format_ir(ir)
	 reg_format(@ir)  +  " (" + case reg_format(@ir)[0,4]
			when "0000"
				"LDA"
			when "0001"
				"ADD"
			when "0010"
				"SUB"
			when "1110"
				"OUT"
			when "1111"
				"HLT"
			else
				"UNKNOWN"
		end + ")"
	end
	
	def display()		
		
		system("clear") || system("cls") 
		puts "          C O M P U T E R       "
		puts "=================================="
		
		puts "  A#{(cntr(6) ? '*' : ' ')}: " + reg_format(@a,true) + "  B#{(cntr(10) ? '*' : ' ')}: " + reg_format(@b,true)
		puts "         ALU#{cntr(8) ? '-' : '+'}: " + reg_format(@alu, true)
		print "BUS : " + reg_format(@bus, true)
		
		puts "" 
		puts "MAR#{(cntr(2) ? '*' : ' ')}: " + reg_format(@mar) + "     RAM : " + reg_format(@ram,true)
		puts "" 
		puts "PC#{(cntr(0) ? '+' : ' ')} :  " + reg_format(@pc, true) 
		puts "IR#{(cntr(4) ? '*' : ' ')} :    " + format_ir(@ir) + " cnt " + reg_format(@m_cntr)		
		puts
		
		c = reg_format(@m_inst)
		puts "Microcode Instruction ROM output (next step):"
		puts "  PC Inc:    #{c[0]}      A Load:    #{c[6]}    "
		puts "  PC Write:  #{c[1]}      A Write:   #{c[7]}    "
		puts "  MAR Load:  #{c[2]}      ALU Sub: #{c[8]}      "
		puts "  RAM Write: #{c[3]}      ALU Write:   #{c[9]}  "
		puts "  IR Load :  #{c[4]}      B Load: #{c[10]}      "
		puts "  IR Write:  #{c[5]}      OUT Load:  #{c[11]}   "
		puts 

					
	end
	
	def run()
	
		while true do 						
			@sim.update(:low)
			#display()										
			@sim.update(:high)
			
			puts "OUTPUT: #{reg_decimal(@out)}" if cntr(11)
			if reg_format(@ir)[0,4] == "1" * 4 # halt instruction loaded in IR\
				puts "Program HALTed"
				break
			end
			
			# s = STDIN.gets
		end
	end
	
	if (ARGV.size != 1)
		puts "Usage: comp <program>"
		exit 
	end
end 

comp = ComputerSAP1.new(File.readlines("#{ARGV[0]}.bin").collect do |l| l.strip end)
comp.run
