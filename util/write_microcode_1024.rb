# tell components to read from bus
control_in = ["00000000"] * 1024
# tell components to write to bus
control_out = ["00000000"] * 1024

# setup instruction fetching 
(0...1024).each do |addr|
	if addr % 16 == 0
		# PC TO MAR
		control_in[addr], control_out[addr] = "00100000", "00010000"
	elsif addr % 16 == 1
		# RAM TO IR, increment PC
		control_in[addr], control_out[addr] = "00010100", "00001000"
	end
end


# instruction set documentation:

# MAR TO IR HIGH

# A, B, ALU, PC, RAM, none, none, SUB


addr = ("000000" + "0010").to_i(2) # RESET
control_in[addr], control_out[addr] = "11011010","00001000" ; addr += 1  # ram (0) to a, b, pc

#                                        read       write
#                                        J          
#                                        M           
#                                      ABP.....   AB......
addr = ("000100" + "0010").to_i(2) # LDA [addr]
control_in[addr], control_out[addr] = "00100000","00010000" ; addr += 1  # pc to mar
control_in[addr], control_out[addr] = "00110000","00001000" ; addr += 1  # ram to mar pointer lookup
control_in[addr], control_out[addr] = "10000010","00001000" ; addr += 1  # ram to a

#
#                                        J          .
#                                      ABMP....   AB......
addr = ("000101" + "0010").to_i(2) # LDB [addr]
control_in[addr], control_out[addr] = "00100000","00010000" ; addr += 1  # pc to mar
control_in[addr], control_out[addr] = "00110000","00001000" ; addr += 1  # ram to mar pointer lookup
control_in[addr], control_out[addr] = "01000010","00001000" ; addr += 1  # ram to b

#
#                                        J          .
#                                      ABMP....   AB......
addr = ("100000" + "0010").to_i(2) # ADD
control_in[addr], control_out[addr] = "10000010","00100000" ; addr += 1  # ALU TO A

addr = ("100001" + "0010").to_i(2) # SUB
control_in[addr], control_out[addr] = "10000010","00100001" ; addr += 1  # ALU TO A w/ SUB


# OPCODE CNTR
# 000000 0000
# 000001
# 000010
# 000011
# 000100
# 000101
# 000110
# 000111
# ...

# (0...1024).each do |idx|
	# puts idx.to_s(2).rjust(8,'0')[-8,8]
# end

# control_in

File.open("computer1a.rom","w") do |out| out.print control_in.join("\n") end
File.open("computer1b.rom","w") do |out| out.print control_out.join("\n") end