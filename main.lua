--!strict

type Registers = { A: number, B: number, C: number, D: number }
type Instruction = number
type InstructionSet = { [number]: () -> () }
type Memory = { [number]: number }

local OPCODES = {
    ADD = 0x01,
    SUB = 0x02,
    MUL = 0x03,
    DIV = 0x04,
    LOAD = 0x05,
    STORE = 0x06,
}

local REGISTERS: Registers = {
    A = 0,
    B = 1,
    C = 2,
    D = 3,
}

local state = {
    registers = { [REGISTERS.A] = 10, [REGISTERS.B] = 5, [REGISTERS.C] = 0, [REGISTERS.D] = 0 }, -- Initialize registers with values
    code = {} :: { Instruction },
    pc = 1,
    memory = {} :: Memory,
    next_mem_addr = 0,
}

local instructionSet: InstructionSet = {}

instructionSet[OPCODES.ADD] = function()
    local regc = bit32.rshift(bit32.band(state.code[state.pc], 0x00030000), 16)
    local rega = bit32.rshift(bit32.band(state.code[state.pc], 0x000C0000), 18)
    local regb = bit32.rshift(bit32.band(state.code[state.pc], 0x03000000), 24)
    state.registers[regc] = state.registers[rega] + state.registers[regb]
end

instructionSet[OPCODES.SUB] = function()
    local regc = bit32.rshift(bit32.band(state.code[state.pc], 0x00030000), 16)
    local rega = bit32.rshift(bit32.band(state.code[state.pc], 0x000C0000), 18)
    local regb = bit32.rshift(bit32.band(state.code[state.pc], 0x03000000), 24)
    state.registers[regc] = state.registers[rega] - state.registers[regb]
end

instructionSet[OPCODES.LOAD] = function()
    local regc = bit32.rshift(bit32.band(state.code[state.pc], 0x00030000), 16)
    local addr = bit32.rshift(bit32.band(state.code[state.pc], 0xFFFF0000), 16)
    state.registers[regc] = state.memory[addr]
end

instructionSet[OPCODES.STORE] = function()
    local regc = bit32.rshift(bit32.band(state.code[state.pc], 0x00030000), 16)
    local addr = bit32.rshift(bit32.band(state.code[state.pc], 0xFFFF0000), 16)
    state.memory[addr] = state.registers[regc]
end

local function encode(opcode: number, regc: number, operand: number): Instruction
    local instruction = opcode
    instruction = bit32.bor(instruction, bit32.lshift(regc, 16))
    instruction = bit32.bor(instruction, bit32.lshift(operand, 16))
    return instruction
end

local function encode2(opcode: number, regc: number, rega: number, regb: number): Instruction
    local instruction = opcode
    instruction = bit32.bor(instruction, bit32.lshift(regc, 16))
    instruction = bit32.bor(instruction, bit32.lshift(rega, 18))
    instruction = bit32.bor(instruction, bit32.lshift(regb, 24))
    return instruction
end

local function allocate(): number
    local addr = state.next_mem_addr
    state.next_mem_addr += 1
    return addr
end

local function execute()
    local opcode = bit32.band(state.code[state.pc], 0xFF)
    local instruction = instructionSet[opcode]

    if instruction then
        instruction()
        state.pc += 1
    else
        error(`Unknown opcode: {opcode}`)
    end
end

local x_addr = allocate()
local y_addr = allocate()
local z_addr = allocate()

state.code = {
    encode(OPCODES.LOAD, REGISTERS.A, x_addr), -- load value at x_addr into register A
    encode(OPCODES.LOAD, REGISTERS.B, y_addr), -- load value at y_addr into register B
    encode2(OPCODES.ADD, REGISTERS.C, REGISTERS.A, REGISTERS.B), -- add A and B, store result in C
    encode(OPCODES.STORE, REGISTERS.C, z_addr),
}

state.memory[x_addr] = 10
state.memory[y_addr] = 20

while state.pc <= #state.code do
    execute()
end

print("Final result:")
print("Register C:", state.registers[REGISTERS.C]) -- 30
print("Memory z_addr:", state.memory[z_addr]) -- 30
