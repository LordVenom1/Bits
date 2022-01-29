# 555 timer

# on clock pulse, all latches record their values.
# only then, start updating
require 'set'

class Simulation
	MAX_ITERATIONS = 10000
	PORT_FALSE = 0
	PORT_TRUE = 1
	# PORT_CLOCK = 2

	attr_reader :clock

	def initialize()
		@ports = Array.new(2)
		@ports[PORT_FALSE] = false # false
		@ports[PORT_TRUE] = true # true	
		@components = []
		@clock = Clock.new
	end			
	
	def to_s
		@ports.collect do |p|
			p ? '1' : '0'
		end.join("")
	end
	
	def allocate_ports(n)
		@ports = @ports + Array.new(n,false)		
		(@ports.size - n...@ports.size).to_a
	end
	
	def get(idx)
		@ports[idx]
	end
	
	def set(idx, value)
		raise 'read-only' if [PORT_FALSE,PORT_TRUE].include? idx
		raise 'out of range' if idx >= @ports.size
		
		if @ports[idx] != value
			@ports[idx] = value
			@dirty = true
		end
			
		# update/cascade?
	end
	
	def update(update_clock = false)
		@dirty = true
		
		n = MAX_ITERATIONS
	
		while @dirty
			n = n - 1
			raise 'failure to converge' if n == 0
			@dirty = false
			@components.each do |c|
				c.update
			end
		end	

		@clock.pulse if update_clock
	end
	
	def register_component(c, num_ports)
		@components << c
		allocate_ports(num_ports)
	end
	
end

class Clock
	def initialize
		@components = []
	end
	
	def register(c)
		@components << c
	end

	
	def pulse
		@components.each do |c|
			c.pulse
		end
	end
end


class Component
	
	def initialize(sim, num_inputs, num_outputs, reserve = nil)
		@sim = sim
		@num_inputs = num_inputs
		@ports = (Array.new(num_inputs, Simulation::PORT_FALSE)) + @sim.register_component(self, reserve || num_outputs)		
	end
	
	def update
		raise 'must override'
	end
		
	def pulse
	end
	
	def to_s		
		self.class.to_s + ":" + (0...@num_inputs).collect do |idx|			
			@ports[idx].to_s + (@sim.get(@ports[idx]) ? 'T' : 'F')
		end.join(",") + ":" + (@num_inputs...@ports.size).collect do |idx|
			@ports[idx].to_s + (@sim.get(@ports[idx]) ? 'T' : 'F')
		end.join(",")
	end
	
	def	set_input_values(vals)
		raise 'bad set' unless vals.size == @num_inputs
		(0...vals.size).each do |idx|
			set_input_pointer(idx, vals[idx] ? Simulation::PORT_TRUE : Simulation::PORT_FALSE)
		end
	end
	
	def get_output_values		
		(@num_inputs...@ports.size).collect do |p|				
			@sim.get(@ports[p])
		end
	end
		
	def get_output_pointers
		(@num_inputs...@ports.size).collect do |p|				
			@ports[p]
		end
	end
	
	def set_input_pointer(n, idx)
		#validate we're not changing an output?
		raise 'out of range' if n >= @ports.size
		@ports[n] = idx		
	end
	
	def self.label_helper(labels, num_inputs)
		labels.each_with_index do |label,idx|
			define_method(label) do 
				@sim.get(@ports[idx])
			end
			
			if idx < num_inputs then
				define_method(label.to_s + "=") do |val|
					set_input_pointer(@ports[idx], val ? Simulation::PORT_TRUE : Simulation::PORT_FALSE)
				end
			end
		end
	end
	
	# def to_s
		# @inputs.collect do |v| 
			# v ? '0' : '1'
		# end.join("") + ":" +
		# @outputs.collect do |v| 
			# v ? '0' : '1'
		# end.join("")
	# end
	
	# def set_inputs(values)				
		# values = [values] if values.class != Array #put into array if not already
		# raise '# of inputs doesnt match' unless @inputs.size == values.size		
		
		# @inputs = values.collect do |v|
			# raise 'bad value' unless [true,false,0,1].include? v
			# if v == 0
				# false
			# elsif v == 1
				# true
			# else
				# v
			# end
		# end		
		# update
	# end
	
	
	# def get_output(n)
		# raise 'out of range' if n > @outputs.size
		# @outputs[n]
	# end
	
	# def outputs
		# @outputs.to_enum # to_enum prevents modification without making a copy
	# end
	
	# def method_missing(*vals)
		# target = vals.first
		# val = vals[1]
		
		# if target.to_s.end_with? "="			
			# port = @labels[target.to_s.chomp('=').to_sym]
			# super unless port # method missing
			# if port.first == :input 
				# set_input(port.last, val)				
			# elsif port.first == :output
				# raise 'can''t set output directly'
			# else
				# raise 'not sure what to do with port type: ' + port.first
			# end
		# else
			# port = @labels[target]
			# super unless port # method missing
			# if port.first == :input
				# return @inputs[port.last]
			# else
				# return @outputs[port.last]			
			# end
		# end
	# end
end

