# 555 timer

class Clock
	attr_reader :state
	def initialize
		@components = []
		@state = :low
	end
	
	def register(c)
		@components << c
	end
	
	def half_pulse
		if @state == :low
			pulse_high
		else
			pulse_low
		end
	end
	
	def full_pulse
		half_pulse
		half_pulse
	end
	
	def pulse_high
		@state = :high
		@components.each do |c|
			c.pulse_high
		end
	end
	
	def pulse_low
		@state = :low
		@components.each do |c|
			c.pulse_low
		end
	end
end

class Component

	def initialize(num_inputs, num_outputs)
		@inputs = Array.new(num_inputs, false)
		@outputs = Array.new(num_outputs, false)
		@labels = {}		
		# update() call update in each child to make sure everythings setup
	end
	
	def update
		raise 'must override'
	end
	
	def pulse_high
	end
	def pulse_low
	end
	
	def set_input(n, val)
		raise 'bad input' if n > @inputs.size
		# could look up n in labels if a symbol		
		@inputs[n] = val
		update
		nil
	end
	
	def to_s
		@inputs.collect do |v| 
			v ? '0' : '1'
		end.join("") + ":" +
		@outputs.collect do |v| 
			v ? '0' : '1'
		end.join("")
	end
	
	def set_inputs(values)				
		values = [values] if values.class != Array #put into array if not already
		raise '# of inputs doesnt match' unless @inputs.size == values.size		
		
		@inputs = values.collect do |v|
			raise 'bad value' unless [true,false,0,1].include? v
			if v == 0
				false
			elsif v == 1
				true
			else
				v
			end
		end		
		update
	end
	
	
	def get_output(n)
		raise 'out of range' if n > @outputs.size
		@outputs[n]
	end
	
	def outputs
		@outputs.to_enum # to_enum prevents modification without making a copy
	end
	
	def method_missing(*vals)
		target = vals.first
		val = vals[1]
		
		if target.to_s.end_with? "="			
			port = @labels[target.to_s.chomp('=').to_sym]
			super unless port # method missing
			if port.first == :input 
				set_input(port.last, val)				
			elsif port.first == :output
				raise 'can''t set output directly'
			else
				raise 'not sure what to do with port type: ' + port.first
			end
		else
			port = @labels[target]
			super unless port # method missing
			if port.first == :input
				return @inputs[port.last]
			else
				return @outputs[port.last]			
			end
		end
	end
end

class DLatch < Component
	def initialize()
		super(2,1)
		@labels[:set] = [:input, 0]		
		@labels[:enable] = [:input, 1]
		@labels[:value] = [:output, 0]		
		# clk.register(self)
		# @clk = clk		
		
		update
	end 
	
	def pulse_high
		# if @input[0] and not @input[1]
			# @output[0] = true
			# @output[1] = false
		# elsif @input[1] and not @input[0]
			# @output[0] = false
			# @output[1] = true
		# elsif @input[1] and @input[1]
			# raise 'undefined behavior from sr latch'
		# end
	end 
	
	def pulse_low
	end
	
	def update
		# only set value if 'enable' is on
		if @inputs[1]
			@outputs[0] = @inputs[0]
		end			
	end	
end

class DFlipFlop < Component
	def initialize(clk)
		super(1,1)
		@labels[:set] = [:input, 0]				
		@labels[:value] = [:output, 0]		
		clk.register(self)		
		
		update
	end 
	
	# lock in the input on clock high
	def pulse_high			
		@outputs[0] = @inputs[0]				
	end 
	
	def pulse_low
	end
	
	def update		
	end	
end

class NotGate < Component
	def initialize()
		super(1,1)
		@labels[:a] = [:input, 0]		
		@labels[:x] = [:output, 0]
		update
	end 
	
	def update		
		@outputs[0] = not(@inputs[0])
	end	
end

class OrGate < Component
	def initialize()
		super(2,1)
		@labels[:a] = [:input, 0]
		@labels[:b] = [:input, 1]
		@labels[:x] = [:output, 0]
		update
	end 
	
	def update		
		@outputs[0] = @inputs[0] | @inputs[1]		
	end	
end

class NorGate < Component
	def initialize()
		super(2,1)
		@labels[:a] = [:input, 0]
		@labels[:b] = [:input, 1]
		@labels[:x] = [:output, 0]
		update
	end 
	
	def update		
		@outputs[0] = not(@inputs[0] | @inputs[1]		)
	end	
end

class AndGate < Component
	def initialize()
		super(2,1)
		@labels[:a] = [:input, 0]
		@labels[:b] = [:input, 1]
		@labels[:x] = [:output, 0]
		update
	end
	def update		
		@outputs[0] = @inputs[0] & @inputs[1]		
	end
end

class XorGate < Component
	def initialize()
		super(2,1)
		@labels[:a] = [:input, 0]
		@labels[:b] = [:input, 1]
		@labels[:x] = [:output, 0]
		update
	end
	def update		
		@outputs[0] = @inputs[0] ^ @inputs[1]		
	end
end

class NandGate < Component
	def initialize()
		super(2,1)
		@labels[:a] = [:input, 0]
		@labels[:b] = [:input, 1]
		@labels[:x] = [:output, 0]
		update
	end
	def update		
		@outputs[0] = not(@inputs[0] & @inputs[1])
	end
end

class And4Gate < Component
	def initialize()		
		super(4,1)
		@labels[:a] = [:input, 0]
		@labels[:b] = [:input, 1]
		@labels[:c] = [:input, 2]
		@labels[:d] = [:input, 3]
		@labels[:x] = [:output, 0]		
		@comps = {}
		@comps[:a1] = AndGate.new
		@comps[:a2] = AndGate.new
		@comps[:ac] = AndGate.new		
		update
	end
	
	def update
		@comps[:a1].set_inputs([@inputs[0],@inputs[1]])
		@comps[:a2].set_inputs([@inputs[2],@inputs[3]])
		@comps[:ac].set_inputs([@comps[:a1].get_output(0),@comps[:a2].get_output(0)])
		@outputs[0] = @comps[:ac].get_output(0)
	end
end