# 555 timer

# on clock pulse, all latches record their values.
# only then, start updating
require 'set'

class Simulation
	MAX_ITERATIONS = 10000

	attr_reader :clock
	attr_reader :false_signal, :true_signal

	def initialize()
		@components = []
		@clock = Clock.new
		
		@false_signal = FalseSignal.new(self)
		@true_signal = TrueSignal.new(self)
	end			
	
	def to_s
		components.collect do |c|
			c.to_s
		end.join("\n")
	end
	
	def mark_dirty
		@dirty = true
	end
	
	def update()
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

		@clock.pulse
	end
	
	def register_component(c)
		@components << c
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


class CoreComponent

	attr_reader :inputs # debug

	def initialize(sim, num_inputs, num_outputs)	
		@sim = sim
		
		@inputs = Array.new(num_inputs)  # stores a pointer to an output
		@outputs = Array.new(num_outputs, false) # stores an actual value (true/false)
		
		(0...num_inputs).each do |idx|
			@inputs[idx] = [@sim.false_signal,0] # does this name sense?
		end
		
		@sim.register_component(self)
	end
	
	def update
		raise 'must override'
	end	
		
	def pulse
	end
	
	# inputs are always pointers even for core components
	def connect_input_to_output(idx, obj, oidx)
		@inputs[idx] = [obj,oidx] # set 
	end
	
	# for core components, no need to set indirection.
	def set_input_to_output(idx, obj, oidx)
		connect_input_to_output(idx,obj,oidx)
	end
	
	# redirecting output isn't valid for core components
	def connect_output_to_output(idx,obj,oidx)
		raise 'not implemented'
	end
	
	# core componetns have real outputs
	def get_output(idx)
		@outputs[idx]
	end
	
	# core components still have to dereference inputs to grab the output
	def get_input(idx)
		@inputs[idx].first.send(:get_output, @inputs[idx].last)
	end
		
	def to_s
		self.class.to_s + ":" + (0...@inputs.size).collect do |i| 
			get_input(i) ? 'T' : 'F'
		end.join("") + ":" + (0...@outputs.size).collect do |i|
			get_output(i) ? 'T' : 'F'
		end.join("")
	end
		# @inputs.collect do |i|
			# "<#{i.first.class.to_s}>-#{i.last.to_s}"
		# end.join(",") + ":" + @outputs.collect do |i|
			# "#{i}"
		# end.join(",")
	# end
	
	# helper to mass assign inputs
	def set_input_values(vals)		
		raise 'bad input' unless vals.size == @inputs.size
		vals.each_with_index do |val,idx|
		
			signal = [0,'0','F',false].include?(val) ? @sim.false_signal : @sim.true_signal
			set_input_to_output(idx, signal, 0)
		end
	end
			
	# helper to get all outputs
	def get_outputs()		
		(0...@outputs.size).collect do |idx|
			get_output(idx)
		end
	end
	
	def self.label_helper(labels, num_inputs)
		# labels.each_with_index do |label,idx|
			# define_method(label) do 
				# @sim.get(@ports[idx])
			# end
			
			# if idx < num_inputs then
				# define_method(label.to_s + "=") do |val|
					# set_input_pointer(@ports[idx], val ? Simulation::PORT_TRUE : Simulation::PORT_FALSE)
				# end
			# end
		# end
	end
end

class Component < CoreComponent
	def initialize(sim, num_inputs, num_outputs)
		super
	end
	
	def update
	end
	
	# non-core components have inputs that point to core inputs, which then point to core outputs
	def connect_input_to_input(idx, input, i)
		@inputs[idx] = [input, i]  #use this to redirect...
	end
	
	# deref the input, then change that input to the given output
	def connect_input_target_to_output(idx, obj, oidx)
		@inputs[idx].first.send(:connect_input_to_output, @inputs[idx].last, obj,oidx)
	end
	
	# for core components, no need to set indirection.
	def set_input_to_output(idx, obj, oidx)
		connect_input_target_to_output(idx,obj,oidx)
	end
		
	# non-core components have outputs that point to core outputs 
	def connect_output_to_output(idx, output, i)
		@outputs[idx] = [output, i]
	end
	
	def get_output(idx)
		@outputs[idx].first.send(:get_output, @outputs[idx].last)
	end
	
	# core components still have to dereference inputs to grab the output
	def get_input(idx)
		@inputs[idx].first.send(:get_output, @inputs[idx].last)
	end
