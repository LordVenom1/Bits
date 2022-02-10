# 555 timer

# on clock pulse, all latches record their values.
# only then, start updating
# require 'set'

class InputAbstract
	def initialize(owner)
		@target = nil
		@owner = owner
	end
	
	def alias(input)
		@target = input # recurse
	end
	
	def check
		return @target != nil & @target.check
	end
	
	def set_source(output)
		raise 'bad output type' unless [OutputAbstract,OutputPhysical].include? output.class
		@target.set_source(output)
	end	
	
	def get_value()
		@target.get_value() # from output
	end	
	
	def to_s()
		"#{owner.path}>#{@target.to_s}"
	end
end

class InputPhysical
	def initialize(owner)
		@target = nil
		@owner = owner
	end
	
	def check
		return (@target != nil) & @target.check
	end
	
	def set_source(output)
		raise 'bad output type' unless [OutputAbstract,OutputPhysical].include? output.class
		@target = output
	end
	
	def get_value()
		begin
			@target.get_value() # from output
		rescue StandardError => ex
			raise @owner.path + " - " + ex.to_s
		end
	end
	
	def to_s()
		"(#{@target.to_s})"
	end
end

class OutputAbstract	
	def initialize(owner)
		@target = nil
		@owner = owner		
	end
	
	def alias(out)
		@target = out # get physical
	end
	
	def check
		return (@target != nil) & @target.check
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
	def initialize(owner)
		# nil is a problem due to initial update trying to pull in nil values and replicate them forward
		@value = false 
		@owner = owner
	end
	
	def set_value(v)
		if [0,'0','f','F',false].include?(v)
			@value = false
		elsif [1,'1','t','T',true].include?(v)  # nil no longer defaults to true, wtf
			@value = true
		else
			raise 'invalid output value ' + v.class.to_s
		end
	end
	
	def check
		return [true, false].include? @value
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
		# @root = TreeNode.new()
		@components = []
		@clock = Clock.new
		
		@false_signal = FalseSignal.new(self,"sim_false","sim")
		@true_signal = TrueSignal.new(self,"sim_true","sim")
	end			
	
	def to_s
		components.collect do |c|
			c.to_s
		end.join("\n")
	end
	
	def mark_dirty
		@dirty = true
	end
	
	def check()
		@components.each do |c|
			c.inputs.each do |i|
				raise 'bad input on ' + c.to_s unless i != nil and i.check
			end
			c.outputs.each do |i|
				raise 'bad output on ' + c.to_s unless i != nil and i.check
			end
		end
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
				begin
					c.update
				rescue StandardError => ex
					raise c.class.to_s + " - " + ex.to_s
				end
			end
		end		

		@clock.pulse
		
		n = MAX_ITERATIONS
		@dirty = true
		while @dirty
			#puts "UPDATING"
			n = n - 1
			raise 'failure to converge' if n == 0
			@dirty = false
			@components.each do |c|
			
				begin
					c.update
				rescue StandardError => ex
					raise c.class.to_s + " - " + ex.to_s
				end
				
				
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
	attr_reader :label
	
	def path
		(@parent ? @parent.path : "root") + "\\" + @label
	end

	def initialize(sim, label, parent, num_inputs, num_outputs, abstract = true)
		@sim = sim
		
		@label = label
		@parent = parent			

		@inputs = Array.new(num_inputs)  do |idx|
			(abstract ? InputAbstract.new(self) : InputPhysical.new(self))		
		end
		
		@outputs = Array.new(num_outputs) do |idx|
			(abstract ? OutputAbstract.new(self) : OutputPhysical.new(self))
		end
		
		@sim.register_component(self)
	end
	
	def update
	end
		
	def pulse
	end
			
	def to_s
		# print "displaying #{self.class.to_s}"
		@label + "(" + self.class.to_s + "):\n\tin:" + (0...@inputs.size).collect do |i|
			
			# puts "in: #{i}"
			v = @inputs[i].get_value()
			
			if [true,false].include? v
				v ? '1' : '0'
			else
				"<<#{v}>>"
			end
			#raise 'bad value' unless [true,false].include? v
			
		end.join("") + " out:" + (0...@outputs.size).collect do |i|
			# puts "out: #{i}"
			v = @outputs[i].get_value()
			if [true,false].include? v
				v ? '1' : '0'
			else
				"<<#{v}>>"
			end
		end.join("") + "\n"
	end
	
	
	def set_input_value(idx, val)
		signal = nil
			
		if [0,'0','F',false].include?(val)
			signal = @sim.false_signal
		elsif [1,'1','T',true].include?(val)				
			signal = @sim.true_signal
		else
			raise 'invalid value #{idx}: ' + val.to_s
		end
		
		begin			
			@inputs[idx].set_source(signal.outputs[0])
		rescue StandardError => ex
			raise "unable to set input value: #{path} #{self.class.to_s} #{idx} #{val} - " + ex.to_s
		end
		
	end
	# helper to mass assign inputs
	# only works on top-most component, otherwise aliases will break
	def set_input_values(vals)		
		raise 'bad input' unless vals.size == @inputs.size
		vals.each_with_index do |val,idx|
			set_input_value(idx,val)
	
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
	
end

class FalseSignal < Component
	def initialize(sim, label, parent)
		super(sim, label, parent,0,1,false)		
		@outputs[0].set_value(false)
	end
	def update
	end
end 

class TrueSignal < Component
	def initialize(sim, label, parent)
		super(sim, label, parent, 0, 1,false)
		@outputs[0].set_value(true)
	end
	def update
	end
end 

