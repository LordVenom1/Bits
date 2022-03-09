require_relative 'simulation.rb'

$stdout.sync = true

class Computer1
			
	def initialize(program)
		@sim = Simulation.new()
		
		#internal components		
				
		@bus = ComponentGroup.build_bus8x8(@sim)
			@sim.show_gate_count("bus")		
		@mar = ComponentGroup.build_register(@sim, 8)    # Memory Address Register
			@sim.show_gate_count("mar")
		@ram = ComponentGroup.build_ram8x256(@sim, :high, program)       # Main Memory
			@sim.show_gate_count("ram")
		@pc = ComponentGroup.build_program_counter(@sim) # Program counter				
			@sim.show_gate_count("pc")
		@a = ComponentGroup.build_register(@sim, 8)      # A register
			@sim.show_gate_count("a")
		@b = ComponentGroup.build_register(@sim, 8)      # B register
			@sim.show_gate_count("b")
		@alu = ComponentGroup.build_alu8(@sim)		     # ALU
			@sim.show_gate_count("alu")
		@ir = ComponentGroup.build_register(@sim, 6)     # instruction register
			@sim.show_gate_count("ir")
		@m_cntr = ComponentGroup.build_microcounter(@sim, :low) # Micro-instruction counter
			@sim.show_gate_count("micro counter")
		# 6 inst, 4 cntr > 16 outputs		
		microcode_in = File.readlines("computer1a.rom").collect do |l| l.strip end
		microcode_out = File.readlines("computer1b.rom").collect do |l| l.strip end			
		@m_inst = ComponentGroup.build_microcode(@sim,   # ROM that stores all the micro instruciton control flags 
					microcode_in, microcode_out) 
			@sim.show_gate_count("microcode")
		
		#internal wiring
		(0...6).each do |idx| 
			# ir pulls the low 6 bits from the bus
			@ir.set_aliased_input(idx, @bus.aliased_output(idx + 2))
			# m_inst decodes the IR			
			@m_inst.set_aliased_input(idx, @ir.aliased_output(idx))			
		end
		
		# tie jump addr to zeros
		(0...4).each do |idx|
			@m_cntr.set_aliased_input(idx, Simulation::FALSE)
		end
		@m_cntr.set_aliased_input(4, Simulation::FALSE) # jump
		@m_cntr.set_aliased_input(5, Simulation::TRUE) # enable
		@m_cntr.set_aliased_input(6, @m_inst.aliased_output(6)) # zero	
		
								
		(0...8).each do |idx|
			@alu.set_aliased_input(idx, @a.aliased_output(idx))
			@alu.set_aliased_input(8 + idx, @b.aliased_output(idx))
		end		
		
		# pass micro loop counter into micro instruction
		(0...4).each do |idx| 
			@m_inst.set_aliased_input(6 + idx, @m_cntr.aliased_output(idx)) 
		end
		
		# connect "outgoing" control flags
		@a.set_aliased_input(8, @m_inst.aliased_output(0))
		@b.set_aliased_input(8, @m_inst.aliased_output(1))
		@alu.set_aliased_input(16, @m_inst.aliased_output(15)) # subtraction		

		# setup bus "outputs": determine which component gets to write to the bus on this cycle
		(0...8).each do |idx| @bus.set_aliased_input(0  + idx, @a.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(8  + idx, @b.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(16 + idx, @alu.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(24 + idx, @pc.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(32 + idx, @ram.aliased_output(idx)) end
		(0...8).each do |idx| @bus.set_aliased_input(40 + idx, Simulation::FALSE) end
		(0...8).each do |idx| @bus.set_aliased_input(48 + idx, Simulation::FALSE) end
		(0...8).each do |idx| @bus.set_aliased_input(56 + idx, Simulation::FALSE) end				
		(0...7).each do |idx| @bus.set_aliased_input(64 + idx, @m_inst.aliased_output(8 + idx)) end
		@bus.set_aliased_input(64 + 7, Simulation::FALSE) # do not link last m_inst, that is a sub flag
		
		# connect components to input registers from bus.. 
		# doens't do anything unless these components have their load signals set
		(0...8).each do |idx| 
			@ram.set_aliased_input(idx, @bus.aliased_output(idx))
			@a.set_aliased_input(idx, @bus.aliased_output(idx))
			@b.set_aliased_input(idx, @bus.aliased_output(idx))
			@pc.set_aliased_input(idx, @bus.aliased_output(idx))
			@mar.set_aliased_input(idx, @bus.aliased_output(idx))			
		end
		
		(0...8).each do |idx|
			@ram.set_aliased_input(8 + idx, @mar.aliased_output(idx))
		end
		
		@ram.set_aliased_input(16, @m_inst.aliased_output(7))
		@pc.set_aliased_input(8,@m_inst.aliased_output(3)) # pc enable
		@pc.set_aliased_input(9,@m_inst.aliased_output(4)) # jump
		@ir.set_aliased_input(6,@m_inst.aliased_output(5)) # ir read from bus flag
		@mar.set_aliased_input(8, @m_inst.aliased_output(2)) # mar read from bus flag
		
		#external wiring
		
		puts "Computer setup complete.  Press return to start processing."
		s = STDIN.gets
		
	end
	
	def reg_format(reg, decode = false)
	
		
		bin = (reg.outputs.collect do |o| o.output() ? '1' : '0'  end).join("")
		
		decode ? "#{bin} (#{bin.to_i(2).to_s()})" : bin
	end	
	
	def format_ir(ir)
	+ reg_format(@ir)  +  " (" + case reg_format(@ir)
			when "000000"
				"RESET"
			when "000100"
				"LDA"
			when "000101"
				"LDB"
			when "100000"
				"ADD"
			when "100001"
				"SUB"
			else
				"UNKNOWN"
		end + ")"
	end
	
	def cntr(idx)
		@m_inst.aliased_output(idx).output
	end
	
	def display()		
		
		system("clear") || system("cls") 
		puts "          C O M P U T E R       "
		puts "=================================="
		
		puts "  A#{(cntr(0) ? '*' : ' ')}: " + reg_format(@a,true) + "  B#{(cntr(1) ? '*' : ' ')}: " + reg_format(@b,true)
		puts "         ALU#{cntr(13) ? '-' : '+'}: " + reg_format(@alu, true)
		print "BUS : " + reg_format(@bus, true)
		
		puts "" 
		puts "MAR#{(cntr(2) ? '*' : ' ')}: " + reg_format(@mar) + "     RAM#{(cntr(7) ? '*' : ' ')}: " + reg_format(@ram,true)
		puts "" 
		puts "PC#{(cntr(3) ? '+' : ' ')} :  " + reg_format(@pc, true) 
		puts "IR#{(cntr(5) ? '*' : ' ')} :    " + format_ir(@ir) + " cnt " + reg_format(@m_cntr)		
		puts
		@sim.update(:low)
		c = reg_format(@m_inst)
		puts "Microcode Instruction ROM output (next step):"
		puts "    A:     #{c[0]}       A:   #{c[8]}                  "
		puts "    B:     #{c[1]}       B:   #{c[9]}                  "
		puts "    MAR:   #{c[2]}       ALU: #{c[10]}                  "
		puts "   PC Ena: #{c[3]}       PC:  #{c[11]}                  "
		puts "   PC JMP: #{c[4]}       RAM: #{c[12]}                  "
		puts "    IR:    #{c[5]}            #{c[13]}                  "
		puts "    MCZ:   #{c[6]}            #{c[14]}                  "
		puts "    RAM:   #{c[7]}       SUB: #{c[15]}                  "
					
	end
	
	def run()
		while true do 						
			display()						
			@sim.update(:high)
			s = STDIN.gets
		end
	end
end

if (ARGV.size != 1)
	puts "Usage: comp <program>"
	exit 
end 
comp = Computer1.new(File.readlines("#{ARGV[0]}.rom").collect do |l| l.strip end)
comp.run