end

class FalseSignal < CoreComponent
	def initialize(sim)
		super(sim,0,1)		
		@outputs[0] = false
	end
	def update
	end
end 

class TrueSignal < CoreComponent
	def initialize(sim)
		super(sim,0,1)
		@outputs[0] = true
	end
	def update
	end
end 

class OrGate < CoreComponent
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update
		prev = @outputs[0]
		@outputs[0] = get_input(0) | get_input(1)
		@sim.mark_dirty if @outputs[0] != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class AndGate < CoreComponent
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update
		prev = @outputs[0]
		@outputs[0] = get_input(0) & get_input(1)
		@sim.mark_dirty if @outputs[0] != prev
	end
		
	label_helper([:a,:b,:x], 2)
end

class NorGate < CoreComponent
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update	
		prev = @outputs[0]	
		@outputs[0] = !(get_input(0) | get_input(1))
		@sim.mark_dirty if @outputs[0] != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class XorGate < CoreComponent
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update		
		prev = @outputs[0]
		a = get_input(0)
		b = get_input(1)		
		@outputs[0] = (a | b) & (!(a & b))
		@sim.mark_dirty if @outputs[0] != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class NandGate < CoreComponent
	def initialize(sim)
		super(sim,2,1)
	end 
	
	def update	
		prev = @outputs[0]
		a = get_input(0)
		b = get_input(1)	
		@outputs[0] = !(a & b)
		@sim.mark_dirty if @outputs[0] != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class NotGate < CoreComponent
	def initialize(sim)
		super(sim,1,1)
	end 
	
	def update
		prev = @outputs[0]
		@outputs[0] = not(get_input(0))
		@sim.mark_dirty if @outputs[0] != prev
	end
	
	label_helper([:a,:x], 1)
end

## not a real component
class And4Gate < Component
	 def initialize(sim)		
		super(sim,4,1)		
		
		a1 = AndGate.new(sim)		
		a2 = AndGate.new(sim)
		ac = AndGate.new(sim)
		
		ac.connect_input_to_output(0,a1,0)
		ac.connect_input_to_output(1,a2,0)
		
		connect_input_to_input(0, a1, 0) 
		connect_input_to_input(1, a1, 1)
		connect_input_to_input(2, a2, 0)
		connect_input_to_input(3, a2, 1)
		connect_output_to_output(0, ac, 0)
	end
	
	# def to_s
		# ['debug:',super,@comps[:a1].to_s,@comps[:a2].to_s,@comps[:ac].to_s].join("\n")
	# end
	
	label_helper([:a,:b,:c,:d,:x], 4)
end

class BufferGate < CoreComponent
	def initialize(sim)
		super(sim,1,1)
	end 
	
	def update	
		prev = @outputs[0]
		@outputs[0] = get_input(0)		
		@sim.mark_dirty if @outputs[0] != prev
	end
		
	label_helper([:a,:x], 1)
end
		

 class DataLatch < CoreComponent
	def initialize(sim)
		super(sim,1,1)
		sim.clock.register(self)
	end 
	
	label_helper([:set,:value], 1)
	
	def pulse		
		@outputs[0] = get_input(0)	
	end
	
	def update		
	end	
end

class Register < Component
	def initialize(sim)
		super(sim,2,1)  # load, enable (removed for now
				
		b = BufferGate.new(sim) # load
		n = NotGate.new(sim)
		a1 = AndGate.new(sim)
		a2 = AndGate.new(sim)
		o = OrGate.new(sim)
		@dl = DataLatch.new(sim)
		
		n.connect_input_to_output(0,b,0)
		a1.connect_input_to_output(0, @dl, 0)
		a1.connect_input_to_output(1, n, 0)
		a2.connect_input_to_output(0, b, 0)	
		o.connect_input_to_output(0,a1,0)
		o.connect_input_to_output(1,a2,0)
		@dl.connect_input_to_output(0,o,0)
		
		connect_input_to_input(0,a2,1)		
		connect_input_to_input(1,b,0)
		connect_output_to_output(0,@dl,0)
		
		#@b,@n,@a1,@a2,@o,@dl = b,n,a1,a2,o,dl
		# enable 0 means don't send any inputs to bus???
		# tri-state-buffer?
		# multiplexor instead?
	end
		
	def to_s
		super
		#[super, @b.to_s,@n.to_s,@a1.to_s,@a2.to_s,@o.to_s,@dl.to_s].join("\n\t")
	end
