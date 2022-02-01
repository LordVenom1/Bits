# 555 timer

# on clock pulse, all latches record their values.
# only then, start updating
require 'set'

class Binary
  def self.to_decimal(binary)
    raise ArgumentError if binary.match?(/[^01]/)

    binary.reverse.chars.map.with_index do |digit, index|
      digit.to_i * 2**index
    end.sum
  end
end

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
	
	# def override(out)  # only physical components can set values...
		# # raise 'not allowed'
		# if @target.class == OutputPhysical
			# @target = out
		# else
			# @target.override(v) # allow it to go down...
		# end
	# end
	
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
		puts v.to_s
		if [0,'0','f','F',false].include?(v)
			@value = false
		elsif [1,'1','t','T',true].include?(v)
			@value = true
		else
			raise 'invalid output value ' + v.class.to_s
		end
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
			#puts "UPDATING"
			n = n - 1
			raise 'failure to converge' if n == 0
			@dirty = false
			@components.each do |c|
				c.update
			end
		end		

		@clock.pulse
		
		@dirty = true
		while @dirty
			#puts "UPDATING"
			n = n - 1
			raise 'failure to converge' if n == 0
			@dirty = false
			@components.each do |c|
				c.update
			end
		end	
		
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
			@inputs[i].get_value() ? '1' : '0'
		end.join("") + " out:" + (0...@outputs.size).collect do |i|
			@outputs[i].get_value() ? '1' : '0'
		end.join("") + "\n"
	end
	
	# helper to mass assign inputs
	def set_input_values(vals)		
		raise 'bad input' unless vals.size == @inputs.size
		vals.each_with_index do |val,idx|
			signal = nil
			if [0,'0','F',false].include?(val)
				signal = @sim.false_signal
			elsif [1,'1','T',true].include?(val)				
				signal = @sim.true_signal
			else
				raise 'invalid value: ' + val.to_s
			end

			# rescue 
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
	
	def override(v)		
		if [0,'0','f','F',false].include?(v)
			@outputs[0] = @sim.false_signal #.set_value(@sim.false_signal)
		elsif [1,'1','t','T',true].include?(v)
			@outputs[0] = @sim.true_signal #.set_value(@sim.true_signal)
		else
			raise 'invalid output value ' + v
		end	
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
		@dl = DataLatch.new(sim)
		
		n.inputs[0].set_source(b.outputs[0])
		
		a1.inputs[0].set_source(@dl.outputs[0])
		a1.inputs[1].set_source(n.outputs[0])
		a2.inputs[0].set_source(b.outputs[0])	
		o.inputs[0].set_source(a1.outputs[0])
		o.inputs[1].set_source(a2.outputs[0])
		@dl.inputs[0].set_source(o.outputs[0])
		
		@inputs[0].alias(a2.inputs[1])
		@inputs[1].alias(b.inputs[0])
		@outputs[0].alias(@dl.outputs[0])
		
		#@b,@n,@a1,@a2,@o,@dl = b,n,a1,a2,o,dl
		# enable 0 means don't send any inputs to bus???
		# tri-state-buffer?
		# multiplexor instead?
	end
	
	def override(v)
		@dl.override(v)
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
		
		@r = Array.new(8) do Register.new(sim) end
		(0...8).each do |idx|
			@inputs[idx].alias(@r[idx].inputs[0])
			@outputs[idx].alias(@r[idx].outputs[0])
			@r[idx].inputs[1].set_source(b.outputs[0])			
		end		
		
		# @b = b
		# @r = r
	end
	
	def load(values)
		raise 'bad data: ' + values unless values.class == String and values.size == 8
		(0...8).each do |idx|
			@r[idx].override(values[idx])
		end
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
		
		@b1 = BufferGate.new(sim) #d0
		@b2 = BufferGate.new(sim) #d1
		@b3 = BufferGate.new(sim) #sel
		
		@inputs[0].alias(@b1.inputs[0])
		@inputs[1].alias(@b2.inputs[0])
		@inputs[2].alias(@b3.inputs[0])
		
		@n1 = NotGate.new(sim)
		@n1.inputs[0].set_source(@b3.outputs[0])
		
		@a1 = AndGate.new(sim)
		@a2 = AndGate.new(sim)
		
		@a1.inputs[0].set_source(@b1.outputs[0])
		@a1.inputs[1].set_source(@b3.outputs[0]) # first data line and sel = 0
		@a2.inputs[0].set_source(@b2.outputs[0])
		@a2.inputs[1].set_source(@n1.outputs[0]) # second line line and sel = 1
		
		@o = OrGate.new(sim)
		@o.inputs[0].set_source(@a1.outputs[0])  
		@o.inputs[1].set_source(@a2.outputs[0])
		
		@outputs[0].alias(@o.outputs[0])
	end
	
	# def to_s
		# ["mux2",super, @b1, @b2, @b3, @n1, @a1, @a2, @o,"mux2end"].join(",")
	# end
