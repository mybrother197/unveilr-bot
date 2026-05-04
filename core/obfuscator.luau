--!nocheck
--[[
    하하난천0 x 난독화 v20.0 "Titan Overlord"
    Chunked Data Streaming & Compiler Bypass
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

local function prometheus_titan_overlord(source)
    local bytecode = {}
    for i = 1, #source do
        table.insert(bytecode, string.format("%02x", source:byte(i)))
    end

    -- Chunk the hex data to prevent table/string literal limits
    local hex_data = table.concat(bytecode)
    local chunks = {}
    local chunk_size = 1024
    for i = 1, #hex_data, chunk_size do
        table.insert(chunks, string.format("'%s'", hex_data:sub(i, i + chunk_size - 1)))
    end

    local v_vm_name = "TitanVM_" .. generate_id(5)
    local v_state = generate_id(10)
    local v_pc_table = generate_id(10)
    local v_sandbox = generate_id(10)
    local v_dispatch = generate_id(10)

    local op_xor = math.random(50, 250)
    local op_mod = math.random(10, 100)

    local template = [[
local function VAR_VM_NAME(...)
    local _ARGS = {...}
    local _Env = getfenv()
    SECURITY_BLOCK
    
    local VAR_STATE = {}
    local _raw_hex = table.concat({BYTECODE_CHUNKS})
    for i = 1, #_raw_hex, 2 do
        table.insert(VAR_STATE, tonumber(_raw_hex:sub(i, i+1), 16))
    end

    local VAR_PC_TABLE = {PC = 1, Running = true, Buffer = {}}
    
    local VAR_SANDBOX = setmetatable({ _G = _Env._G or _G }, {
        __index = function(_, k) return _Env[k] end,
        __newindex = function(_, k, v) _Env[k] = v end,
        __metatable = "Hypervisor Protected"
    })

    local function VAR_DISPATCH()
        while VAR_PC_TABLE.Running and VAR_PC_TABLE.PC <= #VAR_STATE do
            local _raw = VAR_STATE[VAR_PC_TABLE.PC]
            local _inst = bit32.bxor(_raw, (VAR_PC_TABLE.PC * OP_MOD + OP_XOR) % 256)
            table.insert(VAR_PC_TABLE.Buffer, string.char(bit32.band(_inst, 255)))
            
            VAR_PC_TABLE.PC = VAR_PC_TABLE.PC + 1
            if VAR_PC_TABLE.PC % 4000 == 0 then 
                local _w = (task and task.wait) or wait
                if _w then _w() end
            end
        end
        
        local _src = table.concat(VAR_PC_TABLE.Buffer)
        local _kernel = _Env[string.char(108,111,97,100,115,116,114,105,110,103)] or _Env.loadstring or _Env.load or loadstring or load
        
        if _kernel then
            local _success, _runtime = pcall(function()
                return _kernel(_src)
            end)
            
            if _success and _runtime then
                pcall(setfenv, _runtime, VAR_SANDBOX)
                _runtime(unpack(_ARGS))
            end
        end
    end

    VAR_DISPATCH()
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm_name)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("VAR_STATE", v_state)
    final = final:gsub("BYTECODE_CHUNKS", table.concat(chunks, ","))
    final = final:gsub("VAR_PC_TABLE", v_pc_table)
    final = final:gsub("VAR_SANDBOX", v_sandbox)
    final = final:gsub("OP_MOD", tostring(op_mod))
    final = final:gsub("OP_XOR", tostring(op_xor))
    
    return "--[[ 하하난천0 x 난독화 v20.0 | Titan Overlord VM ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_titan_overlord(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
