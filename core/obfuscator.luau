--!nocheck
--[[
    하하난천0 x 난독화 v27.0 "Sentinel Nexus"
    Refined Metamorphic Ops & Poison Threshold Seeding
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local id = "_"
    for i = 1, len or 18 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_sentinel_nexus(source)
    local chunks = {}
    local step = 8
    for i = 1, #source, step do
        table.insert(chunks, source:sub(i, i + step - 1))
    end

    local node_ids = {}
    for i = 1, #chunks do node_ids[i] = math.random(100000, 999999) end
    
    local shard_payloads = {}
    local base_seed = math.random(50, 255)
    local current_key = base_seed

    for i = 1, #chunks do
        local data = chunks[i]
        local next_node = node_ids[i+1] or -1
        local op_type = math.random(1, 3) -- 1:XOR, 2:ADD, 3:SUB
        
        local enc_bytes = {}
        for j = 1, #data do
            local b = data:byte(j)
            local res = 0
            if op_type == 1 then res = bit32.bxor(b, current_key)
            elseif op_type == 2 then res = (b + current_key) % 256
            elseif op_type == 3 then res = (b - current_key) % 256
            end
            table.insert(enc_bytes, string.format("%02x", bit32.band(res, 255)))
            current_key = bit32.band(current_key + res + j, 255)
        end
        
        local h_data = table.concat(enc_bytes)
        local d_wrap = math.random(1, 2)
        local d_final = (d_wrap == 1) and ("'" .. h_data .. "'") or ("function() return '" .. h_data .. "' end")

        table.insert(shard_payloads, string.format("[%d] = {d=%s, n=%d, o=%d}", node_ids[i], d_final, next_node, op_type))
    end

    local v_vm_name = "Sentinel_" .. generate_id(4)
    
    local template = [[
local function VAR_VM_NAME(...)
    local _ARGS = {...}
    local _Env = getfenv()
    SECURITY_BLOCK
    
    -- Sentinel Seeding: If detected, key cascades into corruption
    local _S = (INITIAL_SEED + (_Detected > 40 and 1 or 0)) % 256
    
    local _NODES = {
        SHARD_DATA
    }
    
    local _ptr = INITIAL_NODE
    local _key = _S
    local _stream = {}
    
    while _ptr ~= -1 do
        local _node = _NODES[_ptr]
        if not _node then break end
        
        local _raw = _node.d
        if type(_raw) == "function" then _raw = _raw() end
        local _op = _node.o
        
        local _buf = {}
        for i = 1, #_raw, 2 do
            local _enc = tonumber(_raw:sub(i, i+1), 16)
            local _dec = 0
            if _op == 1 then _dec = bit32.bxor(_enc, _key)
            elseif _op == 2 then _dec = (_enc - _key) % 256
            elseif _op == 3 then _dec = (_enc + _key) % 256
            end
            
            table.insert(_buf, string.char(bit32.band(_dec, 255)))
            _key = bit32.band(_key + _enc + (math.floor(i/2) + 1), 255)
        end
        
        table.insert(_stream, table.concat(_buf))
        _NODES[_ptr] = nil 
        _ptr = _node.n
    end
    
    local _L_Name = string.char(108,111,97,100,115,116,114,105,110,103)
    local _L = _Env[_L_Name] or _Env.load or load
    
    if _L then
        local _r, _e = _L(table.concat(_stream))
        if _r then
            pcall(function() if setfenv then setfenv(_r, _Env) end end)
            return _r(unpack(_ARGS))
        end
    end
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm_name)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("SHARD_DATA", table.concat(shard_payloads, ",\n        "))
    final = final:gsub("INITIAL_SEED", tostring(base_seed))
    final = final:gsub("INITIAL_NODE", tostring(node_ids[1]))
    
    return "--[[ 하하난천0 x 난독화 v27.0 | Sentinel Nexus Engine ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_sentinel_nexus(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