end

class Multiplexer4 < Component
	def initialize(sim)
		super(sim,6,1)
		@m1 = Multiplexer2.new(sim)
		@m2 = Multiplexer2.new(sim)
		@b = BufferGate.new(sim)
		@inputs[5].alias(@b.inputs[0])
		@inputs[0].alias(@m1.inputs[0])
		@inputs[1].alias(@m1.inputs[1])
		@inputs[2].alias(@m2.inputs[0])
		@inputs[3].alias(@m2.inputs[1])
		@mo = Multiplexer2.new(sim)
		@mo.inputs[0].set_source(@m1.outputs[0])
		@mo.inputs[1].set_source(@m2.outputs[0])
		@m1.inputs[2].set_source(@b.outputs[0])
		@m2.inputs[2].set_source(@b.outputs[0])
		@inputs[4].alias(@mo.inputs[2])
		@outputs[0].alias(@mo.outputs[0])	
	end
	
	# def to_s
		# [super, @m1.to_s, @m2.to_s, @mo.to_s, @b].join(":")
	# end
end

class Multiplexer8 < Component
	def initialize(sim)
		super(sim,11,1)
		@m1 = Multiplexer4.new(sim)
		@m2 = Multiplexer4.new(sim)
		@b1 = BufferGate.new(sim)
		@b2 = BufferGate.new(sim)
		
		@inputs[0].alias(@m1.inputs[0])
		@inputs[1].alias(@m1.inputs[1])
		@inputs[2].alias(@m1.inputs[2])
		@inputs[3].alias(@m1.inputs[3])
		@inputs[4].alias(@m2.inputs[0])
		@inputs[5].alias(@m2.inputs[1])
		@inputs[6].alias(@m2.inputs[2])
		@inputs[7].alias(@m2.inputs[3])

	
		@inputs[9].alias(@b1.inputs[0])
		@inputs[10].alias(@b2.inputs[0])
		
		@mo = Multiplexer2.new(sim)
		@mo.inputs[0].set_source(@m1.outputs[0])
		@mo.inputs[1].set_source(@m2.outputs[0])
		
		@m1.inputs[4].set_source(@b1.outputs[0])		
		@m1.inputs[5].set_source(@b2.outputs[0])
		@m2.inputs[4].set_source(@b1.outputs[0])
		@m2.inputs[5].set_source(@b2.outputs[0])
		
		@inputs[8].alias(@mo.inputs[2])  # high bit selects between the two mux4s.
		@outputs[0].alias(@mo.outputs[0])	
	end
	
	# def to_s
		# [super, @m1.to_s, @m2.to_s, @mo.to_s, @b1, @b2].join(",")
	# end
end

class Demux2 < Component
	def initialize(sim)
		super(sim,2,2) # data, sel		
		sel = BufferGate.new(sim)
		not_sel = NotGate.new(sim)
		@inputs[1].alias(sel.inputs[0])
		not_sel.inputs[0].set_source(sel.outputs[0])
						
		data = BufferGate.new(sim)
		a1 = AndGate.new(sim)
		@inputs[0].alias(data.inputs[0])
		a1.inputs[0].set_source(data.outputs[0])
		a1.inputs[1].set_source(not_sel.outputs[0])		
		a2 = AndGate.new(sim)
		a2.inputs[0].set_source(data.outputs[0])
		a2.inputs[1].set_source(sel.outputs[0])
		
		@outputs[1].alias(a1.outputs[0])
		@outputs[0].alias(a2.outputs[0])
		
	end
