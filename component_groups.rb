class ComponentGroup	

	attr_reader :inputs, :outputs # for debug

	def initialize(num_inputs, num_outputs)
		@inputs = Array.new(num_inputs)
		@outputs = Array.new(num_outputs)				
	end
	
	def debug_override_input_values(inputs)
		raise "bad override length #{inputs.size} != #{@inputs.size}"
		inputs.split("").each_with_index do |i,n|			
			gate = Simulation::FALSE if ["0","F"].include? i
			gate = Simulation::TRUE if ["1","T"].include? i
			raise "invalid input #{inputs}" unless gate
			self.set_aliased_input(n, gate)
		end	
	end
	
	def display(name)	
		puts name		
		
		puts "Inputs: " + (@inputs.collect.with_index do |i, idx|
			begin
				i.first.inputs[i.last].output ? '1' : '0'
			rescue Exception => ex
				raise "unable to display input #{idx}: " + ex.to_s
			end
			
		end.join(""))
		
		puts "Outputs: " + (@outputs.collect do |o|			
			begin
				o.output ? '1' : '0'
			rescue Exception => ex
				raise "unable to display output #{idx}: " + ex.to_s
			end
			
		end.join(""))
	end
	
	# remember the target internal component and an input number for input[n]
	# later we can either set_aliased_input which will lookup this actual component and set that input to the given source output
	# or we can use aliased_input to grab the target, so we can alias it again to an encompassing component group
	def alias_input(external_input_num, component, internal_input_num)
		raise "bad external_input_num #{external_input_num}" unless external_input_num < @inputs.size
		raise 'bad component' unless component
		@inputs[external_input_num] = [component,internal_input_num]
	end
		
	# remember which component each cg output pulls its output from
	def alias_output(external_output_num, component)
		raise "bad external_output_num #{external_output_num}" unless external_output_num < @outputs.size
		@outputs[external_output_num] = component
	end	
	
	# dereference the target internal component and then set its source output
	def set_aliased_input(external_input_num, out)
		raise "out of range #{external_input_num}" unless external_input_num < @inputs.size		
		internal_component, internal_input_num = *@inputs[external_input_num]
		raise "input alias not set: #{external_input_num}" if internal_component == nil
		internal_component.set_input(internal_input_num, out)
	end
	
	# retrieve the component and input idx a cg-input is aliased to.  can use it to store this same pair in a parent cg
	def aliased_input(external_input_num)
		raise "out of range #{external_input_num}" unless external_input_num < @inputs.size
		@inputs[external_input_num]
	end
	
	def aliased_output(external_output_num)
		raise "out of range #{external_output_num}" unless external_output_num < @outputs.size
		@outputs[external_output_num]
	end
	
	### Logical Component Groups (higher-level components)
	### These mainly just build actual components, but you can use the cg you get back to 
	### attach the cg's inputs and outputs to other components
	### after that you can throw away the cg unless you want to reference it, for example, to display a register
	
	def self.build_or4_gate(sim)
		cg = ComponentGroup.new(4,1)
		#internal components
		o1 = sim.register_component(OrGate.new)
		o2 = sim.register_component(OrGate.new)
		out = sim.register_component(OrGate.new)
		
		#internal wiring		
		out.set_inputs([o1,o2])
		
		#external wiring
		cg.alias_input(0, o1, 0)
		cg.alias_input(1, o1, 1)
		cg.alias_input(2, o2, 0)
		cg.alias_input(3, o2, 1)
		cg.alias_output(0, out)
		
		cg
	end
	
	def self.build_and4_gate(sim)
		cg = ComponentGroup.new(4,1)
		#internal components
		a1 = sim.register_component(AndGate.new)
		a2 = sim.register_component(AndGate.new)
		out = sim.register_component(AndGate.new)
		
		#internal wiring
		out.set_inputs([a1,a2])
		
		#external wiring
		cg.alias_input(0, a1, 0)
		cg.alias_input(1, a1, 1)
		cg.alias_input(2, a2, 0)
		cg.alias_input(3, a2, 1)
		cg.alias_output(0, out)
		
		cg
	end
	
	def self.build_bit_register(sim, on_clock = :high, initial_value = false)
		cg = ComponentGroup.new(2,1)
		
		b = sim.register_component(BufferGate.new) #load
			
		n = sim.register_component(NotGate.new)
		a1 = sim.register_component(AndGate.new) # previous value AND not load?
		a2 = sim.register_component(AndGate.new) # new value and load?
		o = sim.register_component(OrGate.new)
		dl = sim.register_clocked_component(DataLatch.new(initial_value), on_clock)
		
		#internal wiring
		n.set_inputs([b])
		a1.set_inputs([dl,n])
		a2.set_input(0, b)
		o.set_inputs([a1,a2])
		dl.set_inputs([o])
		
		#external wiring
		cg.alias_input(0, a2, 1)
		cg.alias_input(1, b, 0)
		cg.alias_output(0, dl)
			
		cg
	end
	
	def self.build_register_n(sim, n, on_clock = :high, initial_values = nil)
				
		raise "invalid initial_data #{initial_values} / #{initial_values.size}" if initial_values and (initial_values.size != 8)
	
		cg = ComponentGroup.new(n + 1,n)
		
		b = sim.register_component(BufferGate.new) #load		
				
		(0...n).each do |idx|
			#internal components
			if initial_values
				bit = build_bit_register(sim, on_clock, (["1","T"].include? initial_values[idx]))
			else
				bit = build_bit_register(sim, on_clock)
			end
			
			#internal wiring
			bit.set_aliased_input(1, b)
			
			#external wiring
			cg.alias_input(idx, *bit.aliased_input(0))
			cg.alias_output(idx, bit.aliased_output(0))
						
		end
		
		#external wiring
		cg.alias_input(n, b, 0)		
		
		cg
	end
	
	def self.build_bufferset(sim, n)
		cg = ComponentGroup.new(n, n)
		
		(0...n).each do |idx|
			#internal components
			b = sim.register_component(BufferGate.new)
			#internal wiring
			#external wiring
			cg.alias_input(idx, b, 0)
			cg.alias_output(idx, b)
		end
			
		cg
	end
	
	def self.build_encoder8x3(sim) #8 inputs LSB, 3 bit MSB
		cg = ComponentGroup.new(8,3)
		
		#internal components
		b = build_bufferset(sim, 8)
		sel = Array.new(3) do build_or4_gate(sim) end

		#internal wiring
		sel[0].set_aliased_input(0, *b.aliased_output(0))
		sel[0].set_aliased_input(1, *b.aliased_output(1))
		sel[0].set_aliased_input(2, *b.aliased_output(2))
		sel[0].set_aliased_input(3, *b.aliased_output(3))
		
		sel[1].set_aliased_input(0, *b.aliased_output(0))
		sel[1].set_aliased_input(1, *b.aliased_output(1))
		sel[1].set_aliased_input(2, *b.aliased_output(4))
		sel[1].set_aliased_input(3, *b.aliased_output(5))
		
		sel[2].set_aliased_input(0, *b.aliased_output(0))
		sel[2].set_aliased_input(1, *b.aliased_output(2))
		sel[2].set_aliased_input(2, *b.aliased_output(4))
		sel[2].set_aliased_input(3, *b.aliased_output(6))
		
		#external wiring
		(0...8).each do |idx|
			cg.alias_input(7 - idx, *b.aliased_input(idx))
		end
		(0...3).each do |idx|
			cg.alias_output(idx, *sel[idx].aliased_output(0))
		end

		cg
	end
	
	def self.build_halfadder(sim)
		cg = ComponentGroup.new(2,2) # b0, b1 > sum, carry
		
		#internal components
		x = sim.register_component(XorGate.new)
		a = sim.register_component(AndGate.new)		
		b1 = sim.register_component(BufferGate.new)
		b2 = sim.register_component(BufferGate.new)
		
		#internal wiring
		x.set_inputs([b1,b2])
		a.set_inputs([b1,b2])
		
		#external wiring
		cg.alias_input(0, b1, 0)
		cg.alias_input(1, b2, 0)
		cg.alias_output(0, x)
		cg.alias_output(1, a)
		
		cg
	end
	
	def self.build_fulladder(sim)
		cg = ComponentGroup.new(3,2) # b0, b1, carry-in > sum, carry-out
		
		#internal components
		x1 = sim.register_component(XorGate.new)
		x2 = sim.register_component(XorGate.new)
		a1 = sim.register_component(AndGate.new)
		a2 = sim.register_component(AndGate.new)
		a3 = sim.register_component(AndGate.new)
		o1 = sim.register_component(OrGate.new)
		o2 = sim.register_component(OrGate.new)
		b1 = sim.register_component(BufferGate.new)
		b2 = sim.register_component(BufferGate.new)
		b3 = sim.register_component(BufferGate.new)
		
		#internal wiring		
		o1.set_inputs([a1,a2])
		o2.set_inputs([o1,a3])
		a1.set_inputs([b1,b2])
		a2.set_inputs([b1,b3])
		a3.set_inputs([b2,b3])
		x2.set_inputs([x1,b3])
		x1.set_inputs([b1,b2])
		
		#external wiring
		cg.alias_input(0, b1, 0)
		cg.alias_input(1, b2, 0)
		cg.alias_input(2, b3, 0)
		cg.alias_output(0, x2)
		cg.alias_output(1, o2)
		
		cg
	end
	
	def self.build_fulladder_n(sim, n = 8)
		cg = ComponentGroup.new(n * 2 + 1,n + 1) # addend 1, addend 2, carry-in > output 8 (MSB) , carry-out

		#internal components		
		#idx = 0 (MSB)	
		fas = Array.new(n) do |i|
			fa = ComponentGroup.build_fulladder(sim)
		end
				
		
		#internal wiring			
		#connect carry-in to carry-out of previous adder		
		(0...(n-1)).each do |idx|
			fas[idx].set_aliased_input(2, *fas[idx+1].aliased_output(1))
		end
			
		#external wiring
		(0...n).each do |idx|
			cg.alias_input(idx, *fas[idx].aliased_input(0))
			cg.alias_input(idx+n, *fas[idx].aliased_input(1))
			cg.alias_output(idx, *fas[idx].aliased_output(0))			
		end			
		
		cg.alias_input(n*2, *fas[n-1].aliased_input(2))
		cg.alias_output(n, fas[0].aliased_output(1))
		
		cg		
	end
	
	def self.build_fulladdersub8(sim)
		cg = ComponentGroup.new(17,9) # addend 1, addend 2, sub? > output 8 (MSB) , carry-out
	
		#internal components	 
		fa = ComponentGroup.build_fulladder_n(sim, 8)
		x = Array.new(8) do |g| sim.register_component(XorGate.new) end
		b = sim.register_component(BufferGate.new)
		
		#internal wiring	
		(0...8).each do |idx|
			x[idx].set_input(1, b)
			fa.set_aliased_input(8+idx, x[idx])
		end
		fa.set_aliased_input(16, b)
		
		#external wiring
		(0...8).each do |idx|
			cg.alias_input(idx, *fa.aliased_input(idx))
			cg.alias_input(idx+8, x[idx], 0)
			cg.alias_output(idx, fa.aliased_output(idx))
		end			
		
		cg.alias_input(16, b, 0)
		cg.alias_output(8, *fa.aliased_output(8))
		
		cg
	end
	
	def self.build_mux2(sim)
		cg = ComponentGroup.new(3,1)
		
		#internal components
		addr = sim.register_component(BufferGate.new)
		n = sim.register_component(NotGate.new)
		a1 = sim.register_component(AndGate.new)
		a2 = sim.register_component(AndGate.new)
		o = sim.register_component(OrGate.new)
		
		#internal wiring
		n.set_input(0,addr)
		
		a1.set_input(1,n)
		a2.set_input(1,addr)
		o.set_inputs([a1,a2])
				
		#external wiring
		cg.alias_input(0, a1, 0)
		cg.alias_input(1, a2, 0)
		cg.alias_input(2, addr, 0)
		cg.alias_output(0, o)

		cg
	end

	def self.build_mux4(sim)
		cg = ComponentGroup.new(6,1)
		
		#internal components
		m1 = ComponentGroup.build_mux2(sim)
		m2 = ComponentGroup.build_mux2(sim)
		b = sim.register_component(BufferGate.new)
		out = ComponentGroup.build_mux2(sim)
		
		#internal wiring
		out.set_aliased_input(0, m1.aliased_output(0))
		out.set_aliased_input(1, m2.aliased_output(0))
		m1.set_aliased_input(2, b)
		m2.set_aliased_input(2, b)
		
		#external wiring
		cg.alias_input(0, *m1.aliased_input(0))
		cg.alias_input(1, *m1.aliased_input(1))
		cg.alias_input(2, *m2.aliased_input(0))
		cg.alias_input(3, *m2.aliased_input(1))
		cg.alias_input(4, *out.aliased_input(2))
		cg.alias_input(5, b, 0)
		cg.alias_output(0, out.aliased_output(0))
				
		cg
	end

	def self.build_mux8(sim)
		cg = ComponentGroup.new(11,1)
		
		#internal components		
		m1 = ComponentGroup.build_mux4(sim)
		m2 = ComponentGroup.build_mux4(sim)
		b1 = sim.register_component(BufferGate.new)
		b2 = sim.register_component(BufferGate.new)		
		out = ComponentGroup.build_mux2(sim)
		
		#internal wiring
		out.set_aliased_input(0, m1.aliased_output(0))
		out.set_aliased_input(1, m2.aliased_output(0))
		m1.set_aliased_input(4, b1)
		m1.set_aliased_input(5, b2)
		m2.set_aliased_input(4, b1)
		m2.set_aliased_input(5, b2)
				
		#external wiring
		cg.alias_input(0, *m1.aliased_input(0))
		cg.alias_input(1, *m1.aliased_input(1))
		cg.alias_input(2, *m1.aliased_input(2))
		cg.alias_input(3, *m1.aliased_input(3))
		cg.alias_input(4, *m2.aliased_input(0))
		cg.alias_input(5, *m2.aliased_input(1))
		cg.alias_input(6, *m2.aliased_input(2))
		cg.alias_input(7, *m2.aliased_input(3))
		cg.alias_input(8, *out.aliased_input(2)) # high bit selects between the two mux4s.
		cg.alias_input(9, b1, 0)
		cg.alias_input(10, b2, 0)		
		cg.alias_output(0, out.aliased_output(0))
						
		cg
	end
	
	def self.build_mux16(sim)
		cg = ComponentGroup.new(20,1)
		
		#internal components
		m = Array.new(4) do |n|
			ComponentGroup.build_mux4(sim)
		end
		
		addr = ComponentGroup.build_bufferset(sim, 4)
		out = ComponentGroup.build_mux4(sim)		
		
		#internal wiring
		out.set_aliased_input(0, m[0].aliased_output(0))
		out.set_aliased_input(1, m[1].aliased_output(0))
		out.set_aliased_input(2, m[2].aliased_output(0))
		out.set_aliased_input(3, m[3].aliased_output(0))		
		out.set_aliased_input(4, addr.aliased_output(0))
		out.set_aliased_input(5, addr.aliased_output(1))		
		(0...4).each do |mi|			
			m[mi].set_aliased_input(4, addr.aliased_output(2))
			m[mi].set_aliased_input(5, addr.aliased_output(3))
		end
		
		#external wiring		
		(0...4).each do |mi|
			(0...4).each do |bi|
				cg.alias_input(mi*4+bi, *m[mi].aliased_input(bi))
			end
		end
		cg.alias_input(16, *addr.aliased_input(0))
		cg.alias_input(17, *addr.aliased_input(1))
		cg.alias_input(18, *addr.aliased_input(2))
		cg.alias_input(19, *addr.aliased_input(3))
		cg.alias_output(0, out.aliased_output(0))		
		
		cg
	end
	
	def self.build_and_n_gate(sim, n)
		cg = ComponentGroup.new(n, 1)
		
		# internal components
		gates = Array.new(n-1) do sim.register_component(AndGate.new) end
		# internal wiring
		(1...(gates.size)).each do |idx|
			gates[idx].set_input(0, gates[idx - 1])
		end
		# external wiring
		cg.alias_input(0, gates[0], 0)
		(1...n).each do |idx|
			cg.alias_input(idx, gates[idx - 1], 1)
		end
		cg.alias_output(0, gates.last)
		
		cg				
	end
	
	def self.build_or_n_gate(sim, n)
		cg = ComponentGroup.new(n, 1)
		
		# internal components
		gates = Array.new(n-1) do sim.register_component(OrGate.new) end
		# internal wiring
		(1...(gates.size)).each do |idx|
			gates[idx].set_input(0, gates[idx - 1])
		end
		# external wiring
		cg.alias_input(0, gates[0], 0)
		(1...n).each do |idx|
			cg.alias_input(idx, gates[idx - 1], 1)
		end
		cg.alias_output(0, gates.last)
		
		cg				
	end
		
	def self.build_mux_n(sim, data_n)		
		
		addr_n = Math.log(data_n, 2).to_i			
		cg = ComponentGroup.new(data_n + addr_n, 1)
				
		#internal components
		a = Array.new(data_n) do ComponentGroup.build_and_n_gate(sim, addr_n + 1) end		
		o = ComponentGroup.build_or_n_gate(sim, data_n)
		
		addr = ComponentGroup.build_bufferset(sim, addr_n)		
		addr_not = Array.new(addr_n) do sim.register_component(NotGate.new) end
		
		#internal wiring			
		(0...addr_n).each do |idx|			
			addr_not[idx].set_input(0, addr.aliased_output(idx))
		end		
		(0...data_n).each do |idx|					
			idx.to_s(2).rjust(addr_n,'0').split("").each_with_index do |signal, ai|
				if signal == '0'			
					a[idx].set_aliased_input(1 + ai, addr_not[ai])
				else										
					a[idx].set_aliased_input(1 + ai, addr.aliased_output(ai))
				end				
			end	
			o.set_aliased_input(idx, a[idx].aliased_output(0))
		end
						
		#external wiring
		(0...data_n).each do |idx|
			cg.alias_input(idx, *a[idx].aliased_input(0))
		end
		(0...addr_n).each do |idx|
			cg.alias_input(data_n + idx, *addr.aliased_input(idx))			
		end
		cg.alias_output(0, o.aliased_output(0))		
				
		cg
	end
	
	def self.build_demux2(sim)
		cg = ComponentGroup.new(2,2)
		
		#internal components
		sel = sim.register_component(BufferGate.new)
		not_sel = sim.register_component(NotGate.new)
		data = sim.register_component(BufferGate.new)
		a1 = sim.register_component(AndGate.new)
		a2 = sim.register_component(AndGate.new)
		
		#internal wiring
		not_sel.set_input(0, sel)
		a1.set_inputs([data,not_sel])
		a2.set_inputs([data,sel])
		
		#external wiring
		cg.alias_input(0, data, 0)
		cg.alias_input(1, sel, 0)
		cg.alias_output(0, a1)
		cg.alias_output(1, a2)
				
		cg
	end
	
	def self.build_demux4(sim)
		cg = ComponentGroup.new(3,4)
		
		#internal components
		d1 = ComponentGroup.build_demux2(sim)
		d2 = ComponentGroup.build_demux2(sim)
		din = ComponentGroup.build_demux2(sim)
		sel = sim.register_component(BufferGate.new)
		
		#internal wiring
		d1.set_aliased_input(0, din.aliased_output(0))
		d1.set_aliased_input(1, sel)
		d2.set_aliased_input(0, din.aliased_output(1))
		d2.set_aliased_input(1, sel)
		
		#external wiring
		cg.alias_input(0, *din.aliased_input(0))
		cg.alias_input(1, *din.aliased_input(1))
		cg.alias_input(2, sel, 0)
		cg.alias_output(0, d1.aliased_output(0))
		cg.alias_output(1, d1.aliased_output(1))
		cg.alias_output(2, d2.aliased_output(0))
		cg.alias_output(3, d2.aliased_output(1))
		
		cg
	end
	
	def self.build_demux8(sim)
		cg = ComponentGroup.new(4,8)
		
		#internal wiring
		d1 = ComponentGroup.build_demux4(sim)
		d2 = ComponentGroup.build_demux4(sim)
		din = ComponentGroup.build_demux2(sim)
		sel1 = sim.register_component(BufferGate.new)
		sel2 = sim.register_component(BufferGate.new)
		
		#internal components
		d1.set_aliased_input(0, din.aliased_output(0))
		d1.set_aliased_input(1, sel1)
		d1.set_aliased_input(2, sel2)
		d2.set_aliased_input(0, din.aliased_output(1))
		d2.set_aliased_input(1, sel1)
		d2.set_aliased_input(2, sel2)
		
		#external wiring
		cg.alias_input(0, *din.aliased_input(0))
		cg.alias_input(1, *din.aliased_input(1))
		cg.alias_input(2, sel1, 0)
		cg.alias_input(3, sel2, 0)
		cg.alias_output(0, d1.aliased_output(0)) # MSB output
		cg.alias_output(1, d1.aliased_output(1))
		cg.alias_output(2, d1.aliased_output(2))
		cg.alias_output(3, d1.aliased_output(3))
		cg.alias_output(4, d2.aliased_output(0))
		cg.alias_output(5, d2.aliased_output(1))
		cg.alias_output(6, d2.aliased_output(2))
		cg.alias_output(7, d2.aliased_output(3))

		cg
	end
				
	def self.build_demux16(sim) # data, addr(4) => outx16
		cg = ComponentGroup.new(5,16)
		
		#internal components
		din = ComponentGroup.build_demux4(sim)
		addr = ComponentGroup.build_bufferset(sim, 4)
		
		d = Array.new(4) do |n|
			ComponentGroup.build_demux4(sim)
		end
				
		#internal wiring		
		din.set_aliased_input(1, addr.aliased_output(0))
		din.set_aliased_input(2, addr.aliased_output(1))
		
		# # set demux address lines
		(0...4).each do |di|
			d[di].set_aliased_input(0, din.aliased_output(di))			
			(0...2).each do |ai|				
				d[di].set_aliased_input(1 + ai, addr.aliased_output(2+ai))
			end
		end
		
		#external wiring
		(0...4).each do |idx|
			cg.alias_input(1 + idx, *addr.aliased_input(idx))			
		end
		cg.alias_input(0, *din.aliased_input(0))		
		(0...4).each do |di|
			(0...4).each do |bi|
				cg.alias_output(di * 4 + bi, d[di].aliased_output(bi))				
			end
		end		

		cg
	end
	
	def self.build_bus8x8(sim) 
		cg = ComponentGroup.new(72,8)
				
		#internal components
		enc = ComponentGroup.build_encoder8x3(sim)
		m = Array.new(8) do ComponentGroup.build_mux8(sim) end
		
		(0...8).each do |idx|		
			# internal wiring			
			m[idx].set_aliased_input(8, enc.aliased_output(0))
			m[idx].set_aliased_input(9, enc.aliased_output(1))
			m[idx].set_aliased_input(10, enc.aliased_output(2))			
			
			# external wiring			
			(0...8).each do |j|
				cg.alias_input(idx + j * 8, *m[idx].aliased_input(j))
			end
			cg.alias_input(64 + idx, *enc.aliased_input(idx))
			cg.alias_output(idx, m[idx].aliased_output(0))
		end
		
		$debug = {bus: [enc, m]}
		
		cg
	end
		
	def self.build_ram8x8(sim, on_clock = :high, initial_data = nil) #data 8 MSB, 3 addr MSB, 1 load
		cg = ComponentGroup.new(12,8)
		
		#internal components
		data = Array.new(8) do sim.register_component(BufferGate.new) end
		addr0 = sim.register_component(BufferGate.new)		
		addr1 = sim.register_component(BufferGate.new)
		addr2 = sim.register_component(BufferGate.new)
		load = ComponentGroup.build_demux8(sim)		
		r = Array.new(8) do |idx|			
			ComponentGroup.build_register_n(sim, 8, on_clock, initial_data ? initial_data[idx] : nil)		
		end
		m = Array.new(8) do ComponentGroup.build_mux8(sim) end
		
		#internal wiring
		load.set_aliased_input(1, addr0)
		load.set_aliased_input(2, addr1)
		load.set_aliased_input(3, addr2)
		(0...8).each do |idx|					
			(0...8).each do |j|
				m[j].set_aliased_input(idx, r[idx].aliased_output(j))				
				r[idx].set_aliased_input(j, data[j])
			end		
			m[idx].set_aliased_input(8,  addr0)
			m[idx].set_aliased_input(9,  addr1)
			m[idx].set_aliased_input(10, addr2)			
			r[idx].set_aliased_input(8,  load.aliased_output(idx))			
		end	
		
		#external wiring
		(0...8).each do |idx|
			cg.alias_input(idx, data[idx], 0)
			cg.alias_output(idx, m[idx].aliased_output(0))			
		end
		cg.alias_input(8,  addr0, 0)
		cg.alias_input(9,  addr1, 0)
		cg.alias_input(10, addr2, 0)
		cg.alias_input(11, *load.aliased_input(0))		
				
		cg
	end
				
	def self.build_ram8x64(sim, on_clock = :high, initial_data = nil)
		cg = ComponentGroup.new(15,8)
		
		#internal components
		data = Array.new(8) do sim.register_component(BufferGate.new) end
		addr = Array.new(6) do sim.register_component(BufferGate.new) end
		load = ComponentGroup.build_demux8(sim)
		r = Array.new(8) do |idx| 
			ComponentGroup.build_ram8x8(sim, on_clock, initial_data ? initial_data[idx * 8, 8] : nil)
		end
		m = Array.new(8) do ComponentGroup.build_mux8(sim) end
		
		#internal wiring
		load.set_aliased_input(1, addr[0])
		load.set_aliased_input(2, addr[1])
		load.set_aliased_input(3, addr[2])
		
		(0...8).each do |idx|
			(0...8).each do |j|
				r[idx].set_aliased_input(j, data[j])
			end
			r[idx].set_aliased_input(8,  addr[3])
			r[idx].set_aliased_input(9,  addr[4])			
			r[idx].set_aliased_input(10, addr[5])
			r[idx].set_aliased_input(11, load.aliased_output(idx))			
		end		
		
		(0...8).each do |idx|	
			m[idx].set_aliased_input(8,  addr[0])
			m[idx].set_aliased_input(9,  addr[1])
			m[idx].set_aliased_input(10, addr[2])		
			(0...8).each do |j|
				m[j].set_aliased_input(idx, r[idx].aliased_output(j))
			end	
		end
		
		#external wiring
		(0...8).each do |idx|
			cg.alias_input(idx, data[idx], 0)
			cg.alias_output(idx, m[idx].aliased_output(0))
		end
		(0...6).each do |idx|
			cg.alias_input(8 + idx, addr[idx], 0)			
		end
		cg.alias_input(14, *load.aliased_input(0))		
			
		cg
	end
	
	def self.build_ram8x256(sim, on_clock = :high, initial_data = nil) 
		cg = ComponentGroup.new(17,8)
		
		#internal components
		data = Array.new(8) do sim.register_component(BufferGate.new) end
		addr = Array.new(8) do sim.register_component(BufferGate.new) end
		r = Array.new(4) do |idx| ComponentGroup.build_ram8x64(sim, on_clock, initial_data ? initial_data[idx * 64, 64] : nil) end
		load = ComponentGroup.build_demux4(sim)
		m = Array.new(8) do ComponentGroup.build_mux4(sim) end
		
		#internal wiring
		load.set_aliased_input(1,addr[0])
		load.set_aliased_input(2,addr[1])				
		(0...4).each do |mi|
            (0...8).each do |bi|
				r[mi].set_aliased_input(bi, data[bi])
			end
			r[mi].set_aliased_input(8, addr[2]) 
			r[mi].set_aliased_input(9, addr[3])
			r[mi].set_aliased_input(10,addr[4])
			r[mi].set_aliased_input(11,addr[5]) 
			r[mi].set_aliased_input(12,addr[6])
			r[mi].set_aliased_input(13,addr[7])		
			r[mi].set_aliased_input(14,load.aliased_output(mi))
		end
		(0...8).each do |bi|	
			m[bi].set_aliased_input(4,addr[0])
			m[bi].set_aliased_input(5,addr[1])
			(0...4).each do |mi|
				m[bi].set_aliased_input(mi, r[mi].aliased_output(bi))
			end				
		end
		
		#external wiring
		(0...8).each do |idx|
			cg.alias_input(idx, data[idx], 0)
			cg.alias_input(idx + 8, addr[idx], 0)
			cg.alias_output(idx, m[idx].aliased_output(0))			
		end
		cg.alias_input(16, *load.aliased_input(0))
		
		cg
	end

	def self.build_ram8x1024(sim, on_clock = :high, initial_data = nil) 
		cg = ComponentGroup.new(19,8)
		
		#internal components		
		data = ComponentGroup.build_bufferset(sim,8)
		addr = ComponentGroup.build_bufferset(sim,10)
		load = ComponentGroup.build_demux4(sim)
		r = Array.new(4) do |idx| ComponentGroup.build_ram8x256(sim, on_clock, initial_data ? initial_data[idx * 256, 256] : nil) end
		m = Array.new(8) do ComponentGroup.build_mux4(sim) end
		
		#internal wiring
		load.set_aliased_input(1, addr.aliased_output(0))
		load.set_aliased_input(2, addr.aliased_output(1))
		(0...4).each do |mi|
            (0...8).each do |bi|
				r[mi].set_aliased_input(bi, data.aliased_output(bi))
			end
			r[mi].set_aliased_input(8 , addr.aliased_output(2)) 
			r[mi].set_aliased_input(9 , addr.aliased_output(3))
			r[mi].set_aliased_input(10, addr.aliased_output(4))
			r[mi].set_aliased_input(11, addr.aliased_output(5)) 
			r[mi].set_aliased_input(12, addr.aliased_output(6))
			r[mi].set_aliased_input(13, addr.aliased_output(7))			
			r[mi].set_aliased_input(14, addr.aliased_output(8))
			r[mi].set_aliased_input(15, addr.aliased_output(9))	
			r[mi].set_aliased_input(16, load.aliased_output(mi))  # output 0 is lsb for a demux			
		end
		
		(0...8).each do |bi|	
			m[bi].set_aliased_input(4,addr.aliased_output(0))
			m[bi].set_aliased_input(5,addr.aliased_output(1))
			(0...4).each do |mi|
				m[bi].set_aliased_input(mi, r[mi].aliased_output(bi))	
			end			
		end	
		
		#external wiring
		cg.alias_input(18, *load.aliased_input(0))
			
		(0...8).each do |idx|
			cg.alias_input(idx, *data.aliased_input(idx))
			cg.alias_output(idx, m[idx].aliased_output(0))
		end
		(0...10).each do |ai|
			cg.alias_input(ai + 8, *addr.aliased_input(ai))			
		end

		cg
	end
	
	def self.build_counter_n(sim, n = 8)
		cg = ComponentGroup.new(n + 2, n)
		
		#internal components
		r = ComponentGroup.build_register_n(sim, n)
		add = ComponentGroup.build_fulladder_n(sim, n)
		m = Array.new(n) do ComponentGroup.build_mux2(sim) end
		inc = sim.register_component(BufferGate.new)
		jmp = sim.register_component(BufferGate.new)
		carryin = sim.register_component(OrGate.new)
		
		#internal wiring
		(0...n).each do |idx|
			m[idx].set_aliased_input(0, add.aliased_output(idx))
			m[idx].set_aliased_input(2, jmp)						
			r.set_aliased_input(idx, m[idx].aliased_output(0))
			add.set_aliased_input(idx, r.aliased_output(idx))
			add.set_aliased_input(n+idx, Simulation::FALSE)
		end
		r.set_aliased_input(n, inc)
		carryin.set_input(0, inc)
		carryin.set_input(1, jmp)
		add.set_aliased_input(n*2, inc)
		
		#external wiring
		(0...n).each do |idx|
			cg.alias_input(idx, *m[idx].aliased_input(1))
			cg.alias_output(idx, r.aliased_output(idx))
		end
		
		cg.alias_input(n, inc, 0)
		cg.alias_input(n+1, jmp, 0)
		
		cg
	end
	
	def self.build_counter_register_n(sim, n, on_clock = :high) 
		cg = ComponentGroup.new(n+3,n) # jump, enable, zero
		
		#internal components		
		jump = sim.register_component(BufferGate.new)
		zero = sim.register_component(BufferGate.new)
		r = ComponentGroup.build_register_n(sim, n, on_clock)		
		m = Array.new(n) do ComponentGroup.build_mux4(sim) end		
		add = ComponentGroup.build_fulladder_n(sim, 4)
				
		#internal wiring
		(0...n).each do |bit|			
			m[bit].set_aliased_input(0, add.aliased_output(bit))
			m[bit].set_aliased_input(2, Simulation::FALSE)
			m[bit].set_aliased_input(3, Simulation::FALSE)			
			m[bit].set_aliased_input(4, zero)
			m[bit].set_aliased_input(5, jump)			
			
			# add current value plus zero
			add.set_aliased_input(bit, r.aliased_output(bit))
			add.set_aliased_input(n + bit, Simulation::FALSE)
			
			r.set_aliased_input(bit, m[bit].aliased_output(0))
		end		
		
		add.set_aliased_input(n*2, Simulation::TRUE) # carry in 1

		#external wiring
		cg.alias_input(n, jump, 0)
		cg.alias_input(n+1, *r.aliased_input(4))
		cg.alias_input(n+2, zero, 0)
		(0...n).each do |bit|
			cg.alias_input(bit, *m[bit].aliased_input(1))
			cg.alias_output(bit, r.aliased_output(bit))
		end		
		
		cg
	end
	
	def self.build_rom_n(sim, n, data)
		raise "bad data size #{n} != #{data.size}" unless data.size == n
		
		cg = ComponentGroup.new(0, n)
		
		(0...n).each do |idx|			
			if ["T", "1"].include? data[idx]
				cg.alias_output(idx, Simulation::TRUE)
			elsif ["F", "0"].include? data[idx]
				cg.alias_output(idx, Simulation::FALSE)
			else
				raise "invalid data #{data}"
			end
		end
		cg
	end
	
	# addr_n determines how many units we store
	# output_n determines how wide each address is, likely 8-bit
	def self.build_rom_n_m(sim, addr_n, output_n, data)
		cg = ComponentGroup.new(addr_n, output_n)
		data_n = addr_n ** 2
		#internal components
		# 0, n
		addr = ComponentGroup.build_bufferset(sim, addr_n)
		rom = Array.new( data_n ) do |idx| 	ComponentGroup.build_rom_n(sim,output_n,data[idx]) end
		# output bits + ln bits, 1
		mux = Array.new( output_n ) do ComponentGroup.build_mux_n(sim, data_n) end
		
		#internal wiring
		(0...data_n).each do |di|
			(0...output_n).each do |mi|
				mux[mi].set_aliased_input(di, rom[di].aliased_output(mi))
			end
		end
		(0...output_n).each do |mi|
			(0...addr_n).each do |ai|
				mux[mi].set_aliased_input(data_n + ai, addr.aliased_output(ai))
			end
		end
		
		#external wiring
		(0...addr_n).each do |idx|
			cg.alias_input(idx, *addr.aliased_input(idx))
		end
		(0...output_n).each do |idx|			
			cg.alias_output(idx, mux[idx].aliased_output(0))
		end
		
		cg
	end
	
	def self.build_rom8x16(sim, data)
		cg = ComponentGroup.new(4,8)
		
		#internal components
		m = Array.new(8) do ComponentGroup.build_mux16(sim) end
		rom = Array.new(16) do |idx| ComponentGroup.build_rom_n(sim,8,data[idx]) end
		addr = ComponentGroup.build_bufferset(sim, 4)
		
		#internal wiring		
		(0...8).each do |bit|
			(0...16).each do |idx|			
				m[bit].set_aliased_input(idx, rom[idx].aliased_output(bit))
			end
			(0...4).each do |a|
				m[bit].set_aliased_input(16 + a,addr.aliased_output(a))
			end
		end
		
		#external wiring
		(0...8).each do |bit|
			cg.alias_output(bit, m[bit].aliased_output(0))
		end
		(0...4).each do |bit|
			cg.alias_input(bit, *addr.aliased_input(bit))
		end
		
		cg		
	end
	
	def self.build_rom8x256(sim, data)
		cg = ComponentGroup.new(8,8)
		
		#internal components
		m = Array.new(8) do ComponentGroup.build_mux16(sim) end
		rom = Array.new(16) do |idx| ComponentGroup.build_rom8x16(sim,data[idx*16,16]) end
		addr = ComponentGroup.build_bufferset(sim, 8)
		
		#internal wiring
		(0...16).each do |r|
			(0...4).each do |a|				
				rom[r].set_aliased_input(a, addr.aliased_output(4+a))
			end
		end

		(0...8).each do |bit|
		
			(0...16).each do |r|
				m[bit].set_aliased_input(r, rom[r].aliased_output(bit))
			end
		
			(0...4).each do |a|				
				m[bit].set_aliased_input(16 + a, addr.aliased_output(a))
			end
		end
		
		#external wiring
		(0...8).each do |a|
			cg.alias_input(a, *addr.aliased_input(a))
			cg.alias_output(a, m[a].aliased_output(0))
		end
			
		cg
	end
	
	def self.build_rom8x1024(sim, data)
		cg = ComponentGroup.new(10,8)
		
		#internal components
		m = Array.new(8) do ComponentGroup.build_mux4(sim) end
		rom = Array.new(4) do |idx| ComponentGroup.build_rom8x256(sim,data[idx*256,256]) end
		addr = ComponentGroup.build_bufferset(sim, 10)
		
		#internal wiring
		(0...4).each do |r|
			(0...8).each do |a|				
				rom[r].set_aliased_input(a, addr.aliased_output(2+a))
			end
		end

		(0...8).each do |bit|
			(0...4).each do |r|
				m[bit].set_aliased_input(r, rom[r].aliased_output(bit))
			end
		
			(0...2).each do |a|				
				m[bit].set_aliased_input(4 + a, addr.aliased_output(a))
			end
		end
		
		#external wiring
		(0...10).each do |a|
			cg.alias_input(a, *addr.aliased_input(a))
		end
		(0...8).each do |a|			
			cg.alias_output(a, m[a].aliased_output(0))
		end
				
		cg
	end

	def self.build_microcode(sim, inst_n, cntr_n, output_n, data_in, data_out) 
		
		raise "unsupported output_n #{output_n}" if output_n != 16
		
		cg = ComponentGroup.new(inst_n + cntr_n, output_n)
		
		#internal components
		inst = ComponentGroup.build_bufferset(sim, inst_n)
		cntr = ComponentGroup.build_bufferset(sim, cntr_n)
		
		rom_in = nil
		rom_out = nil
		
		case inst_n + cntr_n
			when 4
				rom_in = ComponentGroup.build_rom8x16(sim, data_in) #4,8
				rom_out = ComponentGroup.build_rom8x16(sim, data_out) #4,8
			when 8
				rom_in = ComponentGroup.build_rom8x256(sim, data_in) #8,8
				rom_out = ComponentGroup.build_rom8x256(sim, data_out) #8,8
			when 10
				rom_in = ComponentGroup.build_rom8x1024(sim, data_in) #10,8
				rom_out = ComponentGroup.build_rom8x1024(sim, data_out) #10,8
			else
				raise "bit size #{inst_n} + #{cntr_n} not supported"
		end
		
		#internal wiring
		(0...inst_n).each do |idx|
			rom_in.set_aliased_input(idx, inst.aliased_output(idx))
			rom_out.set_aliased_input(idx, inst.aliased_output(idx))
		end
		(0...cntr_n).each do |idx|
			rom_in.set_aliased_input(inst_n + idx, cntr.aliased_output(idx))
			rom_out.set_aliased_input(inst_n + idx, cntr.aliased_output(idx))
		end
		
		#external wiring
		(0...inst_n).each do |idx|
			cg.alias_input(idx, *inst.aliased_input(idx))
		end		
		(0...cntr_n).each do |idx|
			cg.alias_input(inst_n + idx, *cntr.aliased_input(idx))
		end
		
		(0...8).each do |idx|
			cg.alias_output(idx, rom_in.aliased_output(idx))
			cg.alias_output(8 + idx, rom_out.aliased_output(idx))			
		end

		cg
	end
			
	def self.build_alu8(sim) 
		cg = ComponentGroup.new(17,8)
		
		#internal components
		add = ComponentGroup.build_fulladdersub8(sim)
		#internal wiring
		#external wiring
		(0...8).each do |idx|
			cg.alias_input(idx, *add.aliased_input(idx))
			cg.alias_input(8 + idx, *add.aliased_input(8 + idx))
			cg.alias_output(idx, add.aliased_output(idx))
		end
		cg.alias_input(16, *add.aliased_input(16))

		cg		
	end
	
end		





# # # ai in load signl
# # # a out signal
# # # b in
# # # b out

# # # 2x 8 inputs
# # # eo out?
# # # substract?