class OrGate < Component
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update		
		@sim.set(@ports[2], a | b)
	end
	
	label_helper([:a,:b,:x], 2)
end

class AndGate < Component
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update				
		@sim.set(@ports[2], a & b)
	end
	
	label_helper([:a,:b,:x], 2)
end

class NorGate < Component
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update		
		@sim.set(@ports[2], !(a | b))
	end
	
	label_helper([:a,:b,:x], 2)
end

class XorGate < Component
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update		
		@sim.set(@ports[2], (a || b) & (!(a & b)))
	end
	
	label_helper([:a,:b,:x], 2)
end

class NandGate < Component
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update		
		@sim.set(@ports[2], !(a & b))
	end
	
	label_helper([:a,:b,:x], 2)
end

class NotGate < Component
	def initialize(sim)
		super(sim,1,1)
	end 
	
	def update			
		@sim.set(@ports[1], not(a))		
	end
	
	label_helper([:a,:x], 1)
end

## not a real component
class And4Gate < Component
	 def initialize(sim)		
		super(sim,4,1,0)		
		@comps = {}
		@comps[:a1] = AndGate.new(sim)		
		@comps[:a2] = AndGate.new(sim)
		@comps[:ac] = AndGate.new(sim)
		@comps[:ac].set_input_pointer(0,@comps[:a1].get_output_pointers[0])
		@comps[:ac].set_input_pointer(1,@comps[:a2].get_output_pointers[0])
		@ports[4] = @comps[:ac].get_output_pointers[0]
	end
	
	def set_input_pointer(n, idx)
		case n
			when 0
				@comps[:a1].set_input_pointer(0, idx)
			when 1
				@comps[:a1].set_input_pointer(1, idx)
			when 2
				@comps[:a2].set_input_pointer(0, idx)
			when 3
				@comps[:a2].set_input_pointer(1, idx)
		end	
	end
	
	def update
	end
	
	label_helper([:a,:b,:c,:d,:x], 4)
end

class BufferGate < Component
	def initialize(sim)
		super(sim,1,1)
	end 
	
	def update			
		@sim.set(@ports[1], a)		
	end
	
	label_helper([:a,:x], 1)
end
		

 class DataLatch < Component
	def initialize(sim)
		super(sim,1,1)
		sim.clock.register(self)
	end 
	
	label_helper([:set,:value], 1)
	
	def pulse
		@sim.set(@ports[1], set)
	end
	
	def update		
	end	
end

class FullAdderSub8 < Component
	 def initialize(sim)		
		super(sim,17,9,0)	# input: a + b, 17th = sub  output: 8 digits plus carry
		@comps = {}
		@comps[:fa1] = FullAdder.new(sim)		
		@comps[:fa2] = FullAdder.new(sim)
		@comps[:fa3] = FullAdder.new(sim)
		@comps[:fa4] = FullAdder.new(sim)
		@comps[:fa5] = FullAdder.new(sim)
		@comps[:fa6] = FullAdder.new(sim)
		@comps[:fa7] = FullAdder.new(sim)
		@comps[:fa8] = FullAdder.new(sim)
		
		@comps[:x1] = XorGate.new(sim)
		@comps[:x2] = XorGate.new(sim)
		@comps[:x3] = XorGate.new(sim)
		@comps[:x4] = XorGate.new(sim)
		@comps[:x5] = XorGate.new(sim)
		@comps[:x6] = XorGate.new(sim)
		@comps[:x7] = XorGate.new(sim)
		@comps[:x8] = XorGate.new(sim)
		
		@comps[:fa1].set_input_pointer(1, @comps[:x1].get_output_pointers[0])				
		@comps[:fa2].set_input_pointer(1, @comps[:x2].get_output_pointers[0])
		@comps[:fa3].set_input_pointer(1, @comps[:x3].get_output_pointers[0])				
		@comps[:fa4].set_input_pointer(1, @comps[:x4].get_output_pointers[0])				
		@comps[:fa5].set_input_pointer(1, @comps[:x5].get_output_pointers[0])				
		@comps[:fa6].set_input_pointer(1, @comps[:x6].get_output_pointers[0])				
		@comps[:fa7].set_input_pointer(1, @comps[:x7].get_output_pointers[0])				
		@comps[:fa8].set_input_pointer(1, @comps[:x8].get_output_pointers[0])	
			
		@comps[:fa2].set_input_pointer(2, @comps[:fa1].get_output_pointers[1])
		@comps[:fa3].set_input_pointer(2, @comps[:fa2].get_output_pointers[1])
		@comps[:fa4].set_input_pointer(2, @comps[:fa3].get_output_pointers[1])
		@comps[:fa5].set_input_pointer(2, @comps[:fa4].get_output_pointers[1])
		@comps[:fa6].set_input_pointer(2, @comps[:fa5].get_output_pointers[1])
		@comps[:fa7].set_input_pointer(2, @comps[:fa6].get_output_pointers[1])
		@comps[:fa8].set_input_pointer(2, @comps[:fa7].get_output_pointers[1])
		
		@ports[17] = @comps[:fa1].get_output_pointers[0]
		@ports[18] = @comps[:fa2].get_output_pointers[0]
		@ports[19] = @comps[:fa3].get_output_pointers[0]
		@ports[20] = @comps[:fa4].get_output_pointers[0]
		@ports[21] = @comps[:fa5].get_output_pointers[0]
		@ports[22] = @comps[:fa6].get_output_pointers[0]
		@ports[23] = @comps[:fa7].get_output_pointers[0]
		@ports[24] = @comps[:fa8].get_output_pointers[0]
		@ports[25] = @comps[:fa8].get_output_pointers[1]
	end
	
	def update
	end
	
	def set_input_pointer(n, idx)		
		@ports[n] = idx
		case n
			when 0
				@comps[:fa1].set_input_pointer(0, idx)
			when 1
				@comps[:fa2].set_input_pointer(0, idx)
			when 2
				@comps[:fa3].set_input_pointer(0, idx)
			when 3
				@comps[:fa4].set_input_pointer(0, idx)
			when 4
				@comps[:fa5].set_input_pointer(0, idx)
			when 5
				@comps[:fa6].set_input_pointer(0, idx)
			when 6
				@comps[:fa7].set_input_pointer(0, idx)
			when 7
				@comps[:fa8].set_input_pointer(0, idx)				
			when 8
				@comps[:x1].set_input_pointer(0, idx)				
			when 9
				@comps[:x2].set_input_pointer(0, idx)
			when 10
				@comps[:x3].set_input_pointer(0, idx)				
			when 11
				@comps[:x4].set_input_pointer(0, idx)				
			when 12
				@comps[:x5].set_input_pointer(0, idx)				
			when 13
				@comps[:x6].set_input_pointer(0, idx)				
			when 14
				@comps[:x7].set_input_pointer(0, idx)				
			when 15
				@comps[:x8].set_input_pointer(0, idx)		
			when 16	
				
				@comps[:fa1].set_input_pointer(2, idx)
				@comps[:x1].set_input_pointer(1, idx)				
				@comps[:x2].set_input_pointer(1, idx)
				@comps[:x3].set_input_pointer(1, idx)				
				@comps[:x4].set_input_pointer(1, idx)				
				@comps[:x5].set_input_pointer(1, idx)				
				@comps[:x6].set_input_pointer(1, idx)				
				@comps[:x7].set_input_pointer(1, idx)				
				@comps[:x8].set_input_pointer(1, idx)			
		end	
	end
