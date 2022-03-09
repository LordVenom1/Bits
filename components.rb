TRACING = true

class Component	
	attr_reader :inputs # for debug

	def initialize(num_inputs)
		@inputs = Array.new(num_inputs)
	end
	
	def output
		# raise "invalid input" if DEBUG and @inputs.any? do |i| (not [true,false].include?(i.output) end
	end
	
	def clocked?
		false
	end
	
	def set_input(n, output)
		raise 'bad output' unless output.class.ancestors.include? Component
		@inputs[n] = output
	end
	
	def set_inputs(outputs)
		outputs.flatten!
		raise "incorrect count" if outputs.size != @inputs.size
		@inputs = outputs
	end
end

class FalseSignal < Component
	def initialize()
		super(0)
	end
	
	def output		
		false
	end
end 

class TrueSignal < Component
	def initialize()
		super(0)
	end
	def output
		true
	end
end 

class Simulation
	TRUE = TrueSignal.new
	FALSE = FalseSignal.new
end

class OrGate < Component
	def initialize()
		super(2)
	end
	
	def output	
		raise 'input 0 missing' unless @inputs[0]
		raise 'input 1 missing' unless @inputs[1]
		@inputs[0].output or @inputs[1].output
	end
end

class AndGate < Component
	def initialize()
		super(2)
	end
	
	def output
		raise 'input 0 missing' unless @inputs[0]
		raise 'input 1 missing' unless @inputs[1]
		@inputs[0].output and @inputs[1].output
	end
end

class BufferGate < Component
	def initialize()
		super(1)
	end
	
	def output		
		raise "input 0 missing on #{self}" unless @inputs[0]		
		@inputs[0].output		
	end
end

class XorGate < Component
	def initialize()
		super(2)
	end
	
	def output
		raise 'input 0 missing' unless @inputs[0]
		raise 'input 1 missing' unless @inputs[1]
		@inputs[0].output ^ @inputs[1].output
	end
end	

class NotGate < Component
	def initialize()
		super(1)
	end
	
	def output
		raise 'input 0 missing' unless @inputs[0]		
		not (@inputs[0].output)
	end
end

class NandGate < AndGate
	def output
		not(super)		
	end
end

class NorGate < OrGate
	def output
		not(super)		
	end
end

class DataLatch < Component
	def initialize(initial_value = false)
		super(1)
		@value = initial_value
		self
	end
	
	def output
		@value
	end
	
	def clocked?
		true
	end
	
	def pulse_start
		@cache = @inputs[0].output
	end
	
	def pulse_finish
		@value = @cache
		@cache = nil
	end	
end