class OrGate < Component
	def initialize(sim, label, parent)
		super(sim, label, parent, 2,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		@outputs[0].set_value(@inputs[0].get_value() | @inputs[1].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
end

class OrGate4 < Component
	def initialize(sim, label, parent)
		super(sim,label,parent,4,1)
		@o1 = OrGate.new(sim, "or1", self)
		@o2 = OrGate.new(sim, "or2", self)
		@inputs[0].alias(@o1.inputs[0])
		@inputs[1].alias(@o1.inputs[1])
		@inputs[2].alias(@o2.inputs[0])
		@inputs[3].alias(@o2.inputs[1])
		@oc = OrGate.new(sim, "oc", self)
		@oc.inputs[0].set_source(@o1.outputs[0])
		@oc.inputs[1].set_source(@o2.outputs[0])
		@outputs[0].alias(@oc.outputs[0])
	end
end

class AndGate < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,2,1,false)
	end 
	
	def update
		prev = @outputs[0].get_value()
		@outputs[0].set_value(@inputs[0].get_value() & @inputs[1].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
end

class NorGate < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,2,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		@outputs[0].set_value(!(@inputs[0].get_value() | @inputs[1].get_value()))
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
end

class XorGate < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,2,1,false)
	end 
	
	def update		
		prev = @outputs[0].get_value()
		a = @inputs[0].get_value()
		b = @inputs[1].get_value()		
		@outputs[0].set_value((a | b) & (!(a & b)))
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
end

class NandGate < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,2,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		a = @inputs[0].get_value()
		b = @inputs[1].get_value()		
		@outputs[0].set_value(!(a & b))
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
end

class NotGate < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,1,1,false)
	end 
	
	def update
		prev = @outputs[0].get_value()
		@outputs[0].set_value(!@inputs[0].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
end

## not a real component
class And4Gate < Component
	 def initialize(sim,label,parent)		
		super(sim,label,parent,4,1,true)		
		
		a1 = AndGate.new(sim,"a1",self)		
		a2 = AndGate.new(sim,"a2",self)
		ac = AndGate.new(sim,"ac",self)
		
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
end

class BufferGate < Component
	def initialize(sim, label, parent)
		super(sim,label,parent,1,1,false)
	end 
	
	def update	
		prev = @outputs[0].get_value()
		@outputs[0].set_value(@inputs[0].get_value())
		@sim.mark_dirty if @outputs[0].get_value() != prev
	end
end

class Bus8x8 < Component
	def initialize(sim,label,parent)
		# 8 sets of 8-bit inputs from other components' outputs
		# 8 select lines to determine which components should be output
		super(sim,label,parent,72,8)
		
		@enc = Encoder8x3.new(sim,"enc",self) # for converting the 8 select inputs to a 3-bit 
		@m = Array.new(8) do |n| Multiplexer8.new(sim, "mux8_#{n}", self) end
		(0...8).each do |idx|
			@inputs[64 + idx].alias(@enc.inputs[7 - idx])
			
			(0...8).each do |j|
				@inputs[idx + j * 8].alias(@m[idx].inputs[j])				
			end
			
			@m[idx].inputs[8].set_source(@enc.outputs[0])
			@m[idx].inputs[9].set_source(@enc.outputs[1])
			@m[idx].inputs[10].set_source(@enc.outputs[2])
			
			@outputs[idx].alias(@m[idx].outputs[0])
		end
	end
end

class BufferSet < Component
	def initialize(sim,label,parent,n)
		super(sim,label,parent,n,n)
		@b = Array.new(n) do |i| BufferGate.new(sim,"b#{i}",self) end
		(0...n).each do |idx|
			@inputs[idx].alias(@b[idx].inputs[0])
			@outputs[idx].alias(@b[idx].outputs[0])
		end
	end
end

class Encoder8x3 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,8,3)

		@b = BufferSet.new(sim,"b",self,8)
		@bit2 = OrGate4.new(sim,"bit2",self)
		@bit1 = OrGate4.new(sim,"bit1",self)
		@bit0 = OrGate4.new(sim,"bit0",self) #LSB
		
		(0...8).each do |idx|
			@inputs[idx].alias(@b.inputs[idx])
		end
		
		@bit2.inputs[0].set_source(@b.outputs[0])
		@bit2.inputs[1].set_source(@b.outputs[1])
		@bit2.inputs[2].set_source(@b.outputs[2])
		@bit2.inputs[3].set_source(@b.outputs[3])
		
		@bit1.inputs[0].set_source(@b.outputs[0])
		@bit1.inputs[1].set_source(@b.outputs[1])
		@bit1.inputs[2].set_source(@b.outputs[4])
		@bit1.inputs[3].set_source(@b.outputs[5])
		
		@bit0.inputs[0].set_source(@b.outputs[0])
		@bit0.inputs[1].set_source(@b.outputs[2])
		@bit0.inputs[2].set_source(@b.outputs[4])
		@bit0.inputs[3].set_source(@b.outputs[6])		
		
		@outputs[0].alias(@bit2.outputs[0])	
		@outputs[1].alias(@bit1.outputs[0])
		@outputs[2].alias(@bit0.outputs[0])
		
	end
end

class DataLatch < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,1,1,false)
		sim.clock.register(self)
	end 
	
	def pulse		
		@outputs[0].set_value(@inputs[0].get_value())	
	end
	
	def override(v)		
	
		raise 'oh no' if @outputs[0] === @sim.false_signal
		raise 'oh no' if @outputs[0] === @sim.true_signal
	
		if [0,'0','f','F',false].include?(v)
			
			@outputs[0].set_value(false)
		elsif [1,'1','t','T',true].include?(v)
			@outputs[0].set_value(true)
		else
			raise 'invalid output value ' + v
		end	
	end
	
	def update		
	end	
end

class Register < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,2,1,true)  # load, enable (removed for now
				
		b = BufferGate.new(sim, "load", self) # load
		n = NotGate.new(sim, "not", self)
		a1 = AndGate.new(sim, "a1", self)
		a2 = AndGate.new(sim, "a2", self)
		o = OrGate.new(sim, "or", self)
		@dl = DataLatch.new(sim, "datalatch", self)
		
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
		
class RegisterN < Component
	def initialize(sim, label,parent,bits)
		super(sim,label,parent,bits + 1,bits)  # n bit, load.  deal with enabled downstream on input to bus?
		
		@bits = bits
		b = BufferGate.new(sim, "buffers", self)
		@inputs[bits].alias(b.inputs[0])		
		
		@r = Array.new(bits) do Register.new(sim, "buffers", self) end
		(0...bits).each do |idx|
			@inputs[idx].alias(@r[idx].inputs[0])
			@outputs[idx].alias(@r[idx].outputs[0])
			@r[idx].inputs[1].set_source(b.outputs[0])			
		end				
	end
	
	def override(values)
		raise 'bad data: ' + values unless values.class == String and values.size == @bits
		(0...@bits).each do |idx|
			@r[idx].override(values[idx])
		end
	end
	
	def to_s
		([super,@b.to_s] + @r.collect do |x| x.to_s end).join("\n\t")
	end
		
end