end 

class Demux4 < Component
	def initialize(sim)
		super(sim,3,4) # data, sel0, sel1 => out0, out1, out2, out3
		
		din = Demux2.new(sim)
		d1 = Demux2.new(sim)
		d2 = Demux2.new(sim)		
		@inputs[0].alias(din.inputs[0])
		@inputs[1].alias(din.inputs[1])
		sel1 = BufferGate.new(sim)
		@inputs[2].alias(sel1.inputs[0])
		
		d1.inputs[0].set_source(din.outputs[0])
		d1.inputs[1].set_source(sel1.outputs[0])
		d2.inputs[0].set_source(din.outputs[1])
		d2.inputs[1].set_source(sel1.outputs[0])
		
		@outputs[0].alias(d1.outputs[0])
		@outputs[1].alias(d1.outputs[1])
		@outputs[2].alias(d2.outputs[0])
		@outputs[3].alias(d2.outputs[1])
		
	end
end

class Demux8 < Component
	def initialize(sim)
		super(sim,4,8) # data, sel0, sel1 => out0, out1, out2, out3
		
		din = Demux2.new(sim)
		d1 = Demux4.new(sim)
		d2 = Demux4.new(sim)		
		@inputs[0].alias(din.inputs[0])		
		@inputs[1].alias(din.inputs[1])
		
		sel1 = BufferGate.new(sim)
		sel2 = BufferGate.new(sim)
		@inputs[2].alias(sel1.inputs[0])
		@inputs[3].alias(sel2.inputs[0])
		
		d1.inputs[0].set_source(din.outputs[0])
		d1.inputs[1].set_source(sel1.outputs[0])
		d1.inputs[2].set_source(sel2.outputs[0])
		d2.inputs[0].set_source(din.outputs[1])
		d2.inputs[1].set_source(sel1.outputs[0])
		d2.inputs[2].set_source(sel2.outputs[0])
		
		@outputs[0].alias(d1.outputs[0]) # MSB output
		@outputs[1].alias(d1.outputs[1])
		@outputs[2].alias(d1.outputs[2])
		@outputs[3].alias(d1.outputs[3])
		@outputs[4].alias(d2.outputs[0])
		@outputs[5].alias(d2.outputs[1])
		@outputs[6].alias(d2.outputs[2])
		@outputs[7].alias(d2.outputs[3])
		
	end
end	

