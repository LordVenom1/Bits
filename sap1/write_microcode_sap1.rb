MC_OPCODE_SIZE = 4
MC_INST_SET_SIZE = 2 ** MC_OPCODE_SIZE
MC_CNTR_ADDR_SIZE = 3 # 6-bit ring counter?
MC_CNTR_HEIGHT = 2 ** MC_CNTR_ADDR_SIZE
MC_SIZE = MC_INST_SET_SIZE * MC_CNTR_HEIGHT
MC_INST_WIDTH = 12

control = ["0" * MC_INST_WIDTH] * MC_SIZE

puts MC_INST_SET_SIZE
puts MC_CNTR_HEIGHT
puts MC_SIZE

# 0  - PC  Increment
# 1  - PC  Write to bus
# 2  - MAR Load from bus
# 3  - RAM Write to bus
# 4  - IR  Load from bus
# 5  - IR  Write to bus
# 6  - A   Load from bus
# 7  - A   Write to bus
# 8  - ALU Subtraction
# 9  - ALU Write to bus
# 10 - B   Load from bus
# 11 - Out Load from bus

# setup instruction fetching 
(0...MC_SIZE).each do |addr|
	if addr % (MC_CNTR_HEIGHT) == 0
		# PC TO MAR
		control[addr] = "011000000000" # Address state
	elsif addr % (MC_CNTR_HEIGHT) == 1
		# RAM TO IR, increment PC
		control[addr] = "100000000000" # Increment State
	elsif addr % (MC_CNTR_HEIGHT) == 2 
		# RAM TO IR, increment PC
		control[addr] = "000110000000" # Memory State
		
	end
end

# LDA <addr> 0000
# ADD <addr> 0001
# SUB <addr> 0010
# OUT        1110
# HLT        1111
#                ppmriiaas+bo

addr = ("0000" + "011").to_i(2) # 0000 - LDA <addr>
control[addr] = "001001000000" ; addr += 1  # IR addr to MAR
control[addr] = "000100100000" ; addr += 1  # RAM to A reg
# no-ops for the remaining 3 states...

addr = ("0001" + "011").to_i(2) # 0001 - ADD <addr>
control[addr] = "001001000000" ; addr += 1  # IR addr to MAR
control[addr] = "000100000010" ; addr += 1  # RAM to B reg
control[addr] = "000000100100" ; addr += 1  # ALU to A reg
# no-ops for the remaining 2 states...

addr = ("0010" + "011").to_i(2) # 0010 - SUB <addr>
control[addr] = "001001000000" ; addr += 1  # IR addr to MAR
control[addr] = "000100000010" ; addr += 1  # RAM to B reg
control[addr] = "000000101100" ; addr += 1  # ALU to A reg
# no-ops for the remaining 2 states...

addr = ("1110" + "011").to_i(2) # 1110 - OUT
control[addr] = "000000010001" ; addr += 1  # A reg to OUT reg
# no-ops for the remaining 3 states...

addr = ("1111" + "011").to_i(2) # 1111 - HLT
control[addr] = "000000000000" ; addr += 1  # outside circuitry to stop the clock

File.open("sap1.rom","w") do |out| out.print control.join("\n") end