class Register8 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,9,8)  # 8 bit, load.  deal with enabled downstream on input to bus?
		
		b = BufferGate.new(sim, "b", self)
		@inputs[8].alias(b.inputs[0])		
		
		@r = Array.new(8) do |i| Register.new(sim, "reg#{i}", self) end
		(0...8).each do |idx|
			@inputs[idx].alias(@r[idx].inputs[0])
			@outputs[idx].alias(@r[idx].outputs[0])
			@r[idx].inputs[1].set_source(b.outputs[0])			
		end
	end
	
	def override(values)
		raise 'bad data: ' + values unless values.class == String and values.size == 8
		(0...8).each do |idx|
			@r[idx].override(values[idx])
		end
	end
	
	def to_s
		([super,@b.to_s] + @r.collect do |x| x.to_s end).join("\n\t")
	end
		
end

class FullAdder8 < Component
	 def initialize(sim,label,parent)		
		super(sim,label,parent,17,9)	# input: a + b, 17th = carry-in  output: 8 digits plus carry
		
		@fa = Array.new(8) do |i| FullAdder.new(sim, "fa#{i}", self) end
			
		# carry in
		@inputs[16].alias(@fa[7].inputs[2])
		
		# connect carry-in to carry-out of previous adder
		(0...7).each do |idx|		
			@fa[idx].inputs[2].set_source(@fa[idx+1].outputs[1])
			@fa[idx].inputs[2].set_source(@fa[idx+1].outputs[1])
			@fa[idx].inputs[2].set_source(@fa[idx+1].outputs[1])
			@fa[idx].inputs[2].set_source(@fa[idx+1].outputs[1])
			@fa[idx].inputs[2].set_source(@fa[idx+1].outputs[1])
			@fa[idx].inputs[2].set_source(@fa[idx+1].outputs[1])
			@fa[idx].inputs[2].set_source(@fa[idx+1].outputs[1])	
		end

		# first 8 are a, 2nd 8 are b
		(0...8).each do |idx|
			@inputs[idx].alias(@fa[idx].inputs[0])
			@inputs[idx+8].alias(@fa[idx].inputs[1])
			@outputs[idx].alias(@fa[idx].outputs[0])
		end
			
		@outputs[8].alias(@fa[0].outputs[1])		
	end
	
	def to_s
		[super, @fa.join("")]
	end
end

class FullAdderSub8 < Component
	 def initialize(sim,label,parent)		
		super(sim,label,parent,17,9)	# input: a + b, 17th = sub  output: 8 digits plus carry
		
		
		@fa = FullAdder8.new(sim, "fa", self)
		
		@x = Array.new(8) do |i| XorGate.new(sim, "x#{i}", self) end
		@b = BufferGate.new(sim, "b", self) # subtraction

		# connect a and xor to full adder
		(0...8).each do |idx|
			@inputs[idx].alias(@fa.inputs[idx])
			@inputs[idx+8].alias(@x[idx].inputs[0])
			@x[idx].inputs[1].set_source(@b.outputs[0])
			@fa.inputs[8+idx].set_source(@x[idx].outputs[0])			
			
			@outputs[idx].alias(@fa.outputs[idx])
		end
		
		@inputs[16].alias(@b.inputs[0])
		@fa.inputs[16].set_source(@b.outputs[0])  # carry-in if subtracting.			
		@outputs[8].alias(@fa.outputs[8])
	end
end

class HalfAdder < Component
	 def initialize(sim,label,parent)		
		super(sim,label,parent,2,2)
		
		x = XorGate.new(sim, "x", self)		
		a = AndGate.new(sim, "a", self)

		b1 = BufferGate.new(sim, "b1", self)
		b2 = BufferGate.new(sim, "b2", self)
		
		x.inputs[0].set_source(b1.outputs[0])
		x.inputs[1].set_source(b2.outputs[0])		
		a.inputs[0].set_source(b1.outputs[0])
		a.inputs[1].set_source(b2.outputs[0])
		
		@inputs[0].alias(b1.inputs[0])
		@inputs[1].alias(b2.inputs[0])
		@outputs[0].alias(x.outputs[0])
		@outputs[1].alias(a.outputs[0])
	end
	
	# def to_s
		# ['debug:',super,@x.to_s,@a.to_s,@b1.to_s,@b2.to_s].join("\n")
	# end

end

class FullAdder < Component
	 def initialize(sim,label,parent)		
		super(sim,label,parent,3,2)		
		x1 = XorGate.new(sim, "x1", self)
		x2 = XorGate.new(sim, "x2", self)
		a1 = AndGate.new(sim, "a1", self)
		a2 = AndGate.new(sim, "a2", self)
		a3 = AndGate.new(sim, "a3", self)
		o1 = OrGate.new(sim, "o1", self)
		o2 = OrGate.new(sim, "o2", self)
		
		x2.inputs[0].set_source(x1.outputs[0])
			
		o1.inputs[0].set_source(a1.outputs[0])
		o1.inputs[1].set_source(a2.outputs[0])		
		o2.inputs[0].set_source(o1.outputs[0])
		o2.inputs[1].set_source(a3.outputs[0])
				
		b1 = BufferGate.new(sim, "b1", self)
		b2 = BufferGate.new(sim, "b2", self)
		b3 = BufferGate.new(sim, "b3", self)
		
		@inputs[0].alias(b1.inputs[0])
		@inputs[1].alias(b2.inputs[0])
		@inputs[2].alias(b3.inputs[0])
		
		a1.inputs[0].set_source(b1.outputs[0])
		a2.inputs[0].set_source(b1.outputs[0])
		x1.inputs[0].set_source(b1.outputs[0])
		
		a1.inputs[1].set_source(b2.outputs[0])
		a3.inputs[0].set_source(b2.outputs[0])
		x1.inputs[1].set_source(b2.outputs[0])
		
		a2.inputs[1].set_source(b3.outputs[0])
		a3.inputs[1].set_source(b3.outputs[0])
		x2.inputs[1].set_source(b3.outputs[0])
		
		@outputs[0].alias(x2.outputs[0])
		@outputs[1].alias(o2.outputs[0])
		
	end
	

end

