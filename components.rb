class Component	
	attr_reader :inputs # for debug/display only

	def initialize(num_inputs)
		@inputs = Array.new(num_inputs)
	end
	
	def output
		@inputs.each_with_index do |i, idx|
			raise "input #{idx} not setup" unless i
		end
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
		super
		@inputs[0].output or @inputs[1].output
	end
end

class AndGate < Component
	def initialize()
		super(2)
	end
	
	def output
		super
		@inputs[0].output and @inputs[1].output
	end
end

class BufferGate < Component
	def initialize()
		super(1)
	end
	
	def output		
		super		
		@inputs[0].output		
	end
end

class XorGate < Component
	def initialize()
		super(2)
	end
	
	def output
		super
		@inputs[0].output ^ @inputs[1].output
	end
end	

class NotGate < Component
	def initialize()
		super(1)
	end
	
	def output
		super	
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
		super
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


