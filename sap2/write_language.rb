require_relative 'language.rb'

operands = []

operands << Operand.new("ADD B","Assign (A + B) to A using ALU",0x80)
operands.last.add_microcode("B_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_ADD | A_LOAD")

operands << Operand.new("ADD C","Assign (A + C) to A using ALU",0x81)
operands.last.add_microcode("C_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_ADD | A_LOAD")

operands << Operand.new("SUB B","Assign (A - B) to A using ALU",0x90)
operands.last.add_microcode("B_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_SUB | A_LOAD")

operands << Operand.new("SUB C","Assign (A - C) to A using ALU",0x91)
operands.last.add_microcode("C_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_SUB | A_LOAD")

operands << Operand.new("CMA","Assign (1's complement of A) to A using ALU",0x2F)
operands.last.add_microcode("ALU_WRITE | ALU_OP_NOT | A_LOAD")

operands << Operand.new("ANA B","Assign bitwise (A AND B) to A using ALU",0xA0)
operands.last.add_microcode("B_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_AND | A_LOAD")

operands << Operand.new("ANA C","Assign bitwise (A AND C) to A using ALU",0xA1)
operands.last.add_microcode("C_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_AND | A_LOAD")

operands << Operand.new("ANI","Assign bitwise (A AND immediate value) to A using ALU",0xE6)
operands.last.add_param(:value)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | TMP_LOAD | PC_INC")
operands.last.add_microcode("ALU_WRITE | ALU_OP_AND | A_LOAD")

operands << Operand.new("ORA B","Assign bitwise (A OR B) to A using ALU",0xB0)
operands.last.add_microcode("B_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_OR | A_LOAD")

operands << Operand.new("ORA C","Assign bitwise (A OR C) to A using ALU",0xB1)
operands.last.add_microcode("C_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_OR | A_LOAD")

operands << Operand.new("ORI","Assign bitwise (A OR immediate value) to A using ALU",0xF6)
operands.last.add_param(:value)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | TMP_LOAD | PC_INC")
operands.last.add_microcode("ALU_WRITE | ALU_OP_OR | A_LOAD")

operands << Operand.new("XRA B","Assign bitwise (A XOR B) to A using ALU",0xA8)
operands.last.add_microcode("B_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_XOR | A_LOAD")

operands << Operand.new("XRA C","Assign bitwise (A XOR C) to A using ALU",0xA9)
operands.last.add_microcode("C_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_XOR | A_LOAD")

operands << Operand.new("XRI","Assign bitwise (A XOR immediate value) to A using ALU",0xEE)
operands.last.add_param(:value)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | TMP_LOAD | PC_INC")
operands.last.add_microcode("ALU_WRITE | ALU_OP_XOR | A_LOAD")

operands << Operand.new("MVI A","Assign A reg with immediate value",0x3E)
operands.last.add_param(:value)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | A_LOAD | PC_INC")

operands << Operand.new("MVI B","Assign B reg with immediate value",0x06)
operands.last.add_param(:value)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | B_LOAD | PC_INC")

operands << Operand.new("MVI C","Assign C reg with immediate value",0x0E)
operands.last.add_param(:value)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | C_LOAD | PC_INC")

operands << Operand.new("INR A","Assign A + 1 to A using ALU",0x3C)
operands.last.add_microcode("A_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_INC | A_LOAD")

operands << Operand.new("INR B","Assign B + 1 to B using ALU",0x04)
operands.last.add_microcode("B_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_INC | B_LOAD")

operands << Operand.new("INR C","Assign C + 1 to C using ALU",0x0C)
operands.last.add_microcode("C_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_INC | C_LOAD")

operands << Operand.new("DCR A","Assign A - 1 to A using ALU",0x3D)
operands.last.add_microcode("A_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_DEC | A_LOAD")

operands << Operand.new("DCR B","Assign B - 1 to B using ALU",0x05)
operands.last.add_microcode("B_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_DEC | B_LOAD")

operands << Operand.new("DCR C","Assign C - 1 to C using ALU",0x0D)
operands.last.add_microcode("C_WRITE | TMP_LOAD")
operands.last.add_microcode("ALU_WRITE | ALU_OP_DEC | C_LOAD")

operands << Operand.new("JMP","Jump to label",0xC3)
operands.last.add_param(:label)
operands.last.add_microcode("PC_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("RAM_WRITE | PC_LOAD")

operands << Operand.new("JNZ","Jump to label if ALU ZERO flag not set",0xC2)
operands.last.add_param(:label)
operands.last.add_microcode("PC_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("RAM_WRITE | PC_LOAD")

operands << Operand.new("MOV A,B","Assign A to B",0x78)
operands.last.add_microcode("B_WRITE | A_LOAD")

operands << Operand.new("MOV A,C","Assign A to B",0x79)
operands.last.add_microcode("C_WRITE | A_LOAD")

operands << Operand.new("MOV B,A","Assign A to B",0x47)
operands.last.add_microcode("A_WRITE | B_LOAD")

operands << Operand.new("MOV B,C","Assign A to B",0x41)
operands.last.add_microcode("C_WRITE | B_LOAD")

operands << Operand.new("MOV C,A","Assign A to B",0x4F)
operands.last.add_microcode("A_WRITE | C_LOAD")

operands << Operand.new("MOV C,B","Assign A to B",0x48)
operands.last.add_microcode("B_WRITE | C_LOAD")

operands << Operand.new("LDA","Assign contents of RAM at specified address to A",0x3A)
operands.last.add_param(:variable)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("RAM_WRITE | A_LOAD")

operands << Operand.new("STA","Assign A to specified RAM address",0x32)
operands.last.add_param(:variable)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("A_WRITE | RAM_LOAD")

operands << Operand.new("LDB","Assign contents of RAM at specified address to B",0x38)
operands.last.add_param(:variable)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("RAM_WRITE | B_LOAD")

operands << Operand.new("STB","Assign B to specified RAM address",0x30)
operands.last.add_param(:variable)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("B_WRITE | RAM_LOAD")

operands << Operand.new("LDC","Assign contents of RAM at specified address to C",0x28)
operands.last.add_param(:variable)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("RAM_WRITE | C_LOAD")

operands << Operand.new("STC","Assign C to specified RAM address",0x20)
operands.last.add_param(:variable)
operands.last.add_microcode("PC_WRITE | MAR_LOAD")
operands.last.add_microcode("RAM_WRITE | MAR_LOAD | PC_INC")
operands.last.add_microcode("C_WRITE | RAM_LOAD")

operands << Operand.new("OUT","Assign A to OUTPUT register",0xD3)
operands.last.add_microcode("A_WRITE | OUT_LOAD")

operands << Operand.new("NOP","No-op",0x00)
operands << Operand.new("HLT","HALT program operation",0x76)

File.open("language.yaml","w") do |out|
	out.puts operands.to_yaml
end