class Multiplexer2 < Component
	def initialize(sim, label, parent)
		super(sim,label,parent,3,1)
		
		@b1 = BufferGate.new(sim, "b1", self) #d0
		@b2 = BufferGate.new(sim, "b2", self) #d1
		@b3 = BufferGate.new(sim, "b3", self) #sel
		
		@inputs[0].alias(@b1.inputs[0])
		@inputs[1].alias(@b2.inputs[0])
		@inputs[2].alias(@b3.inputs[0])
		
		@n1 = NotGate.new(sim, "n1", self)
		@n1.inputs[0].set_source(@b3.outputs[0])
		
		@a1 = AndGate.new(sim, "a1", self)
		@a2 = AndGate.new(sim, "a2", self)
		
		@a1.inputs[0].set_source(@b1.outputs[0])
		@a1.inputs[1].set_source(@b3.outputs[0]) # first data line and sel = 0
		@a2.inputs[0].set_source(@b2.outputs[0])
		@a2.inputs[1].set_source(@n1.outputs[0]) # second line line and sel = 1
		
		@o = OrGate.new(sim, "or", self)
		@o.inputs[0].set_source(@a1.outputs[0])  
		@o.inputs[1].set_source(@a2.outputs[0])
		
		@outputs[0].alias(@o.outputs[0])
	end
	
	# def to_s
		# ["mux2",super, @b1, @b2, @b3, @n1, @a1, @a2, @o,"mux2end"].join(",")
	# end
end

class Multiplexer4 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,6,1)
		@m1 = Multiplexer2.new(sim,"m1",self)
		@m2 = Multiplexer2.new(sim,"m2",self)
		@b = BufferGate.new(sim,"bg",self)
		@inputs[5].alias(@b.inputs[0])
		@inputs[0].alias(@m1.inputs[0])
		@inputs[1].alias(@m1.inputs[1])
		@inputs[2].alias(@m2.inputs[0])
		@inputs[3].alias(@m2.inputs[1])
		@mo = Multiplexer2.new(sim,"m_out",self)
		@mo.inputs[0].set_source(@m1.outputs[0])
		@mo.inputs[1].set_source(@m2.outputs[0])
		@m1.inputs[2].set_source(@b.outputs[0])
		@m2.inputs[2].set_source(@b.outputs[0])
		@inputs[4].alias(@mo.inputs[2])
		@outputs[0].alias(@mo.outputs[0])	
	end
	
	# def to_s
		# puts @b.inputs[0].get_value()
		# @b.to_s		
		# [super, @m1.to_s, @m2.to_s, @mo.to_s, @b].join(":")
	# end
end

class Multiplexer8 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,11,1)
				
		@m1 = Multiplexer4.new(sim, "m1", self)
		@m2 = Multiplexer4.new(sim, "m2", self)
		@b1 = BufferGate.new(sim, "b1", self)
		@b2 = BufferGate.new(sim, "b2", self)
		
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
		
		@mo = Multiplexer2.new(sim, "m_out", self)
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

class Multiplexer16 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,20,1) # 16 inputs, 4 select
		
		@m = Array.new(4) do |n| Multiplexer4.new(sim, "mux4_#{n}", self) end
		@addr = BufferSet.new(sim,"addr", self,4)
		
		# map inputs into multiplexers
		
		(0...4).each do |mi|
			(0...4).each do |bi|
				@inputs[mi*4+bi].alias(@m[mi].inputs[bi])
			end
		end
		
		# low bits of address
		@inputs[16].alias(@addr.inputs[0])
		@inputs[17].alias(@addr.inputs[1])
		@inputs[18].alias(@addr.inputs[2])
		@inputs[19].alias(@addr.inputs[3])
		
		@mo = Multiplexer4.new(sim, "mout", self)
		@mo.inputs[0].set_source(@m[0].outputs[0])
		@mo.inputs[1].set_source(@m[1].outputs[0])
		@mo.inputs[2].set_source(@m[2].outputs[0])
		@mo.inputs[3].set_source(@m[3].outputs[0])
		
		(0...4).each do |mi|			
			@m[mi].inputs[4].set_source(@addr.outputs[2])		
			@m[mi].inputs[5].set_source(@addr.outputs[3])
		end
		
		@mo.inputs[4].set_source(@addr.outputs[0])
		@mo.inputs[5].set_source(@addr.outputs[1])
		@outputs[0].alias(@mo.outputs[0])	
	end
	
	def to_s
		[super, @m.join("").to_s, @addr, @mo.to_s].join("\n")
	end
end

class Demux2 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,2,2) # data, sel		
		sel = BufferGate.new(sim,"sel",self)
		not_sel = NotGate.new(sim,"not_sel",self)
		@inputs[1].alias(sel.inputs[0])
		not_sel.inputs[0].set_source(sel.outputs[0])
						
		data = BufferGate.new(sim, "data", self)
		a1 = AndGate.new(sim, "a1", self)
		@inputs[0].alias(data.inputs[0])
		a1.inputs[0].set_source(data.outputs[0])
		a1.inputs[1].set_source(not_sel.outputs[0])		
		a2 = AndGate.new(sim, "a2", self)
		a2.inputs[0].set_source(data.outputs[0])
		a2.inputs[1].set_source(sel.outputs[0])
		
		@outputs[1].alias(a1.outputs[0])
		@outputs[0].alias(a2.outputs[0])
		
	end
end 

class Demux4 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,3,4) # data, sel0, sel1 => out0, out1, out2, out3
		
		din = Demux2.new(sim, "data_in", self)
		d1 = Demux2.new(sim, "d1", self)
		d2 = Demux2.new(sim, "d2", self)		
		@inputs[0].alias(din.inputs[0])
		@inputs[1].alias(din.inputs[1])
		sel1 = BufferGate.new(sim, "sel", self)
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
	def initialize(sim,label,parent)
		super(sim,label,parent,4,8) # data, sel0, sel1, sel2 => out0, out1, out2, out3
		
		din = Demux2.new(sim, "data_in", self)
		d1 = Demux4.new(sim, "d1", self)
		d2 = Demux4.new(sim, "d2", self)		
		@inputs[0].alias(din.inputs[0])		
		@inputs[1].alias(din.inputs[1])
		
		sel1 = BufferGate.new(sim, "sel1", self)
		sel2 = BufferGate.new(sim, "sel2", self)
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

