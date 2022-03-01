(0...1024).each do |idx|
	puts idx.to_s(2).rjust(8,'0')[-8,8]
end