end
		
# failure, nested components with non core sub components still don't work... :(:(:(
class Register8 < Component
	def initialize(sim)
		super(sim,9,8)  # 8 bit, load.  deal with enabled downstream on input to bus?
		
		b = BufferGate.new(sim)
		connect_input_to_input(8, b, 0)		
		
		r = Array.new(8) do Register.new(sim) end
		(0...8).each do |idx|
			connect_input_to_input(idx,r[idx],0)
			connect_output_to_output(idx,r[idx].dl,0)
			r[idx].connect_input_to_output(1, b, 0)
		end		
		
		@b = b
		@r = r
	end
	
	def to_s
		([super,@b.to_s] + @r.collect do |x| x.to_s end).join("\n\t")
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
		
		x1 = XorGate.new(sim)
		x2 = XorGate.new(sim)
		@comps[:x3] = XorGate.new(sim)
		@comps[:x4] = XorGate.new(sim)
		@comps[:x5] = XorGate.new(sim)
		@comps[:x6] = XorGate.new(sim)
		@comps[:x7] = XorGate.new(sim)
		@comps[:x8] = XorGate.new(sim)
		
		@comps[:fa1].set_input_pointer(1, x1.get_output_pointers[0])				
		@comps[:fa2].set_input_pointer(1, x2.get_output_pointers[0])
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
				x1.set_input_pointer(0, idx)				
			when 9
				x2.set_input_pointer(0, idx)
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
				x1.set_input_pointer(1, idx)				
				x2.set_input_pointer(1, idx)
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
		super(sim,2,2)
		
		x = XorGate.new(sim)		
		a = AndGate.new(sim)

		b1 = BufferGate.new(sim)
		b2 = BufferGate.new(sim)
		
		x.connect_input_to_output(0,b1,0)
		x.connect_input_to_output(1,b2,0)
		
		a.connect_input_to_output(0,b1,0)		
		a.connect_input_to_output(1,b2,0)
				
		connect_input_to_input(0,b1,0)		
		connect_input_to_input(1,b2,0)
		connect_output_to_output(0,x,0)
		connect_output_to_output(1,a,0)

		@a = a
		@x = x
		@b1 = b1
		@b2 = b2
	end
	
	def to_s
		['debug:',super,@x.to_s,@a.to_s,@b1.to_s,@b2.to_s].join("\n")
	end
	
	label_helper([:a,:b,:sum,:carry],2)
end

class FullAdder < Component
	 def initialize(sim)		
		super(sim,3,2)		
		x1 = XorGate.new(sim)
		x2 = XorGate.new(sim)
		a1 = AndGate.new(sim)
		a2 = AndGate.new(sim)
		a3 = AndGate.new(sim)
		o1 = OrGate.new(sim)
		o2 = OrGate.new(sim)
		
		x2.connect_input_to_output(0, x1, 0)
		
		o1.connect_input_to_output(0, a1, 0)
		o1.connect_input_to_output(1, a2, 0)		
		o1.connect_input_to_output(0, o1, 0)
		o1.connect_input_to_output(1, a3, 0)
		
		connect_output_to_output(0,x2,0)
		connect_output_to_output(1,o2,0)
		
		b1 = BufferGate.new(sim)
		b2 = BufferGate.new(sim)
		b3 = BufferGate.new(sim)
		
		connect_input_target_to_input(0,b1,0)
		connect_input_target_to_input(1,b2,0)		
		connect_input_target_to_input(2,b3,0)
		
		a1.connect_input(0,b1,0)
		a2.connect_input(0,b1,0)
		x1.connect_input(0,b1,0)

		a1.connect_input(1,b2,0)
		a3.connect_input(0,b2,0)
		x1.connect_input(1,b2,0)

		a2.connect_input(1,b3,0)
		a3.connect_input(1,b3,0)
		x2.connect_input(1,b3,0)
		
	end
	
	label_helper([:a,:b,:c,:sum,:carry],3)
end