class Demux16 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,5,16) # data, addr (4) => out(16)
		
		@din = Demux4.new(sim,"data_in",self)
		@addr = BufferSet.new(sim,"addr", self, 4)
		
		@d = Array.new(4) do |n| Demux4.new(sim, "demux4_#{n}",self) end

		(0...4).each do |idx| 
			@inputs[1+idx].alias(@addr.inputs[idx])
		end
		
		@inputs[0].alias(@din.inputs[0])		

		# din uses first two high addr bits
		@din.inputs[1].set_source(@addr.outputs[0])
		@din.inputs[2].set_source(@addr.outputs[1])

		# set demux address lines
		(0...4).each do |di|
			@d[di].inputs[0].set_source(@din.outputs[di])
			(0...2).each do |ai|
				# puts @d[di].inputs.size
				@d[di].inputs[1 + ai].set_source(@addr.outputs[2 + ai])
			end
		end
		
		(0...4).each do |di|
			(0...4).each do |bi| 
				@outputs[di * 4 + bi].alias(@d[di].outputs[bi]) # MSB output
			end
		end		
	end
end	


class RAM8x8 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent,12,8) # 8 data bits, 3 select bits, load bit		
		
		@addr0 = BufferGate.new(sim,"addr0",self)
		@addr1 = BufferGate.new(sim,"addr1",self)
		@addr2 = BufferGate.new(sim,"addr2",self)
		@inputs[8].alias(@addr0.inputs[0])
		@inputs[9].alias(@addr1.inputs[0])
		@inputs[10].alias(@addr2.inputs[0])
		
		@load = Demux8.new(sim,"load",self)
		@inputs[11].alias(@load.inputs[0])
		@load.inputs[1].set_source(@addr0.outputs[0])
		@load.inputs[2].set_source(@addr1.outputs[0])
		@load.inputs[3].set_source(@addr2.outputs[0])
		
		@data = Array.new(8) do |i| BufferGate.new(sim, "data#{i}", self) end
		
		# 8 bits
		@m = Array.new(8) do |i| Multiplexer8.new(sim, "mux_#{i}", self) end  # 11/1
		@r = Array.new(8) do |i | Register8.new(sim, "reg_#{i}", self) end  # 11/1
		
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
	
	def override(values)	
		# chunks = values.split("\n")
		raise 'bad values' unless values.size == 8
		(0...8).each do |idx|	
			@r[idx].override(values[idx])			
		end
	end	
	
	def update 
		# puts @m[0].to_s
	end
	
	# def to_s
		# [super, @addr0, @addr1, @addr2, @m.collect do |m| m.to_s end.join(","), @r.collect do |r| r.to_s end.join(',')].join("\n")
	# end
end

class RAM8x64 < Component
	def initialize(sim,label,parent)
		super(sim,label,parent, 15, 8) # 8 data, # 6 addr, 1 load bit		
		
		@data = Array.new(8) do |n| BufferGate.new(sim, "data#{n}",self) end
		@addr = Array.new(6) do |n| BufferGate.new(sim, "addr#{n}",self) end
		
		(0...8).each do |idx|
			@inputs[idx].alias(@data[idx].inputs[0])
		end
		
		(0...6).each do |idx|
			@inputs[8 + idx].alias(@addr[idx].inputs[0])
		end
		
		@load = Demux8.new(sim, "load", self)
		@inputs[14].alias(@load.inputs[0])
		@load.inputs[1].set_source(@addr[0].outputs[0])
		@load.inputs[2].set_source(@addr[1].outputs[0])
		@load.inputs[3].set_source(@addr[2].outputs[0])
		
		@r = Array.new(8) do |n| RAM8x8.new(sim, "ram8x8_#{n}", self) end
		(0...8).each do |idx|
			(0...8).each do |j|
				@r[idx].inputs[j].set_source(@data[j].outputs[0])
			end
			@r[idx].inputs[8].set_source(@addr[3].outputs[0]) # low bits to each sub ram module
			@r[idx].inputs[9].set_source(@addr[4].outputs[0])
			@r[idx].inputs[10].set_source(@addr[5].outputs[0])
			@r[idx].inputs[11].set_source(@load.outputs[7 - idx])  # output 0 is lsb for a demux			
		end
		
		@m = Array.new(8) do |i| Multiplexer8.new(sim, "mux8_#{i}", self) end  # 11/1
		(0...8).each do |idx|	
			@m[idx].inputs[8].set_source(@addr[0].outputs[0])
			@m[idx].inputs[9].set_source(@addr[1].outputs[0])
			@m[idx].inputs[10].set_source(@addr[2].outputs[0])		
			(0...8).each do |j|
				@m[j].inputs[idx].set_source(@r[7 - idx].outputs[j])
			end	
			@outputs[idx].alias(@m[idx].outputs[0])
		end		
	end
	
	# def to_s
		# [@data.join(""),@addr.join(""),@load,@r.join(""),@m.join("")].join("\n")
	# end
	
	def dump(off = 0)
		# [@addr0.outputs[0],@addr1.outputs[0],@addr2.outputs[0]].collect do |o| o.get_value() ? '1' : '0' end.join("") + "\n" +
		(0...@r.size).collect do |idx|		
			@r[idx].dump(idx * 8)
		end.join("\n")
	end

	def override(values)
		raise 'bad input' unless values.size == 64
		idx = 0
		# puts values.size
		values.each_slice(8) do |chunk|
			@r[idx].override(chunk)
			idx += 1
		end
	end
	
	
	def load_file(filename)
		override(File.readlines(filename).collect do |line| line.strip end)
	end
end

