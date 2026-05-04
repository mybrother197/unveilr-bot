--!nocheck
--[[
    하하난천0 x 난독화 v25.0 "Quantum Entanglement"
    Distributed Multi-variable Math & Polymorphic Ops
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyz"
    local id = "_"
    for i = 1, len or 14 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_quantum_entanglement(source)
    -- Fragment source into Atomic Shards
    local fragments = {}
    local slice_size = 8
    for i = 1, #source, slice_size do
        table.insert(fragments, source:sub(i, i + slice_size - 1))
    end

    local shard_data = ""
    local seed = math.random(100, 500)
    
    for i, frag in ipairs(fragments) do
        local enc_data = {}
        local op_type = math.random(1, 3) -- Polymorphic types
        for j = 1, #frag do
            local b = frag:byte(j)
            local k1 = math.random(1, 255)
            local k2 = math.random(1, 255)
            
            -- Distributed Logic: Split 'b' into multiple encrypted tokens
            local t1 = bit32.bxor(b, k1)
            local t2 = bit32.bxor(k1, k2)
            -- We store t1, t2, and k2. To get b: bxor(t1, bxor(t2, k2))
            table.insert(enc_data, {t1, t2, k2})
        end
        
        local json_parts = {}
        for _, p in ipairs(enc_data) do
            table.insert(json_parts, string.format("{%d,%d,%d}", p[1], p[2], p[3]))
        end
        shard_data ..= string.format("[%d] = {%s},\n", i, table.concat(json_parts, ","))
    end

    local v_vm = "Entanglement_" .. generate_id(5)
    
    local template = [[
local function VAR_VM_NAME(...)
    SECURITY_BLOCK
    
    local _Env = getfenv()
    local _L = load or loadstring
    
    -- Distributed Shard Storage
    local VAR_SHARDS = {
        SHARD_DATA
    }
    
    local _final_code = {}
    
    -- High-Confusion Distributed Multi-variable Loop
    for _i = 1, #VAR_SHARDS do
        local _s = VAR_SHARDS[_i]
        local _chunk = {}
        
        for _j = 1, #_s do
            local _p = _s[_j]
            -- Spread calculation across multiple temporal variables
            local _tmp1 = _p[1]
            local _tmp2 = _p[2]
            local _tmp3 = _p[3]
            
            -- AI/Debugger will see these meaningless operations
            local _dist1 = bit32.bxor(_tmp2, _tmp3)
            local _res = bit32.bxor(_tmp1, _dist1)
            
            table.insert(_chunk, string.char(bit32.band(_res, 255)))
            
            -- Anti-Tracing: Add redundant math that changes nothing
            local _junk = bit32.bxor(_tmp1, _tmp2) + _tmp3
        end
        table.insert(_final_code, table.concat(_chunk))
        if _i % 200 == 0 then (task and task.wait or wait)() end
    end
    
    local _p = _L(table.concat(_final_code))
    if _p then return _p(...) end
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("SHARD_DATA", shard_data)
    final = final:gsub("VAR_SHARDS", generate_id(8))
    
    return "--[[ 하하난천0 x 난독화 v25.0 | Quantum Entanglement VM ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_quantum_entanglement(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
