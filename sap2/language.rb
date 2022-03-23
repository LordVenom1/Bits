require 'yaml'

#########################################################################
# represent machine language as Operands in global OPERANDS variable
#########################################################################

MC_INST_WIDTH = 20
MC_OPCODE_SIZE = 8
MC_INST_SET_SIZE = 2 ** MC_OPCODE_SIZE
MC_CNTR_ADDR_SIZE = 4 # 6-bit ring counter?
MC_CNTR_HEIGHT = 2 ** MC_CNTR_ADDR_SIZE
MC_SIZE = MC_INST_SET_SIZE * MC_CNTR_HEIGHT

module FLAGS
	pos = 19
	PC_INC =    2 ** pos ; pos = pos - 1
	PC_LOAD =   2 ** pos ; pos = pos - 1
	PC_WRITE =  2 ** pos ; pos = pos - 1
	MAR_LOAD =  2 ** pos ; pos = pos - 1
	RAM_LOAD =  2 ** pos ; pos = pos - 1
	RAM_WRITE = 2 ** pos ; pos = pos - 1
	IR_LOAD =   2 ** pos ; pos = pos - 1
	IR_WRITE =  2 ** pos ; pos = pos - 1
	A_LOAD =    2 ** pos ; pos = pos - 1
	A_WRITE =   2 ** pos ; pos = pos - 1
	B_LOAD =    2 ** pos ; pos = pos - 1
	B_WRITE =   2 ** pos ; pos = pos - 1
	C_LOAD =    2 ** pos ; pos = pos - 1
	C_WRITE =   2 ** pos ; pos = pos - 1
	OUT_LOAD =  2 ** pos ; pos = pos - 1
	TMP_LOAD =  2 ** pos ; pos = pos - 1
	ALU_WRITE = 2 ** pos ; pos = pos - 1
	ALU_OP1 =   2 ** pos ; pos = pos - 1
	ALU_OP2 =   2 ** pos ; pos = pos - 1
	ALU_OP3 =   2 ** pos ; pos = pos - 1
	ALU_OP_ADD = 0
	ALU_OP_SUB = ALU_OP3
	ALU_OP_INC = ALU_OP2
	ALU_OP_DEC = ALU_OP2 | ALU_OP3
	ALU_OP_NOT = ALU_OP1
	ALU_OP_AND = ALU_OP1 | ALU_OP3
	ALU_OP_OR  = ALU_OP1 | ALU_OP2
	ALU_OP_XOR = ALU_OP1 | ALU_OP2 + ALU_OP3
end

class Operand
	include FLAGS	
	@@list = []
	
	attr_reader :opcode, :addr, :params
	def initialize(opcode, desc, addr)
		@opcode = opcode
		@desc = desc
		@addr = addr
		@params = []
		@microcode = []
		
		@regexp = nil				
	end	
	
	def to_h
		{
			opcode: @opcode,
			desc: @desc,
			addr: @addr,
			params: @params,
			microcode: @microcode
		}
	end
		
	def add_param(type)
		raise "bad param type #{type}" unless [:label, :value, :variable].include? type
		@params << type
	end
	
	def add_microcode(value)
		raise "too many microcodes" if @microcode.size >= (MC_CNTR_HEIGHT - 2) # first two are fetch cycle
		@microcode << value
	end
	
	def decode_addr
		@addr.to_s(2).rjust(MC_OPCODE_SIZE,'0')
	end
	
	def decode_microcode
		@microcode.collect do |mc|
			val = eval(mc)
			val.to_s(2).rjust(MC_INST_WIDTH,'0')
		end
	end
	
	def self.all
		return @@list if @@list.size > 0
		
		@@list = YAML::load_file("language.yaml")
		@@list
	end
	
	def parse_re
		@regexp = generate_asm_regex if not @regexp
		@regexp
	end
		
	def generate_asm_regex
		cmd = [@opcode]
		@params.each do |p|
			case p
				when :label
					cmd << '\s+([a-zA-Z0-9]+)'
				when :variable
					cmd << '\s+([a-zA-Z0-9]+)'
				when :value
					cmd << '\s*,?\s*([0-9]+)'
			end
		end
		# puts cmd.join("")
		Regexp.new(cmd.join(""))
	end
end