end

class HalfAdder < Component
	 def initialize(sim)		
		super(sim,2,2,0)		
		@comps = {}
		@comps[:xor] = XorGate.new(sim)		
		@comps[:and] = AndGate.new(sim)
		@ports[2] = @comps[:xor].get_output_pointers[0]
		@ports[3] = @comps[:and].get_output_pointers[0]
	end
	
	def update
	end
	
	def set_input_pointer(n, idx)
		@ports[n] = idx
		case n
			when 0
				@comps[:xor].set_input_pointer(0, idx)
				@comps[:and].set_input_pointer(0, idx)
			when 1
				@comps[:xor].set_input_pointer(1, idx)
				@comps[:and].set_input_pointer(1, idx)
		end	
	end
	
	label_helper([:a,:b,:sum,:carry],2)
end

class FullAdder < Component
	 def initialize(sim)		
		super(sim,3,2,0)		
		@comps = {}
		@comps[:x1] = XorGate.new(sim)
		@comps[:x2] = XorGate.new(sim)
		@comps[:a1] = AndGate.new(sim)
		@comps[:a2] = AndGate.new(sim)
		@comps[:a3] = AndGate.new(sim)
		@comps[:o1] = OrGate.new(sim)
		@comps[:o2] = OrGate.new(sim)
		
		@comps[:x2].set_input_pointer(0, @comps[:x1].get_output_pointers[0])
		
		@comps[:o1].set_input_pointer(0, @comps[:a1].get_output_pointers[0])
		@comps[:o1].set_input_pointer(1, @comps[:a2].get_output_pointers[0])
		@comps[:o2].set_input_pointer(0, @comps[:o1].get_output_pointers[0])
		@comps[:o2].set_input_pointer(1, @comps[:a3].get_output_pointers[0])
		
		@ports[3] = @comps[:x2].get_output_pointers[0]
		@ports[4] = @comps[:o2].get_output_pointers[0]
	end
	
	def update
	end
	
	def set_input_pointer(n, idx)
		@ports[n] = idx
		case n
			when 0
				@comps[:a1].set_input_pointer(0, idx)
				@comps[:a2].set_input_pointer(0, idx)
				@comps[:x1].set_input_pointer(0, idx)				
			when 1
				@comps[:a1].set_input_pointer(1, idx)
				@comps[:a3].set_input_pointer(0, idx)
				@comps[:x1].set_input_pointer(1, idx)	
			when 2
				@comps[:a2].set_input_pointer(1, idx)
				@comps[:a3].set_input_pointer(1, idx)
				@comps[:x2].set_input_pointer(1, idx)				
		end	
	end
	
	label_helper([:a,:b,:c,:sum,:carry],3)
end