class RAM8x256 < Component

	def initialize(sim,label,parent)
		super(sim,label,parent, 17, 8)
		# pass the 8 bits of data into each of the four 64 byte ram modules		
		@data = Array.new(8) do |n| BufferGate.new(sim,"data#{n}",self) end
		# pass the low 6 bits of address into each of the four 64 byte ram modules
		@addr = Array.new(8) do |n| BufferGate.new(sim,"addr#{n}",self) end
		# use the remaining 2 bits to demux the load register into the correct of the 4 modules
		# and again to an array of 8 muxes to use the output of the correct of the 4 modules
		
		@load = Demux4.new(sim, "load", self) # 3/4
		@inputs[16].alias(@load.inputs[0])
		@load.inputs[1].set_source(@addr[0].outputs[0])
		@load.inputs[2].set_source(@addr[1].outputs[0])
		
		@r = Array.new(4) do |i| RAM8x64.new(sim, "ram8x64+#{i}", self) end
			
		(0...8).each do |idx|
			@inputs[idx].alias(@data[idx].inputs[0])
			@inputs[idx + 8].alias(@addr[idx].inputs[0])
		end
			
		(0...4).each do |mi|
            (0...8).each do |bi|
				@r[mi].inputs[bi].set_source(@data[bi].outputs[0])
			end
			@r[mi].inputs[8].set_source(@addr[2].outputs[0]) 
			@r[mi].inputs[9].set_source(@addr[3].outputs[0])
			@r[mi].inputs[10].set_source(@addr[4].outputs[0])
			@r[mi].inputs[11].set_source(@addr[5].outputs[0]) 
			@r[mi].inputs[12].set_source(@addr[6].outputs[0])
			@r[mi].inputs[13].set_source(@addr[7].outputs[0])			
			@r[mi].inputs[14].set_source(@load.outputs[3 - mi])  # output 0 is lsb for a demux			
		end
		
		@m = Array.new(8) do |i| Multiplexer4.new(sim, "mux4_#{i}", self) end  # 6/1
		(0...8).each do |bi|	
			@m[bi].inputs[4].set_source(@addr[0].outputs[0])
			@m[bi].inputs[5].set_source(@addr[1].outputs[0])
			(0...4).each do |mi|
				@m[bi].inputs[mi].set_source(@r[3 - mi].outputs[bi])	
			end	
			@outputs[bi].alias(@m[bi].outputs[0])
		end	
	end
	
	def dump(off = 0)
		# [@addr0.outputs[0],@addr1.outputs[0],@addr2.outputs[0]].collect do |o| o.get_value() ? '1' : '0' end.join("") + "\n" +
		(0...@r.size).collect do |idx|		
			@r[idx].dump(idx * 8)
		end.join("\n")
	end

	def override(values)
		raise 'bad input' unless values.size == 256
		idx = 0
		# puts values.size
		values.each_slice(64) do |chunk|
			@r[idx].override(chunk)
			idx += 1
		end
	end	
	
	def to_s
		[super,@r.join("\n")]
	end
	
	def load_file(filename)
		override(File.readlines(filename).collect do |line| line.strip end)
	end
end

class RAM8x1024 < Component

	def initialize(sim,label,parent)
		super(sim,label,parent, 19, 8)  # 8 data, 10 address, load bit
		# pass the 8 bits of data into each of the four 64 byte ram modules		
		@data = BufferSet.new(sim,"data",self,8)
		# pass the low 8 bits of address into each of the four 64 byte ram modules
		@addr = BufferSet.new(sim,"addr",self,10)
		# use the remaining 2 bits to demux the load register into the correct of the 4 modules
		# and again to an array of 8 muxes to use the output of the correct of the 4 modules
		
		@load = Demux4.new(sim,"load",self) # 3/4
		@inputs[18].alias(@load.inputs[0]) # load bit
		@load.inputs[1].set_source(@addr.outputs[0])
		@load.inputs[2].set_source(@addr.outputs[1])
		
		@r = Array.new(4) do |i| RAM8x256.new(sim,"ram8x256_#{i}",self) end # 17 (8 data, 8 addr, 1 load) ,8
			
		(0...8).each do |idx|
			@inputs[idx].alias(@data.inputs[idx])
			
		end
		(0...10).each do |ai|
			@inputs[ai + 8].alias(@addr.inputs[ai])
		end
			
		(0...4).each do |mi|
            (0...8).each do |bi|
				@r[mi].inputs[bi].set_source(@data.outputs[bi])
			end
			@r[mi].inputs[8].set_source(@addr.outputs[2]) 
			@r[mi].inputs[9].set_source(@addr.outputs[3])
			@r[mi].inputs[10].set_source(@addr.outputs[4])
			@r[mi].inputs[11].set_source(@addr.outputs[5]) 
			@r[mi].inputs[12].set_source(@addr.outputs[6])
			@r[mi].inputs[13].set_source(@addr.outputs[7])			
			@r[mi].inputs[14].set_source(@addr.outputs[8])
			@r[mi].inputs[15].set_source(@addr.outputs[9])	
			@r[mi].inputs[16].set_source(@load.outputs[3 - mi])  # output 0 is lsb for a demux			
		end
		
		@m = Array.new(8) do |i| Multiplexer4.new(sim,"mux4_#{i}",self) end  # 6/1
		(0...8).each do |bi|	
			@m[bi].inputs[4].set_source(@addr.outputs[0])
			@m[bi].inputs[5].set_source(@addr.outputs[1])
			(0...4).each do |mi|
				@m[bi].inputs[mi].set_source(@r[3 - mi].outputs[bi])	
			end	
			@outputs[bi].alias(@m[bi].outputs[0])
		end	
	end
	
	def dump(off = 0)
		# [@addr0.outputs[0],@addr1.outputs[0],@addr2.outputs[0]].collect do |o| o.get_value() ? '1' : '0' end.join("") + "\n" +
		(0...@r.size).collect do |idx|		
			@r[idx].dump(idx * 8)
		end.join("\n")
	end

	def override(values)
		raise 'bad input' unless values.size == 1024
		idx = 0
		# puts values.size
		values.each_slice(256) do |chunk|
			@r[idx].override(chunk)
			idx += 1
		end
	end	
	
	def to_s
		[super,@r.join("\n")]
	end
	
	def load_file(filename)
		override(File.readlines(filename).collect do |line| line.strip end)
	end
end

