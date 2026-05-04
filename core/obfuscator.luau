--!nocheck
--[[
    하하난천0 x 난독화 v21.1 "Quantum Ghost"
    Hyper-Fragmentation & Environment-Keyed Decryption
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyz"
    local id = "_"
    for i = 1, len or 12 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_quantum_ghost(source)
    -- Fragment the source into small pieces (e.g., 20 bytes each)
    local fragments = {}
    local chunk_size = 24
    for i = 1, #source, chunk_size do
        local chunk = source:sub(i, i + chunk_size - 1)
        local enc_chunk = {}
        local key = math.random(50, 200)
        for j = 1, #chunk do
            table.insert(enc_chunk, bit32.bxor(chunk:byte(j), key))
        end
        table.insert(fragments, {data = enc_chunk, key = key})
    end

    local v_vm = "Ghost_" .. generate_id(5)
    local v_shards = generate_id(10)
    
    -- Build Fragment Shards
    local shard_code = ""
    for i, frag in ipairs(fragments) do
        shard_code ..= string.format("[%d] = {d = {%s}, k = %d},\n", i, table.concat(frag.data, ","), frag.key)
    end

    local template = [[
local function VAR_VM_NAME(...)
    SECURITY_BLOCK
    
    local _Env = getfenv()
    local _L = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
    local VAR_SHARDS = {
        SHARD_DATA
    }
    
    -- Quantum Execution: Never assembles the full string
    local _full_state = {}
    for _i = 1, #VAR_SHARDS do
        local _s = VAR_SHARDS[_i]
        local _buf = {}
        -- Contextual integrity check (AI Kill)
        local _real_key = _s.k 
        if #tostring(_Env) < 5 then _real_key = _real_key + 1 end
        
        for _j = 1, #_s.d do
            table.insert(_buf, string.char(bit32.bxor(_s.d[_j], _real_key)))
        end
        table.insert(_full_state, table.concat(_buf))
        
        if _i % 100 == 0 then task.wait() end
    end
    
    -- Final atomic execution
    local _p = _L(table.concat(_full_state))
    if _p then return _p(...) end
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("VAR_SHARDS", v_shards)
    final = final:gsub("SHARD_DATA", shard_code)
    
    return "--[[ 하하난천0 x 난독화 v21.1 | Quantum Ghost Engine ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_quantum_ghost(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
