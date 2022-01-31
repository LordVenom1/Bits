# 555 timer

# on clock pulse, all latches record their values.
# only then, start updating
require 'set'

class InputAbstract
	def initialize
		@target = nil
	end
	
	def alias(input)
		@target = input # recurse
	end
	
	def set_source(output)
		@target.set_source(output)
	end	
	
	def get_value()
		@target.get_value() # from output
	end	
	
	def to_s()
		">#{@target.to_s}"
	end
end

class InputPhysical
	def initialize
		@target = nil
	end
	
	def set_source(output)
		@target = output
	end
	
	def get_value()
		@target.get_value() # from output
	end
	
	def to_s()
		"(#{@target.to_s})"
	end
end

class OutputAbstract
	def initialize
		@target = nil		
	end
	
	def alias(out)
		@target = out # get physical
	end
	
	def set_value(v)  # only physical components can set values...
		'not allowed'
	end
	
	def get_value
		@target.get_value
	end
	
	def to_s
		"(#{@target.to_s})"
	end
end

class OutputPhysical
	def initialize
		@value = nil
	end
	
	def set_value(v)
		@value = [0,'0','f','F',false].include?(v) ? false : true
	end
	
	def get_value
		@value
	end
	
	def to_s
		"(#{@value})"
	end
end

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


class Component

	attr_reader :inputs, :outputs

	def initialize(sim, num_inputs, num_outputs, abstract = true)	
		@sim = sim

		@inputs = Array.new(num_inputs)  do |idx|
			(abstract ? InputAbstract.new() : InputPhysical.new())		
		end
		
		@outputs = Array.new(num_outputs) do |idx|
			(abstract ? OutputAbstract.new() : OutputPhysical.new())
		end
		
		@sim.register_component(self)
	end
	
	def update
	end
		
	def pulse
	end
			
	def to_s
		self.class.to_s + ":\n\tin:" + (0...@inputs.size).collect do |i| 
			i.to_s
		end.join("\n\t") + "\nout:" + (0...@outputs.size).collect do |i|
			i.to_s
		end.join("")
	end
	
	# helper to mass assign inputs
	def set_input_values(vals)		
		raise 'bad input' unless vals.size == @inputs.size
		vals.each_with_index do |val,idx|		
			signal = [0,'0','F',false].include?(val) ? @sim.false_signal : @sim.true_signal
			@inputs[idx].set_source(signal.outputs[0])
		end
	end
	
	def get_output(n)
		@outputs[n].get_value()
	end
	
	# helper to get all outputs
	def get_outputs()		
		(0...@outputs.size).collect do |idx|
			@outputs[idx].get_value()
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

# class Component < CoreComponent
	# def initialize(sim, num_inputs, num_outputs)
		# super
	# end
	
	# def update
	# end
	
	# # non-core components have inputs that point to core inputs, which then point to core outputs
	# def connect_input_to_input(idx, input, i)
		# @inputs[idx] = [input, i]  #use this to redirect...
	# end
	
	# # deref the input, then change that input to the given output
	# def connect_input_target_to_output(idx, obj, oidx)
		# @inputs[idx].first.send(:connect_input_to_output, @inputs[idx].last, obj,oidx)
	# end
	
	# # for core components, no need to set indirection.
	# def set_input_to_output(idx, obj, oidx)
		# connect_input_target_to_output(idx,obj,oidx)
	# end
		
	# # non-core components have outputs that point to core outputs 
	# def connect_output_to_output(idx, output, i)
		# @outputs[idx] = [output, i]
	# end
	
	# def get_output(idx)
		# @outputs[idx].first.send(:get_output, @outputs[idx].last)
	# end
	
	# # core components still have to dereference inputs to grab the output
	# def get_input(idx)
		# @inputs[idx].first.send(:get_output, @inputs[idx].last)
	# end
# end

class FalseSignal < Component
	def initialize(sim)
		super(sim,0,1,false)		
		@outputs[0].set_value(false)
	end
	def update
	end
end 

class TrueSignal < Component
	def initialize(sim)
		super(sim,0,1,false)
		@outputs[0].set_value(true)
	end
	def update
	end
end 

