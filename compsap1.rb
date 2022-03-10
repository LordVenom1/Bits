require_relative 'simulation.rb'

$stdout.sync = true

# this is a computer call the "simple as possible (SAP) 1" described in 
# Digital Computer Electronics 3d edition by Malvino, Brown, starting page 140

class ComputerSAP1
	
	def initialize(program)
		@sim = Simulation.new()
		
		#internal components
		
		#internal wiring
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
	
	if (ARGV.size != 1)
	puts "Usage: comp <program>"
	exit 
end 

comp = ComputerSAP1.new(File.readlines("#{ARGV[0]}.rom").collect do |l| l.strip end)
comp.run