class ROM8x1024 < Component

	def initialize(sim,label,parent)
		super(sim,label,parent, 10, 8)  # 10 address

		# pass the low 8 bits of address into each of the four 64 byte ram modules
		@addr = BufferSet.new(sim,"addr",self,10)
		# use the remaining 2 bits to demux the load register into the correct of the 4 modules
		# and again to an array of 8 muxes to use the output of the correct of the 4 modules
		
		@r = Array.new(4) do |i| RAM8x256.new(sim,"ram8x256_#{i}",self) end # 17 (8 data, 8 addr, 1 load) ,8
			
		(0...10).each do |ai|
			@inputs[ai].alias(@addr.inputs[ai])
		end
			
		(0...4).each do |mi|
            (0...8).each do |bi|
				@r[mi].inputs[bi].set_source(@sim.false_signal.outputs[0])
			end
			@r[mi].inputs[8].set_source(@addr.outputs[2]) 
			@r[mi].inputs[9].set_source(@addr.outputs[3])
			@r[mi].inputs[10].set_source(@addr.outputs[4])
			@r[mi].inputs[11].set_source(@addr.outputs[5]) 
			@r[mi].inputs[12].set_source(@addr.outputs[6])
			@r[mi].inputs[13].set_source(@addr.outputs[7])			
			@r[mi].inputs[14].set_source(@addr.outputs[8])
			@r[mi].inputs[15].set_source(@addr.outputs[9])	
			@r[mi].inputs[16].set_source(@sim.false_signal.outputs[0])		
		end
		
		@m = Array.new(8) do |i| Multiplexer4.new(sim,"mux4_#{i}",self) end  # 6/1
		(0...8).each do |bi|	
			@m[bi].inputs[4].set_source(@addr.outputs[0])
			@m[bi].inputs[5].set_source(@addr.outputs[1])
			(0...4).each do |mi|
				@m[bi].inputs[mi].set_source(@r[3 - mi].outputs[bi])	
			end	
			@outputs[bi].alias(@m[bi].outputs[0])
		end	
	end
	
	def dump(off = 0)
		# [@addr0.outputs[0],@addr1.outputs[0],@addr2.outputs[0]].collect do |o| o.get_value() ? '1' : '0' end.join("") + "\n" +
		(0...@r.size).collect do |idx|		
			@r[idx].dump(idx * 8)
		end.join("\n")
	end

	def override(values)
		raise 'bad input' unless values.size == 1024
		idx = 0
		# puts values.size
		values.each_slice(256) do |chunk|
			@r[idx].override(chunk)
			idx += 1
		end
	end	
	
	def to_s
		[super,@r.join("\n")]
	end
	
	def load_file(filename)
		override(File.readlines(filename).collect do |line| line.strip end)
	end
end


class ProgramCounter < Component
	def initialize(sim,label,parent) 
		super(sim,label,parent,10,8) # 8 data, increment, jump
		@r = Register8.new(sim, "reg", self) #9,8
		@add = FullAdder8.new(sim, "add", self)
		
		@m = Array.new(8) do |i| Multiplexer2.new(sim, "mux2_#{i}", self) end
					
		@inc = BufferGate.new(sim, "inc", self)
		@jmp = BufferGate.new(sim, "jmp", self)
			
		(0...8).each do |idx|
			@inputs[idx].alias(@m[idx].inputs[0])
			@outputs[idx].alias(@r.outputs[idx])
			@m[idx].inputs[1].set_source(@add.outputs[idx])
			@r.inputs[idx].set_source(@m[idx].outputs[0])
			@add.inputs[idx].set_source(@r.outputs[idx])
			@add.inputs[8+idx].set_source(@sim.false_signal.outputs[0]) # TODO: is this okay?
			@m[idx].inputs[2].set_source(@jmp.outputs[0])
		end
		@inputs[8].alias(@inc.inputs[0])
		@inputs[9].alias(@jmp.inputs[0])
		@r.inputs[8].set_source(@inc.outputs[0])
		
		# @carryin = OrGate.new()
		# @carryin.inputs[0].set_source(@inc.outputs[0])
		# @carryin.inputs[1].set_source(@jmp.outputs[0])
		# carry in 1 if incrementing...
		@add.inputs[16].set_source(@inc.outputs[0])
	end
	
	def to_s
		[super, @r, @add.to_s, @m.join(""), @inc, @jmp].join("\n")
	end
end

class LoopCounter < Component
	def initialize(sim, label, parent, bits = 4)
		super(sim, label, parent, bits + 3, bits) # jump, enable, zero
		@bits = bits
		
		@jump = BufferGate.new(sim, "jump", self)		
		@inputs[bits].alias(@jump.inputs[0])
		
		@zero = BufferGate.new(sim, "zero", self)
		@inputs[bits+2].alias(@zero.inputs[0])
		
		@r = RegisterN.new(sim, "reg", self, bits)	
		@m = Array.new(bits) do |i| Multiplexer4.new(sim, "mux" + i.to_s, self) end # 6/1
		@add = Array.new(bits) do |i| FullAdder.new(sim, "add" + i.to_s, self) end  # 3/2
		
		(0...bits).each do |bi|
			@inputs[bi].alias(@m[bi].inputs[2])
			
			@m[bi].inputs[3].set_source(@add[bi].outputs[0])
			@m[bi].inputs[0].set_source(@sim.false_signal.outputs[0]) # high bits are all zero to zero-jump
			@m[bi].inputs[1].set_source(@sim.false_signal.outputs[0])
			
			@m[bi].inputs[4].set_source(@zero.outputs[0])
			@m[bi].inputs[5].set_source(@jump.outputs[0])
			
			@add[bi].inputs[0].set_source(@r.outputs[bi])
			@add[bi].inputs[1].set_source(@sim.false_signal.outputs[0]) # 2nd addend is zero
			
			@r.inputs[bi].set_source(@m[bi].outputs[0])
			
			@outputs[bi].alias(@r.outputs[bi])
		end
						
		@inputs[bits+1].alias(@r.inputs[bits]) # enable
		
		@add[bits-1].inputs[2].set_source(@sim.true_signal.outputs[0])# carry in 1 to LSB
		(0...(bits-1)).each do |bi|
			@add[bi].inputs[2].set_source(@add[bi+1].outputs[1])
		end
	end
	
	def to_s
		[super, @jump, @zero, @r, @m.join(""), @add.join("")]
	end
end

class Microcode < Component
	def initialize(sim,label,parent, rom_in_filename, rom_out_filename)
		super(sim, label,parent,10, 16)

		@inst = BufferSet.new(@sim,"inst",self,6)
		@cntr = BufferSet.new(@sim,"cntr",self,4)		
		@rom_in = ROM8x1024.new(@sim, "microcodeROM_in", self)  # 8 data, 10 address, load bit
		@rom_out = ROM8x1024.new(@sim, "microcodeROM_out", self)
		@rom_in.load_file(rom_in_filename)
		@rom_out.load_file(rom_out_filename)
		
		(0...6).each do |idx|
			@inputs[idx].alias(@inst.inputs[idx])
			@rom_in.inputs[idx + 8].set_source(@inst.outputs[idx])
			@rom_out.inputs[idx + 8].set_source(@inst.outputs[idx])
			# 8 data, 10 address, load bit
		end
		(0...4).each do |idx|
			@inputs[idx + 6].alias(@cntr.inputs[idx])
			@rom_in.inputs[idx + 8 + 6].set_source(@cntr.outputs[idx])
			@rom_out.inputs[idx + 8 + 6].set_source(@cntr.outputs[idx])
		end
		
		(0...8).each do |idx|
			@outputs[idx].alias(@rom_in.outputs[idx])
			@outputs[idx + 8].alias(@rom_out.outputs[idx])
			
		end
	
	end
