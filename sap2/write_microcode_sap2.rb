MC_OPCODE_SIZE = 8
MC_INST_SET_SIZE = 2 ** MC_OPCODE_SIZE
MC_CNTR_ADDR_SIZE = 4 # 6-bit ring counter?
MC_CNTR_HEIGHT = 2 ** MC_CNTR_ADDR_SIZE
MC_SIZE = MC_INST_SET_SIZE * MC_CNTR_HEIGHT
MC_INST_WIDTH = 20

control = ["0" * MC_INST_WIDTH] * MC_SIZE

puts MC_INST_SET_SIZE
puts MC_CNTR_HEIGHT
puts MC_SIZE

# 0  - PC  Increment
# 1  - PC  Load from bus (jump)
# 2  - PC  Write to bus
# 3  - MAR Load from bus
# 4  - RAM Load from bus
# 5  - RAM Write to bus
# 6  - IR  Load from bus
# 7  - IR  Write to bus
# 8  - A   Load from bus
# 9  - A   Write to bus
# 10 - B   Load from bus
# 11 - B   Write to bus
# 12 - C   Load from bus
# 13 - C   Write to bus
# 14 - Out Load from bus
# 15 - TMP Load from bus
# 16 - ALU Write to bus
# 17 - ALU Operation - 
# 18 - ALU Operation
# 19 - ALU Operation

# setup instruction fetching 
(0...MC_SIZE).each do |addr|
	if addr % (MC_CNTR_HEIGHT) == 0
		# PC TO MAR      pppmrriiaabbccotaaaa
		control[addr] = "00110000000000000000" # Address state
	elsif addr % (MC_CNTR_HEIGHT) == 1
		# RAM>IR, +PC    pppmrriiaabbccotaaaa
		control[addr] = "10000110000000000000" # Memory State	
	end
end

#                pppmrriiaabbccotaaaa
addr = ("10000000" + "0010").to_i(2) # 80 ADD B
control[addr] = "00000000000100010000" ; addr += 1  # B To TMP
control[addr] = "00000000100000001000" ; addr += 1  # ALU TO A

#                pppmrriiaabbccotaaaa
addr = ("10000001" + "0010").to_i(2) # 81 ADD C
control[addr] = "00000000000010010000" ; addr += 1  # C To TMP
control[addr] = "00000000100000001000" ; addr += 1  # ALU TO A
                
#                pppmrriiaabbccotaaaa
addr = ("00111110" + "0010").to_i(2) # 3E MVI A
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "10000100100000000000" ; addr += 1  # RAM to A reg

#                pppmrriiaabbccotaaaa
addr = ("00000110" + "0010").to_i(2) # 06 MVI B
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "10000100001000000000" ; addr += 1  # RAM to B reg

#                pppmrriiaabbccotaaaa
addr = ("00001110" + "0010").to_i(2) # 0E MVI C
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "10000100000010000000" ; addr += 1  # RAM to C reg

#                pppmrriiaabbccotaaaa
addr = ("00001101" + "0010").to_i(2) # 0D DCR C
control[addr] = "00000000000001010000" ; addr += 1  # C TO TMP
control[addr] = "00000000000010001011" ; addr += 1  # ALU TO C

#                pppmrriiaabbccotaaaa
addr = ("11000010" + "0010").to_i(2) # C2 JNZ
control[addr] = "10110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "01000100000000000000" ; addr += 1  # RAM to PC reg
addr = ("11000010" + "1000").to_i(2) # C2 JNZ
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR

#                pppmrriiaabbccotaaaa
addr = ("01000111" + "0010").to_i(2) # 47 MOV B,A
control[addr] = "00000000011000000000" ; addr += 1  # A reg to B reg

#                pppmrriiaabbccotaaaa
addr = ("00111010" + "0010").to_i(2) # 3A LDA
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "10010100000000000000" ; addr += 1  # RAM write to MAR 
control[addr] = "00000100100000000000" ; addr += 1  # RAM to A reg

#                pppmrriiaabbccotaaaa
addr = ("00110010" + "0010").to_i(2) # 32 STA
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "10010100000000000000" ; addr += 1  # RAM write to MAR 
control[addr] = "00001000010000000000" ; addr += 1  # A reg to RAM

#                pppmrriiaabbccotaaaa
addr = ("00111000" + "0010").to_i(2) # 38 LDB
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "10010100000000000000" ; addr += 1  # RAM write to MAR 
control[addr] = "00000100001000000000" ; addr += 1  # RAM to B reg

#                pppmrriiaabbccotaaaa
addr = ("00110000" + "0010").to_i(2) # 30 STB
control[addr] = "00110000000000000000" ; addr += 1  # PC write to MAR
control[addr] = "10010100000000000000" ; addr += 1  # RAM write to MAR 
control[addr] = "00001000000100000000" ; addr += 1  # B reg to RAM

#                pppmrriiaabbccotaaaa
addr = ("11010011" + "0010").to_i(2) # D3 - OUT
control[addr] = "00000000010000100000" ; addr += 1  # A reg to OUT reg
# no-ops for the remaining 3 states...

#                pppmrriiaabbccotaaaa
addr = ("01110110" + "0010").to_i(2) # 76 - HLT
control[addr] = "00000000000000000000" ; addr += 1  # outside circuitry to stop the clock

#                pppmrriiaabbccotaaaa
#CNA - not A
#ANA - and <a,b,c>
#ani - and immediate
#ORA - or <a,b,c>
#ori - or immediate
#XRA - xor <a,b,c>
#xri - xor immeidate
#

File.open("sap2.rom","w") do |out| out.print control.join("\n") end