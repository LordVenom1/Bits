line_count = 0

if (ARGV.size != 1)
	puts "Usage: compile <name>"
	puts "compiles <name>.src into <name>.rom"
	exit
end

variables = {}
addr = 200

buffer = ["00000000"] * 256
File.readlines(ARGV[0]+".src").each do |line|
	line.strip!
	
	# ignore comments
	if line.include?("#")
		line = line.split("#").first.strip
	end
	next if line == ""
	
	if line =~ /LDA (.*)/
		target = $1
		raise "variable #{target} not defined" unless variables[target]
		buffer[line_count] = "00000100" ; line_count = line_count + 1
		buffer[line_count] = variables[target].to_i.to_s(2).rjust(8,'0') # two line instruction...
		line_count = line_count + 1	
	elsif line =~ /LDB (.*)/
		target = $1
		raise "variable #{target} not defined" unless variables[target]
		buffer[line_count] = "00000101" ; line_count = line_count + 1
		buffer[line_count] = variables[target].to_i.to_s(2).rjust(8,'0') # two line instruction...
		line_count = line_count + 1
	elsif line == "ADD"
		buffer[line_count] = "00100000" ; line_count = line_count + 1
	elsif line == "SUB"
		buffer[line_count] = "00100001" ; line_count = line_count + 1		
	elsif line =~ /SET (.*) = ([0-9]+)/
		label, value = $1, $2.to_i.to_s(2).rjust(8,'0')
		addr += 1
		variables[label] = addr
		buffer[addr] = value		
	else
		raise "invalid code: #{line}"
	end
	
end

File.open(ARGV[0]+".rom", "w") do |out|
	out.puts buffer.join("\n")
end