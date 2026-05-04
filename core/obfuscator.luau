--!nocheck
--[[
    하하난천0 x 난독화 v19.1 "Titan VM Hypervisor"
    Stabilized Template Engine & Optimized Dispatcher
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local id = "_" .. chars:sub(math.random(#chars), math.random(#chars))
    for i = 1, len or 15 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_titan_vm(source)
    local instructions = {}
    for i = 1, #source do
        table.insert(instructions, source:byte(i))
    end

    local v_vm_name = "TitanVM_" .. generate_id(5)
    local v_state = generate_id(10)
    local v_pc_table = generate_id(10)
    local v_pc_val = generate_id(5)
    local v_sandbox = generate_id(10)
    local v_dispatch = generate_id(10)

    local op_xor = math.random(50, 250)
    local op_mod = math.random(10, 100)

    -- Build with direct variable injection to prevent format errors
    local template = [[
local function VAR_VM_NAME(...)
    SECURITY_BLOCK
    
    local VAR_STATE = {BYTECODE_DATA}
    local VAR_PC_TABLE = {PC = 1, Running = true, Buffer = {}}
    local VAR_PARENT_ENV = getfenv()
    
    local VAR_SANDBOX = setmetatable({}, {
        __index = function(_, k) return VAR_PARENT_ENV[k] end,
        __newindex = function(_, k, v) VAR_PARENT_ENV[k] = v end
    })

    local function VAR_DISPATCH()
        while VAR_PC_TABLE.Running and VAR_PC_TABLE.PC <= #VAR_STATE do
            local _raw = VAR_STATE[VAR_PC_TABLE.PC]
            local _inst = bit32.bxor(_raw, (VAR_PC_TABLE.PC * OP_MOD + OP_XOR) % 256)
            table.insert(VAR_PC_TABLE.Buffer, string.char(bit32.band(_inst, 255)))
            
            VAR_PC_TABLE.PC = VAR_PC_TABLE.PC + 1
            if VAR_PC_TABLE.PC % 3000 == 0 then task.wait() end
        end
        
        local _kernel = (VAR_SANDBOX[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
        local _success, _runtime = pcall(function()
            return _kernel(table.concat(VAR_PC_TABLE.Buffer))
        end)
        
        if _success and _runtime then
            setfenv(_runtime, VAR_SANDBOX)
            _runtime(...)
        end
    end

    pcall(VAR_DISPATCH)
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm_name)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("VAR_STATE", v_state)
    final = final:gsub("BYTECODE_DATA", table.concat(instructions, ","))
    final = final:gsub("VAR_PC_TABLE", v_pc_table)
    final = final:gsub("VAR_PARENT_ENV", generate_id(8))
    final = final:gsub("VAR_SANDBOX", v_sandbox)
    final = final:gsub("VAR_DISPATCH", v_dispatch)
    final = final:gsub("OP_MOD", tostring(op_mod))
    final = final:gsub("OP_XOR", tostring(op_xor))
    
    return "--[[ 하하난천0 x 난독화 v19.1 | Titan VM Hypervisor ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_titan_vm(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
