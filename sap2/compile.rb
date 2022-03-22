line_count = 0

if (ARGV.size != 1)
	puts "Usage: compile <name>"
	puts "compiles <name>.src into <name>.rom"
	exit
end

variables = {}
addr = 200
labels = {}

buffer = ["00000000"] * 256
File.readlines(ARGV[0]+".src").each do |line|
	line.strip!
	
	# ignore comments
	if line.include?("#")
		line = line.split("#").first.strip
	end
	next if line == ""
	
	if line =~ /([a-zA-Z]+):/
		label = $1.upcase
		labels[label] = line_count	
	elsif line =~ /MVI A, ([0-9]+)/
		value = $1.to_i
		buffer[line_count] = "00111110" ; line_count = line_count + 1
		buffer[line_count] = value.to_s(2).rjust(8,'0') ; line_count = line_count + 1
	elsif line =~ /MVI B, ([0-9]+)/
		value = $1.to_i
		buffer[line_count] = "00000110" ; line_count = line_count + 1
		buffer[line_count] = value.to_s(2).rjust(8,'0') ; line_count = line_count + 1
	elsif line =~ /MVI C, ([0-9]+)/
		value = $1.to_i
		buffer[line_count] = "00001110" ; line_count = line_count + 1
		buffer[line_count] = value.to_s(2).rjust(8,'0') ; line_count = line_count + 1
	elsif line =~ /STA ([a-z]+)/
		label = $1.upcase
		buffer[line_count] = "00110010" ; line_count = line_count + 1	
		buffer[line_count] = variables[label].to_s(2).rjust(8,'0') ; 
		line_count = line_count + 1	
	elsif line =~ /LDA ([a-z]+)/
		label = $1.upcase
		buffer[line_count] = "00111010" ; line_count = line_count + 1	
		buffer[line_count] = variables[label].to_s(2).rjust(8,'0') ; 
		line_count = line_count + 1
	elsif line =~ /STB ([a-z]+)/
		label = $1.upcase
		buffer[line_count] = "00110000" ; line_count = line_count + 1	
		buffer[line_count] = variables[label].to_s(2).rjust(8,'0') ; 
		line_count = line_count + 1	
	elsif line =~ /LDB ([a-z]+)/
		label = $1.upcase
		buffer[line_count] = "00111000" ; line_count = line_count + 1	
		buffer[line_count] = variables[label].to_s(2).rjust(8,'0') ; 
		line_count = line_count + 1		
	elsif line =~ /JNZ ([a-zA-Z]+)/
		label = $1.upcase
		buffer[line_count] = "11000010" ; line_count = line_count + 1	
		buffer[line_count] = labels[label].to_s(2).rjust(8,'0') ; 
		line_count = line_count + 1		
	elsif line == "ADD B"
		buffer[line_count] = "10000000" ; line_count = line_count + 1
	elsif line == "OUT"
		buffer[line_count] = "11010011" ; line_count = line_count + 1
	elsif line == "HLT"
		buffer[line_count] = "01110110" ; line_count = line_count + 1
	elsif line == "MOV B,A"
		buffer[line_count] = "01000111" ; line_count = line_count + 1
	elsif line == "DCR C"
		buffer[line_count] = "00001101" ; line_count = line_count + 1		
	elsif line =~ /SET (.*) = ([0-9]+)/
		label, value = $1.upcase, $2.to_i.to_s(2).rjust(8,'0')
		addr += 1
		variables[label] = addr
		buffer[addr] = value		
	else
		raise "invalid code: #{line}"
	end
	
end

File.open(ARGV[0]+".bin", "w") do |out|
	out.puts buffer.join("\n")
end


# JNZ MORE
# HLT