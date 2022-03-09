require_relative 'components'
require_relative 'component_groups'

class Simulation
	def initialize()		
		@components = []		
		@main_clock = Clock.new
		@inv_clock = Clock.new
		@total_gates = Hash.new(0)
	end	
			
	def update(mode = :all)	
		@inv_clock.pulse if [:all, :low].include? mode
		@main_clock.pulse if [:all, :high].include? mode
	end
	
	def register_clocked_component(c, state)
		raise "use register_component" unless c.clocked?
		if state == :high
			@main_clock.register_component(c)
		elsif state == :low
			@inv_clock.register_component(c)
		else
			raise "invalid clocked component state #{state}"
		end
		c		
	end
	
	def register_component(c)
		raise "use register_clocked_component" if c.clocked?
		@components << c
		c
	end
	
	def gate_counts
		count = Hash.new(0)
		@components.each do |c|
			count[c.class] += 1
		end
		count
	end
	
	def show_gate_count(name)
		temp = @total_gates
		@total_gates = gate_counts
		puts name + ": " + @total_gates.diff(temp).to_s		
	end
end

class Hash
	def diff(rhs)
		result = {}
		(self.keys + rhs.keys).each do |key|
			result[key] = self[key] - rhs[key]
		end
		result
	end
	
	def plus(rhs)
		result = {}
		(self.keys + rhs.keys).each do |key|
			result[key] = self[key] + rhs[key]
		end
		result
	end
end

class Clock
	def initialize
		@components = []
	end
	
	def register_component(c)
		@components << c		
	end

	def pulse	
		@components.each do |c|
			c.pulse_start
		end
		@components.each do |c|
			c.pulse_finish
		end
	end
end
