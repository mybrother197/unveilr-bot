--!nocheck
--[[
    하하난천0 x 난독화 v22.0 "Singularity Hypervisor"
    Chained Shard Dependency & Environmental Keying
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

local function prometheus_singularity_hypervisor(source)
    -- Fragment the source into rolling shards
    local shards = {}
    local chunk_size = 16
    local rolling_seed = math.random(50, 255)
    local curr_key = rolling_seed
    
    for i = 1, #source, chunk_size do
        local chunk = source:sub(i, i + chunk_size - 1)
        local enc_data = {}
        for j = 1, #chunk do
            local b = chunk:byte(j)
            local enc = bit32.bxor(b, curr_key)
            table.insert(enc_data, enc)
            -- Key mutation: The key for next byte depends on current encrypted value
            curr_key = bit32.band(bit32.bxor(curr_key, enc) + j, 255)
        end
        table.insert(shards, enc_data)
    end

    local v_vm = "Singularity_" .. generate_id(5)
    local v_state = generate_id(10)
    
    -- Build the Chained Dispatcher
    local shard_code = ""
    for i, data in ipairs(shards) do
        shard_code ..= string.format("[%d] = {%s},\n", i, table.concat(data, ","))
    end

    local template = [[
local function VAR_VM_NAME(...)
    SECURITY_BLOCK
    
    local _Env = getfenv()
    local _L = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
    
    local VAR_SHARDS = {
        SHARD_DATA
    }
    
    -- Environmental Fingerprint (Implicit Key)
    -- This makes the initial key unpredictable for AI/Emulators
    local _base_key = INITIAL_SEED
    if #tostring(_L) < 5 then _base_key = _base_key + 1 end
    
    local _full_source = {}
    local _curr = _base_key
    
    for _i = 1, #VAR_SHARDS do
        local _s = VAR_SHARDS[_i]
        local _buf = {}
        for _j = 1, #_s do
            local _raw = _s[_j]
            local _dec = bit32.bxor(_raw, _curr)
            table.insert(_buf, string.char(bit32.band(_dec, 255)))
            -- Chained Re-keying: AI must solve previous byte to get next key
            _curr = bit32.bxor(_curr, _raw) 
            _curr = bit32.band(_curr + _j, 255)
        end
        table.insert(_full_source, table.concat(_buf))
        
        if _i % 200 == 0 then (task and task.wait or wait)() end
    end
    
    local _p = _L(table.concat(_full_source))
    if _p then return _p(...) end
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("SHARD_DATA", shard_code)
    final = final:gsub("INITIAL_SEED", tostring(rolling_seed))
    final = final:gsub("VAR_SHARDS", generate_id(8))
    
    return "--[[ 하하난천0 x 난독화 v22.0 | Singularity Hypervisor ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_singularity_hypervisor(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
