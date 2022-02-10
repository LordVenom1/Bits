control_in = "0000000000\n" * 1024
control_out = "0000000000\n" * 1024

# (0...1024).each do |idx|
	# puts idx.to_s(2).rjust(8,'0')[-8,8]
# end

# control_in

File.open("computer1a.rom","w") do |out| out.print control_in end
File.open("computer1b.rom","w") do |out| out.print control_out end