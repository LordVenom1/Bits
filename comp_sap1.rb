require './components.rb'

class ComputerSAP
	attr_reader :label
	
	def path
		@label
	end
	
	def reg_format(reg, decode = false)
		bin = (reg.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join("")
		decode ? "#{bin} (#{bin.to_i(2).to_s()})" : bin
	end
	
	def initialize()
		@sim = Simulation.new()
		@label = "Computer1"
	
		f = @sim.false_signal.outputs[0]
		t = @sim.true_signal.outputs[0]

		@bus = Bus8x8.new(@sim, "bus8x8", self) 
		#set bus inputs to low to avoid issues with unused sections
		(0...72).each do |idx| @bus.inputs[idx].set_source(f) end 

		@mar = Register8.new(@sim, "MAR", self) # memory address register
		@ram = RAM8x256.new(@sim, "RAM", self) # 8 data + 8 addr + 1 enable
		@pc = ProgramCounter.new(@sim, "PC", self) # 8 data, increment, jump
		@a = Register8.new(@sim, "A", self) # 8 data + 1 enable
		@b = Register8.new(@sim, "B", self) # 8 data + 1 enable
		@alu = ALU8.new(@sim, "ALU", self) # 8 data, 8 data, subtract  - 8 out
		
		(0...8).each do |idx|
			@alu.inputs[idx].set_source(@a.outputs[idx])
			@alu.inputs[idx + 8].set_source(@b.outputs[idx])
		end
		
		
		@ir = RegisterN.new(@sim,"IR",self,6) # 6 inst, 8 # instruction 9/8
		# (6...14).each do |idx|
			# @ir.inputs[idx].set_source(f)
		# end
		#              INST        DATA
		# @ir.override("000100" + "00000000")  # move A, B
		# @ir.inputs.each do |i| i.set_source(f) end
		
		@microcode = Microcode.new(@sim, "microcode", self, "computer1a.rom", "computer1b.rom") # 6 inst, 4 cntr > 16 outputs
		(0...6).each do |idx| 
			@microcode.inputs[idx].set_source(@ir.outputs[idx]) 
			@ir.inputs[idx].set_source(@bus.outputs[idx + 2])
		end
		
		# microcounter runs on inverse clock
		@microcounter = MicroCounter.new(@sim,"microloop",self, 4, true) # addr + JEZ
		@microcounter.inputs.each do |i| i.set_source(f) end 
		@microcounter.inputs[5].set_source(t) # tie enable to true
		@microcounter.inputs[6].set_source(@microcode.outputs[6])
		
		@alu.inputs[16].set_source(@microcode.outputs[13]) # subtraction
		
		(0...4).each do |idx| @microcode.inputs[idx + 6].set_source(@microcounter.outputs[idx]) end # tbd loopcounter	

		# @ir.inputs[10].set_source(f) # IR load
		
		(0...8).each do |idx| @a.inputs[idx].set_source(f) end
		@a.inputs[8].set_source(@microcode.outputs[0])
		(0...8).each do |idx| @b.inputs[idx].set_source(f) end		
		@b.inputs[8].set_source(@microcode.outputs[1])				

		# @flags = RegisterN.new(@sim, 4)  # TBD								

		# setup bus "outputs": determine which component gets to write to the bus on this cycle
		(0...8).each do |idx| @bus.inputs[0 + idx].set_source(@a.outputs[idx]) end 
		(0...8).each do |idx| @bus.inputs[8 + idx].set_source(@b.outputs[idx]) end 
		(0...8).each do |idx| @bus.inputs[16 + idx].set_source(@ram.outputs[idx]) end 
		(0...8).each do |idx| @bus.inputs[24 + idx].set_source(@pc.outputs[idx]) end 
		(0...8).each do |idx| @bus.inputs[32 + idx].set_source(@alu.outputs[idx]) end 
		# (0...8).each do |idx| @bus.inputs[40 + idx].set_source(@pc.outputs[idx]) end 
		# (0...8).each do |idx| @bus.inputs[48 + idx].set_source(@pc.outputs[idx]) end 
		(0...8).each do |idx| @bus.inputs[56 + idx].set_source(@ram.outputs[idx]) end 
		
		(0...8).each do |idx| @bus.inputs[64 + 7 - idx].set_source(@microcode.outputs[8 + idx]) end 

		(0...8).each do |idx| 
			@ram.inputs[idx].set_source(@bus.outputs[idx])
			@a.inputs[idx].set_source(@bus.outputs[idx])
			@b.inputs[idx].set_source(@bus.outputs[idx])			
			@pc.inputs[idx].set_source(@bus.outputs[idx])
			@mar.inputs[idx].set_source(@bus.outputs[idx])			
		end
		
		(0...8).each do |idx|
			@ram.inputs[idx+8].set_source(@mar.outputs[idx])
		end
		@ram.inputs[16].set_source(@microcode.outputs[7])
			
		# (0..8).each do |idx| @ram.inputs[idx + 8].set_source(@mar.outputs[idx]) end # addr + enable
		@pc.inputs[8].set_source(@microcode.outputs[3]) # pc enable
		@pc.inputs[9].set_source(@microcode.outputs[4]) # jump
		
		
		# @a.inputs[8].set_source(f)
		# @b.inputs[8].set_source(f)
		# (0...8).each do |idx| @alu.inputs[idx + 8].set_source(@b.outputs[idx]) end
		# @alu.inputs[16].set_source(f) # subtraction
		@ir.inputs[6].set_source(@microcode.outputs[5]) # ir read from bus flag
		@mar.inputs[8].set_source(@microcode.outputs[2]) # mar read from bus flag

		# @control_out.inputs[0].set_source(f) # ram
		# @control_out.inputs[1].set_source(f) # a
		# @control_out.inputs[2].set_source(f) # b
		# @control_out.inputs[3].set_source(f) # alu
		# @control_out.inputs[4].set_source(t) # pc
		# @control_out.inputs[5].set_source(f)
		# @control_out.inputs[6].set_source(f)
		# @control_out.inputs[7].set_source(f)
	
	end
	
	def format_ir(ir, cnt)
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
		end + ") " + reg_format(@microcounter)
	end
	
	def display(desc)		
	
		# HERE WE GO
		
		puts "Computer 1 #{desc}:"
		
		# puts flags
		
		puts "  A: " + reg_format(@a,true) + "  B: " + reg_format(@b,true)
		puts "ALU: " + reg_format(@alu, true)
		puts "BUS: " + reg_format(@bus, true)
		puts "" 
		puts "MAR: " + reg_format(@mar)
		puts "RAM: " + reg_format(@ram,true)
		puts "" 
		puts "PC:  " + reg_format(@pc, true)
		puts "IR:    " + format_ir(@ir, @microcounter)
		puts 
		puts "" 
		puts "             M   J   M R     " + "                  A S   R     "
		puts "             A C M I C A     " + "                P L U   A     "
		puts "         A B R E P R Z M     " + "          A B   C U B   M     "
		puts "CTL RECV:" + reg_format(@microcode)[0,8].split("").join(" ") + "     CTL SEND: " + reg_format(@microcode)[8,8].split("").join(" ")
		
	end
	
	def run(progname)
		
		system("ruby write_microcode_1024.rb")
		system("ruby compile.rb #{progname}")
		
		@ram.load_file("#{progname}.rom")
				
		@sim.update(false, false)
		display("start")	
		s = STDIN.gets()
		
		while true do 
		
			# show microcode step "before"
			@sim.update(true, false)
			display("before")						
			@sim.update(false, true)
			display("after")
			s = STDIN.gets()
		end

	
	# data movement
		# movement
		# push
		# pop
		# lea - load pointer into register
		
	# arithmetic/logic
		# add
		# sub
		# inc, dec
		# imul, idiv
		# and,or,xor
		# not
		# neg
		# shl, shr - bit shift
		# 
	# control-flow
		# jmp
		# je, jne, jz, jg, jge, jl, jle
		# cmp - same as subtract except result is discarded.  sets falgs.  
		# call, ret - subroutines!
		
	
	# ip - instruction pointer - same as pc?
	# cf carry flag
	# df direction flag
	# if interrupt flag
	# esp stack pointer.  same as sp?
	# ebp base pointer
	# esi, edi?
	
	
		# how we do'in this?  4 inst, 4 op codes?  or 2-byte instructions?
		# @ir.override("00000000")
	
		# 2.times() do 
			# @sim.update
			# display()
			# s = gets 
		# end
	end
end

if (ARGV.size != 1)
	puts "Usage: comp <program>"
	exit 
end 
comp = ComputerSAP.new()
comp.run(ARGV[0])