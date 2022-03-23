require_relative 'language.rb'

if (ARGV.size != 1)
	puts "Usage: compile <name>"
	puts "compiles <name>.src into <name>.bin"
	exit
end

RAM_HEIGHT = 256

variables = {}
var_addr = 200
labels = {}
jump_addrs = {}
buffer = ["00000000"] * RAM_HEIGHT
line_count = 0

# process operands into machine code
File.readlines(ARGV[0]+".src").each do |line|
	line.strip!
	
	# remove comments: # ; //
	if line.include?("#")
		line = line.split("#").first.strip
	end
	if line.include?(";")
		line = line.split(";").first.strip
	end
	if line.include?("//")
		line = line.split("//").first.strip
	end
	next if line.strip == ""
		
	parsed = false		
	
	if line =~ /([a-zA-Z]+):/ # label
		label = $1.upcase
		labels[label] = line_count
		parsed = true
	elsif line =~ /SET (.*) = ([0-9]+)/ # define variable
		varname, value = $1.upcase, $2.to_i.to_s(2).rjust(8,'0')		
		variables[varname] = var_addr		
		buffer[var_addr] = value # set ram address to default value
		var_addr += 1
	else	
		Operand::all.each do |op|
			if line =~ op.parse_re
				buffer[line_count] = op.decode_addr ; line_count = line_count + 1
				op.params.each do |p|
					case p
						when :label
							label = $1.upcase
							jump_addrs[line_count] = label							
							buffer[line_count] = "11111111"
							line_count = line_count + 1		
						when :variable
							varname = $1.upcase
							raise "undefined variable: #{varname}" unless variables[varname]
							buffer[line_count] = variables[varname].to_s(2).rjust(8,'0'); 
							line_count = line_count + 1	
						when :value
							value = $1.to_i
							buffer[line_count] = value.to_s(2).rjust(8,'0') ; line_count = line_count + 1
					end
				end
				parsed = true
				break
			end		
		end
		raise "unable to parse line: #{line}" unless parsed
	end
end

# replace jump addresses with correct labels
jump_addrs.each do |addr, label|
	raise "undefined label: #{label}" unless labels[label]
	raise "bad jump addr" unless buffer[addr] == "11111111"
	buffer[addr] = labels[label].to_s(2).rjust(8,'0')
end

File.open(ARGV[0]+".bin", "w") do |out|
	out.puts buffer.join("\n")
end