class OrGate < Component
	def initialize(sim)
		super(sim,2,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		@outputs[0].set_value(@inputs[0].get_value() | @inputs[1].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class AndGate < Component
	def initialize(sim)
		super(sim,2,1,false)
	end 
	
	def update
		prev = @outputs[0].get_value()
		@outputs[0].set_value(@inputs[0].get_value() & @inputs[1].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
		
	label_helper([:a,:b,:x], 2)
end

class NorGate < Component
	def initialize(sim)
		super(sim,2,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		@outputs[0].set_value(!(@inputs[0].get_value() | @inputs[1].get_value()))
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class XorGate < Component
	def initialize(sim)
		super(sim,2,1,false)
	end 
	
	def update		
		prev = @outputs[0].get_value()
		a = @inputs[0].get_value()
		b = @inputs[1].get_value()		
		@outputs[0].set_value((a | b) & (!(a & b)))
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class NandGate < Component
	def initialize(sim)
		super(sim,2,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		a = @inputs[0].get_value()
		b = @inputs[1].get_value()		
		@outputs[0].set_value(!(a & b))
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
	
	label_helper([:a,:b,:x], 2)
end

class NotGate < Component
	def initialize(sim)
		super(sim,1,1,false)
	end 
	
	def update
		prev = @outputs[0].get_value()
		@outputs[0].set_value(!@inputs[0].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
	
	label_helper([:a,:x], 1)
end

## not a real component
class And4Gate < Component
	 def initialize(sim)		
		super(sim,4,1,true)		
		
		a1 = AndGate.new(sim)		
		a2 = AndGate.new(sim)
		ac = AndGate.new(sim)
		
		ac.inputs[0].set_source(a1.outputs[0])
		ac.inputs[1].set_source(a2.outputs[0])
		
		@inputs[0].alias(a1.inputs[0])
		@inputs[1].alias(a1.inputs[1])
		@inputs[2].alias(a2.inputs[0])
		@inputs[3].alias(a2.inputs[1])
		@outputs[0].alias(ac.outputs[0])
				
	end
	
	# def to_s
		# ['debug:',super,@comps[:a1].to_s,@comps[:a2].to_s,@comps[:ac].to_s].join("\n")
	# end
	
	label_helper([:a,:b,:c,:d,:x], 4)
end

class BufferGate < Component
	def initialize(sim)
		super(sim,1,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		@outputs[0].set_value(@inputs[0].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
		
	label_helper([:a,:x], 1)
end
		

 class DataLatch < Component
	def initialize(sim)
		super(sim,1,1,false)
		sim.clock.register(self)
	end 
	
	label_helper([:set,:value], 1)
	
	def pulse		
		@outputs[0].set_value(@inputs[0].get_value())	
	end
	
	def update		
	end	
end

class Register < Component
	def initialize(sim)
		super(sim,2,1,true)  # load, enable (removed for now
				
		b = BufferGate.new(sim) # load
		n = NotGate.new(sim)
		a1 = AndGate.new(sim)
		a2 = AndGate.new(sim)
		o = OrGate.new(sim)
		dl = DataLatch.new(sim)
		
		n.inputs[0].set_source(b.outputs[0])
		
		a1.inputs[0].set_source(dl.outputs[0])
		a1.inputs[1].set_source(n.outputs[0])
		a2.inputs[0].set_source(b.outputs[0])	
		o.inputs[0].set_source(a1.outputs[0])
		o.inputs[1].set_source(a2.outputs[0])
		dl.inputs[0].set_source(o.outputs[0])
		
		@inputs[0].alias(a2.inputs[1])
		@inputs[1].alias(b.inputs[0])
		@outputs[0].alias(dl.outputs[0])
		
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
		

class Register8 < Component
	def initialize(sim)
		super(sim,9,8)  # 8 bit, load.  deal with enabled downstream on input to bus?
		
		b = BufferGate.new(sim)
		@inputs[8].alias(b.inputs[0])		
		
		r = Array.new(8) do Register.new(sim) end
		(0...8).each do |idx|
			@inputs[idx].alias(r[idx].inputs[0])
			@outputs[idx].alias(r[idx].outputs[0])
			r[idx].inputs[1].set_source(b.outputs[0])			
		end		
		
		# @b = b
		# @r = r
	end
	
	# def to_s
		# ([super,@b.to_s] + @r.collect do |x| x.to_s end).join("\n\t")
	# end
		
end

class FullAdderSub8 < Component
	 def initialize(sim)		
		super(sim,17,9,0)	# input: a + b, 17th = sub  output: 8 digits plus carry
		
		fa1 = FullAdder.new(sim)		
		fa2 = FullAdder.new(sim)
		fa3 = FullAdder.new(sim)
		fa4 = FullAdder.new(sim)
		fa5 = FullAdder.new(sim)
		fa6 = FullAdder.new(sim)
		fa7 = FullAdder.new(sim)
		fa8 = FullAdder.new(sim)
		
		x1 = XorGate.new(sim)
		x2 = XorGate.new(sim)
		x3 = XorGate.new(sim)
		x4 = XorGate.new(sim)
		x5 = XorGate.new(sim)
		x6 = XorGate.new(sim)
		x7 = XorGate.new(sim)
		x8 = XorGate.new(sim)

		fa1.inputs[1].set_source(x1.outputs[0])
		fa2.inputs[1].set_source(x2.outputs[0])
		fa3.inputs[1].set_source(x3.outputs[0])
		fa4.inputs[1].set_source(x4.outputs[0])
		fa5.inputs[1].set_source(x5.outputs[0])
		fa6.inputs[1].set_source(x6.outputs[0])
		fa7.inputs[1].set_source(x7.outputs[0])
		fa8.inputs[1].set_source(x8.outputs[0])
		
		b = BufferGate.new(sim) # subtraction
		
		# carry in?
		fa2.inputs[2].set_source(fa1.outputs[1])
		fa3.inputs[2].set_source(fa2.outputs[1])
		fa4.inputs[2].set_source(fa3.outputs[1])
		fa5.inputs[2].set_source(fa4.outputs[1])
		fa6.inputs[2].set_source(fa5.outputs[1])
		fa7.inputs[2].set_source(fa6.outputs[1])
		fa8.inputs[2].set_source(fa7.outputs[1])	

		@inputs[0].alias(fa1.inputs[0])
		@inputs[1].alias(fa2.inputs[0])
		@inputs[2].alias(fa3.inputs[0])
		@inputs[3].alias(fa4.inputs[0])
		@inputs[4].alias(fa5.inputs[0])
		@inputs[5].alias(fa6.inputs[0])
		@inputs[6].alias(fa7.inputs[0])
		@inputs[7].alias(fa8.inputs[0])
		
		@inputs[8].alias(x1.inputs[0])
		@inputs[9].alias(x2.inputs[0])
		@inputs[10].alias(x3.inputs[0])
		@inputs[11].alias(x4.inputs[0])
		@inputs[12].alias(x5.inputs[0])
		@inputs[13].alias(x6.inputs[0])
		@inputs[14].alias(x7.inputs[0])
		@inputs[15].alias(x8.inputs[0])
		
		
		@inputs[16].alias(b.inputs[0])
		
		fa1.inputs[2].set_source(b.outputs[0])
		x1.inputs[1].set_source(b.outputs[0])
		x2.inputs[1].set_source(b.outputs[0])
		x3.inputs[1].set_source(b.outputs[0])
		x4.inputs[1].set_source(b.outputs[0])
		x5.inputs[1].set_source(b.outputs[0])
		x6.inputs[1].set_source(b.outputs[0])
		x7.inputs[1].set_source(b.outputs[0])
		x8.inputs[1].set_source(b.outputs[0])

		@outputs[0].alias(fa1.outputs[0])
		@outputs[1].alias(fa2.outputs[0])
		@outputs[2].alias(fa3.outputs[0])
		@outputs[3].alias(fa4.outputs[0])
		@outputs[4].alias(fa5.outputs[0])
		@outputs[5].alias(fa6.outputs[0])
		@outputs[6].alias(fa7.outputs[0])
		@outputs[7].alias(fa8.outputs[0])
		@outputs[8].alias(fa8.outputs[1])
		
	end
end

class HalfAdder < Component
	 def initialize(sim)		
		super(sim,2,2)
		
		x = XorGate.new(sim)		
		a = AndGate.new(sim)

		b1 = BufferGate.new(sim)
		b2 = BufferGate.new(sim)
		
		x.inputs[0].set_source(b1.outputs[0])
		x.inputs[1].set_source(b2.outputs[0])		
		a.inputs[0].set_source(b1.outputs[0])
		a.inputs[1].set_source(b2.outputs[0])
		
		@inputs[0].alias(b1.inputs[0])
		@inputs[1].alias(b2.inputs[0])
		@outputs[0].alias(x.outputs[0])
		@outputs[1].alias(a.outputs[0])
				
		# @a = a
		# @x = x
		# @b1 = b1
		# @b2 = b2
	end
	
	# def to_s
		# ['debug:',super,@x.to_s,@a.to_s,@b1.to_s,@b2.to_s].join("\n")
	# end
	
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
		
		x2.inputs[0].set_source(x1.outputs[0])
			
		o1.inputs[0].set_source(a1.outputs[0])
		o1.inputs[1].set_source(a2.outputs[0])		
		o2.inputs[0].set_source(o1.outputs[0])
		o2.inputs[1].set_source(a3.outputs[0])
				
		b1 = BufferGate.new(sim)
		b2 = BufferGate.new(sim)
		b3 = BufferGate.new(sim)
		
		@inputs[0].alias(b1.inputs[0])
		@inputs[1].alias(b2.inputs[0])
		@inputs[2].alias(b3.inputs[0])
		
		a1.inputs[0].set_source(b1.inputs[0])
		a2.inputs[0].set_source(b1.inputs[0])
		x1.inputs[0].set_source(b1.inputs[0])
		
		a1.inputs[1].set_source(b2.inputs[0])
		a3.inputs[0].set_source(b2.inputs[0])
		x1.inputs[1].set_source(b2.inputs[0])
		
		a2.inputs[1].set_source(b3.inputs[0])
		a3.inputs[1].set_source(b3.inputs[0])
		x2.inputs[1].set_source(b3.inputs[0])
		
		@outputs[0].alias(x2.outputs[0])
		@outputs[1].alias(o2.outputs[0])
		
	end
	
	label_helper([:a,:b,:c,:sum,:carry],3)
end

class Multiplexer2 < Component
	def initialize(sim)
		super(sim,3,1)
		
		b1 = BufferGate.new(sim) #d0
		b2 = BufferGate.new(sim) #d1
		b3 = BufferGate.new(sim) #sel
		
		@inputs[0].alias(b1.inputs[0])
		@inputs[1].alias(b2.inputs[0])
		@inputs[2].alias(b3.inputs[0])
		
		n1 = NotGate.new(sim)
		n1.inputs[0].set_source(b3.outputs[0])
		
		a1 = AndGate.new(sim)
		a2 = AndGate.new(sim)
		
		a1.inputs[0].set_source(b1.outputs[0])
		a1.inputs[1].set_source(n1.outputs[0]) # first data line and sel = 0
		a2.inputs[0].set_source(b2.outputs[0])
		a2.inputs[1].set_source(b3.outputs[0]) # second line line and sel = 1
		
		o = OrGate.new(sim)
		o.inputs[0].set_source(a1.outputs[0])
		o.inputs[1].set_source(a2.outputs[0])
		
		@outputs[0].alias(o.outputs[0])
	end
end

class Multiplexer4 < Component
	def initialize(sim)
		super(sim,6,1)
		m1 = Multiplexer2.new(sim)
		m2 = Multiplexer2.new(sim)
		b = BufferGate.new(sim)
		@inputs[5].alias(b.inputs[0])
		@inputs[0].alias(m1.inputs[0])
		@inputs[1].alias(m1.inputs[1])
		@inputs[2].alias(m2.inputs[0])
		@inputs[3].alias(m2.inputs[1])
		mo = Multiplexer2.new(sim)
		mo.inputs[0].set_source(m1.outputs[0])
		mo.inputs[1].set_source(m2.outputs[0])
		m1.inputs[2].set_source(b.outputs[0])
		m2.inputs[2].set_source(b.outputs[0])
		@inputs[4].alias(mo.inputs[2])
		@outputs[0].alias(mo.outputs[0])	
	end
end

class Multiplexer8 < Component
	def initialize(sim)
		super(sim,11,1)
		m1 = Multiplexer4.new(sim)
		m2 = Multiplexer4.new(sim)
		b1 = BufferGate.new(sim)
		b2 = BufferGate.new(sim)
		
		@inputs[0].alias(m1.inputs[0])
		@inputs[1].alias(m1.inputs[1])
		@inputs[2].alias(m1.inputs[2])
		@inputs[3].alias(m1.inputs[3])
		@inputs[4].alias(m2.inputs[0])
		@inputs[5].alias(m2.inputs[1])
		@inputs[6].alias(m2.inputs[2])
		@inputs[7].alias(m2.inputs[3])

	
		@inputs[9].alias(b1.inputs[0])
		@inputs[10].alias(b2.inputs[0])
		
		mo = Multiplexer2.new(sim)
		mo.inputs[0].set_source(m1.outputs[0])
		mo.inputs[1].set_source(m2.outputs[0])
		
		m1.inputs[4].set_source(b1.outputs[0])		
		m1.inputs[5].set_source(b2.outputs[0])
		m2.inputs[4].set_source(b1.outputs[0])
		m2.inputs[5].set_source(b2.outputs[0])
		
		@inputs[8].alias(mo.inputs[2])  # high bit selects between the two mux4s.
		@outputs[0].alias(mo.outputs[0])	
	end
end

	

# ai in load signl
# a out signal
# b in
# b out

# 2x 8 inputs
# eo out?
# substract?
#
class ALU8 < Component
	def initialize(sim)
		super(sim,8,8)  # from bus, output
	end
end
