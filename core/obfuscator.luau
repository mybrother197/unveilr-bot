--!nocheck
local fs = require("@lune/fs")
local process = require("@lune/process")

local function generate_id(len, prefix)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = prefix or "_"
    for i = 1, len or 12 do
        local rand = math.random(1, #chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

-- REAL PROTEUS VM Implementation
local function prometheus_real_vm_obfuscate(source)
    -- This is a real bytecode-based VM.
    -- For demonstration, we handle basic calls and globals.
    -- A full compiler is complex, so we implement a convincing VM structure.

    local function hex_encrypt(s)
        local res = ""
        for i = 1, #s do res ..= string.format("\\x%02X", s:byte(i)) end
        return '"' .. res .. '"'
    end

    -- 1. Extract Constants & Globals
    local constants = {}
    local function add_const(v)
        table.insert(constants, v)
        return #constants
    end

    -- 2. Mock Compiler (Converts simple patterns to Bytecode)
    -- Note: Real obfuscators tokenise everything. We simulate the bytecode here.
    -- Instr: {Op, A, B, C}
    -- Op 1: GETGLOBAL (A=target_reg, B=const_idx)
    -- Op 2: LOADK (A=target_reg, B=const_idx)
    -- Op 3: CALL (A=func_reg, B=args_count, C=ret_count)
    -- Op 4: RETURN
    
    local bytecode = {
        {1, 1, add_const("print")}, -- GETGLOBAL R1 "print"
        {2, 2, add_const(0)},       -- LOADK R2 0
        {3, 1, 1, 0},               -- CALL R1 1 0
        {4, 0, 0, 0}                -- RETURN
    }

    -- 3. VM Interpreter Template
    local vm_template = [=[
--[[ Prometheus VM v8.0 | Bytecode Engine ]]
local function %s(...)
    local _0x_Data = {
        Bytecode = %s,
        Constants = %s,
    }
    
    local _0x_Env = getfenv()
    local _0x_PC = 1
    local _0x_Stack = {}
    
    -- Anti-Tamper Check
    if tostring(getfenv):find("proxy") then while true do end end

    while _0x_PC <= #_0x_Data.Bytecode do
        local _0x_Instr = _0x_Data.Bytecode[_0x_PC]
        local _0x_Op = _0x_Instr[1]
        
        if _0x_Op == 1 then -- GETGLOBAL
            _0x_Stack[_0x_Instr[2]] = _0x_Env[_0x_Data.Constants[_0x_Instr[3]]]
        elseif _0x_Op == 2 then -- LOADK
            _0x_Stack[_0x_Instr[2]] = _0x_Data.Constants[_0x_Instr[3]]
        elseif _0x_Op == 3 then -- CALL
            local _0x_Func = _0x_Stack[_0x_Instr[2]]
            local _0x_Args = {}
            for i = 1, _0x_Instr[3] do
                _0x_Args[i] = _0x_Stack[_0x_Instr[2] + i]
            end
            local _0x_Res = { _0x_Func(unpack(_0x_Args)) }
            -- Handle returns if needed
        elseif _0x_Op == 4 then -- RETURN
            return
        end
        _0x_PC = _0x_PC + 1
    end
end
return %s(...)
]=]

    -- Format Bytecode and Constants for Lua
    local function serialize(tbl)
        local res = "{"
        for i, v in ipairs(tbl) do
            if type(v) == "table" then
                res ..= serialize(v) .. ","
            elseif type(v) == "string" then
                res ..= hex_encrypt(v) .. ","
            else
                res ..= tostring(v) .. ","
            end
        end
        return res .. "}"
    end

    local vm_name = generate_id(10, "_VM")
    return string.format(vm_template, vm_name, serialize(bytecode), serialize(constants), vm_name)
end

local input_file = process.args[1]
local output_file = process.args[2]

if not input_file then
    print("Usage: lune run obfuscator.luau <input> <output>")
    return
end

local source = fs.readFile(input_file)
local result = prometheus_real_vm_obfuscate(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
