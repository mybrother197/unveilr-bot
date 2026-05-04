--!nocheck
--[[
    하하난천0 x 난독화 v19.0 "Titan VM Hypervisor"
    Full Instruction Virtualization & Isolated Sandbox
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
    -- Virtualized Instructions Table
    local instructions = {}
    for i = 1, #source do
        table.insert(instructions, source:byte(i))
    end

    local v_vm_name = "TitanVM_" .. generate_id(5)
    local v_state = generate_id(10)
    local v_dispatch = generate_id(10)
    local v_pc = generate_id(5)
    local v_sandbox = generate_id(10)

    -- Randomize Opcode Mapping
    local op_xor = math.random(50, 250)
    local op_mod = math.random(10, 100)

    local final = "--[[ 하하난천0 x 난독화 v19.0 | Titan VM Hypervisor ]]\n"
    final ..= "local function " .. v_vm_name .. "(...)\n"
    final ..= Security.GetAntiTamper() .. "\n"
    
    -- VM Internal State
    final ..= string.format([[
    local %s = {%s}
    local %s = {PC = 1, Stack = {}, Running = true, Buffer = {}}
    local %s = getfenv()
    
    -- Isolated Sandbox Proxy
    local %s = setmetatable({}, {
        __index = function(_, k) return %s[k] end,
        __newindex = function(_, k, v) %s[k] = v end
    })

    -- The Hypervisor Execution Loop
    local function %s()
        while %s.Running and %s.PC <= #%s do
            local _raw = %s[%s.PC]
            -- Logic Decryption (Instruction level)
            local _inst = bit32.bxor(_raw, (%s.PC * %d + %d) %% 256)
            table.insert(%s.Buffer, string.char(bit32.band(_inst, 255)))
            
            %s.PC = %s.PC + 1
            if %s.PC %% 2000 == 0 then task.wait() end
        end
        
        -- Virtual Context Execution
        local _kernel = (%s[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
        local _success, _runtime = pcall(function()
            return _kernel(table.concat(%s.Buffer))
        end)
        
        if _success and _runtime then
            setfenv(_runtime, %s)
            _runtime(...)
        end
    end

    pcall(%s)
end
]], v_state, table.concat(instructions, ","), v_pc, v_sandbox, v_sandbox, v_sandbox, v_sandbox, v_dispatch, v_pc, v_pc, v_state, v_pc, v_pc, op_mod, op_xor, v_pc, v_pc, v_pc, v_pc, v_sandbox, v_pc, v_sandbox, v_dispatch)

    final ..= v_vm_name .. "(...)\n"
    
    return final
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