class RAM8x8 < Component
	def initialize(sim)
		super(sim,12,8) # 8 data bits, 3 select bits, load bit		
		
		@addr0 = BufferGate.new(sim)
		@addr1 = BufferGate.new(sim)
		@addr2 = BufferGate.new(sim)
		@inputs[8].alias(@addr0.inputs[0])
		@inputs[9].alias(@addr1.inputs[0])
		@inputs[10].alias(@addr2.inputs[0])
		
		@load = Demux8.new(sim)
		@inputs[11].alias(@load.inputs[0])
		@load.inputs[1].set_source(@addr0.outputs[0])
		@load.inputs[2].set_source(@addr1.outputs[0])
		@load.inputs[3].set_source(@addr2.outputs[0])
		
		@data = Array.new(8) do BufferGate.new(sim) end
		
		# 8 bits
		@m = Array.new(8) do Multiplexer8.new(sim) end  # 11/1
		@r = Array.new(8) do Register8.new(sim) end  # 11/1
		
		(0...8).each do |idx|		
			@inputs[idx].alias(@data[idx].inputs[0])
		
			(0...8).each do |j|
				@m[j].inputs[7 - idx].set_source(@r[idx].outputs[j])
			end		
			@m[idx].inputs[8].set_source(@addr0.outputs[0])
			@m[idx].inputs[9].set_source(@addr1.outputs[0])
			@m[idx].inputs[10].set_source(@addr2.outputs[0])
			
			(0...8).each do |j|
				@r[idx].inputs[j].set_source(@data[j].outputs[0])
			end
			@r[idx].inputs[8].set_source(@load.outputs[7-idx]) # output 0 is lsb for a demux
			
			@outputs[idx].alias(@m[idx].outputs[0])
		end		
	end
	
	def dump(off = 0)
		# [@addr0.outputs[0],@addr1.outputs[0],@addr2.outputs[0]].collect do |o| o.get_value() ? '1' : '0' end.join("") + "\n" +
		(0...@r.size).collect do |idx|		
			"#{(idx + off).to_s(2).rjust(8,'0')}(#{(idx + off).to_s.rjust(2)}):" + @r[idx].outputs.collect do |o| o.get_value() ? '1' : '0' end.join("")
		end.join("\n")
	end
	
	def load(values)	
		chunks = values.split("\n")
		raise 'bad values' unless chunks.size == 8
		(0...8).each do |idx|		
			@r[idx].load(chunks[idx])			
		end
	end	
	
	def update 
		# puts @m[0].to_s
	end
	
	def to_s
		[super, @addr0, @addr1, @addr2, @m.collect do |m| m.to_s end.join(","), @r.collect do |r| r.to_s end.join(',')].join("\n")
	end
end

class RAM8x64 < Component
	def initialize(sim)
		super(sim, 15, 8)
		
		@data = Array.new(8) do BufferGate.new(sim) end
		@addr = Array.new(6) do BufferGate.new(sim) end
		
		(0...8).each do |idx|
			@inputs[idx].alias(@data[idx].inputs[0])
		end
		
		(0...6).each do |idx|
			@inputs[8 + idx].alias(@addr[idx].inputs[0])
		end
		
		@load = Demux8.new(sim)
		@inputs[14].alias(@load.inputs[0])
		@load.inputs[1].set_source(@addr[0].outputs[0])
		@load.inputs[2].set_source(@addr[1].outputs[0])
		@load.inputs[3].set_source(@addr[2].outputs[0])
		
		@r = Array.new(8) do RAM8x8.new(sim) end
		(0...8).each do |idx|
			@r[idx].inputs[11].set_source(@load.outputs[7 - idx])  # output 0 is lsb for a demux
			(0...8).each do |j|
				@r[idx].inputs[j].set_source(@data[j].outputs[0])
			end
			@r[idx].inputs[8].set_source(@addr[3].outputs[0]) # low bits to each sub ram module
			@r[idx].inputs[9].set_source(@addr[4].outputs[0])
			@r[idx].inputs[10].set_source(@addr[5].outputs[0])
		end
		
		@m = Array.new(8) do Multiplexer8.new(sim) end  # 11/1
		(0...8).each do |idx|	
			@m[idx].inputs[8].set_source(@addr[3].outputs[0])
			@m[idx].inputs[9].set_source(@addr[4].outputs[0])
			@m[idx].inputs[10].set_source(@addr[5].outputs[0])		
			(0...8).each do |j|
				@m[j].inputs[idx].set_source(@r[idx].outputs[j])
			end	
			@outputs[idx].alias(@m[idx].outputs[0])
		end		
	end
	
	def dump(off = 0)
		# [@addr0.outputs[0],@addr1.outputs[0],@addr2.outputs[0]].collect do |o| o.get_value() ? '1' : '0' end.join("") + "\n" +
		(0...@r.size).collect do |idx|		
			@r[idx].dump(idx * 8)
		end.join("\n")
	end

	def load(values)
		values.each_slice(8) do |chunk|
			@r.load(chunk)
		end
	end
	
	
	def load_file(filename)
		load(File.readlines(filename))
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
		super(sim,17,8)  # from bus, output
		
		add = FullAdderSub8.new(sim)
		
		(0...16).each do |idx|
			@inputs[idx].alias(add.inputs[idx])
			@outputs[idx].alias(add.outputs[idx])
		end
		
		
	end
end
