require_relative 'language.rb'

#########################################################################
# read in language definition, write resultant microcode into a ROM file
#########################################################################

control = ["0" * MC_INST_WIDTH] * MC_SIZE

# setup instruction fetching as first two microcodes
(0...MC_SIZE).each do |addr|
	if addr % (MC_CNTR_HEIGHT) == 0
		# Address state
		control[addr] = (FLAGS::PC_WRITE | FLAGS::MAR_LOAD).to_s(2).rjust(MC_INST_WIDTH,'0') 
	elsif addr % (MC_CNTR_HEIGHT) == 1
		# Memory State	
		control[addr] = (FLAGS::RAM_WRITE | FLAGS::IR_LOAD | FLAGS::PC_INC).to_s(2).rjust(MC_INST_WIDTH,'0') 
	end
end

# populate the microcode control flags based on the opcode address and generated microcode
Operand::all.each do |op|
	mc = op.decode_microcode
	control[op.addr * MC_CNTR_HEIGHT + 2, mc.size] = mc	
end

File.open("sap2.rom","w") do |out| out.print control.join("\n") end