end

class Computer1
	attr_reader :label
	
	def path
		@label
	end
	
	def initialize()
		@sim = Simulation.new()
		@label = "Computer1"
	
		f = @sim.false_signal.outputs[0]
		t = @sim.true_signal.outputs[0]

		# @mar = Register8.new(@sim, "MAR", self) # memory address register
		# @ram = RAM8x64.new(@sim, "RAM", self) # 8 data + 6 addr + 1 enable
		# @pc = ProgramCounter.new(@sim, "PC", self) # 8 data, increment, jump
		@a = Register8.new(@sim, "A", self) # 8 data + 1 enable
		# @b = Register8.new(@sim, "B", self) # 8 data + 1 enable
		# @alu = ALU8.new(@sim, "ALU", self) # 8 data, 8 data, subtract  - 8 out
		
		#@ir = RegisterN.new(@sim,"IR",self,14) # 6 inst, 8 # instruction 9/8
		
		#@ir.override("0000000000000")
		@microcode = Microcode.new(@sim, "microcode", self, "computer1a.rom", "computer1b.rom") # 6 inst, 4 cntr > 16 outputs
		(0...10).each do |idx| @microcode.inputs[idx].set_source(f) end
		
		# @microcounter = LoopCounter.new(@sim,"microloop",self, 4) # 
		
		# @flags = RegisterN.new(@sim, 4)  # TBD				
		# @control_out = BufferSet.new(@sim,8)
		
		# @bus = Bus8x8.new(@sim) 
		#set bus inputs to low to avoid issues with unused sections
		# (0...72).each do |idx| @bus.inputs[idx].set_source(f) end 

		# (0...8).each do |idx| @bus.inputs[idx].set_source(@ram.outputs[idx]) end 
		# (0...8).each do |idx| @bus.inputs[8 + idx].set_source(@a.outputs[idx]) end 
		# (0...8).each do |idx| @bus.inputs[16 + idx].set_source(@b.outputs[idx]) end 
		# (0...8).each do |idx| @bus.inputs[24 + idx].set_source(@alu.outputs[idx]) end 
		# (0...8).each do |idx| @bus.inputs[32 + idx].set_source(@pc.outputs[idx]) end 
		# (0...8).each do |idx| @bus.inputs[40 + idx].set_source(@pc.outputs[idx]) end 
		
		# (0...8).each do |idx| @bus.inputs[64 + 7 - idx].set_source(@control_out.outputs[idx]) end 

		# (0...8).each do |idx| 
			# @ram.inputs[idx].set_source(@bus.outputs[idx])
			# @a.inputs[idx].set_source(@bus.outputs[idx])
			# @b.inputs[idx].set_source(@bus.outputs[idx])
			# @alu.inputs[idx].set_source(@bus.outputs[idx])
			# @pc.inputs[idx].set_source(@bus.outputs[idx])
			# @mar.inputs[idx].set_source(@bus.outputs[idx])
		# end
			
		# (0..8).each do |idx| @ram.inputs[idx + 8].set_source(@mar.outputs[idx]) end # addr + enable
		# @pc.inputs[8].set_source(t) # pc enable on
		# @pc.inputs[9].set_source(f) # jump off
		# @a.inputs[8].set_source(f)
		# @b.inputs[8].set_source(f)
		# (0...8).each do |idx| @alu.inputs[idx + 8].set_source(@b.outputs[idx]) end
		# @alu.inputs[16].set_source(f) # subtraction
		# @mar.inputs[8].set_source(f) # mar read from bus flag

		# @control_out.inputs[0].set_source(f) # ram
		# @control_out.inputs[1].set_source(f) # a
		# @control_out.inputs[2].set_source(f) # b
		# @control_out.inputs[3].set_source(f) # alu
		# @control_out.inputs[4].set_source(t) # pc
		# @control_out.inputs[5].set_source(f)
		# @control_out.inputs[6].set_source(f)
		# @control_out.inputs[7].set_source(f)
	
	end
	
	def display()		
		puts "BUS: " + (@bus.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join("")
		puts "PC:  " + (@pc.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join("")
		puts "A:   " + (@a.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join("")
		puts "B:   " + (@b.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join("")
		puts "ALU: " + (@alu.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join("")
		puts
		puts "          R     A   M  "
		puts "          A     L P A  "
		puts "          M A B U C R  "
		puts "Ctrl Out: " + (@control_out.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join(" ")
		puts "Ctrl In:  " + (@control_out.outputs.collect do |x| x.get_value() ? '1' : '0'  end).join(" ")
		
		# puts @pc.outputs.collect do |o| o ? '1' : '0' end.join("")
	end
	
	def run
	
	
	# data movement
		# movement
		# push
		# pop
		# lea - load pointer into register
		
	# arithmetic/logic
		# add
		# sub
		# inc, dec
		# imul, idiv
		# and,or,xor
		# not
		# neg
		# shl, shr - bit shift
		# 
	# control-flow
		# jmp
		# je, jne, jz, jg, jge, jl, jle
		# cmp - same as subtract except result is discarded.  sets falgs.  
		# call, ret - subroutines!
		
	
	# ip - instruction pointer - same as pc?
	# cf carry flag
	# df direction flag
	# if interrupt flag
	# esp stack pointer.  same as sp?
	# ebp base pointer
	# esi, edi?
	
	
		# how we do'in this?  4 inst, 4 op codes?  or 2-byte instructions?
		@ir.override("00000000")
	
		2.times() do 
			@sim.update
			display()
			s = gets 
		end
	end
end

# # ai in load signl
# # a out signal
# # b in
# # b out

# # 2x 8 inputs
# # eo out?
# # substract?

class ALU8 < Component
	def initialize(sim)
		super(sim,17,8)  # from bus, output
		
		add = FullAdderSub8.new(sim)		
		(0...8).each do |idx|
			@inputs[idx].alias(add.inputs[idx])
			@inputs[idx + 8].alias(add.inputs[idx + 8])
			@outputs[idx].alias(add.outputs[idx])
		end
		@inputs[16].alias(add.inputs[16])
		
		
	end
end
