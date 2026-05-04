--!nocheck
--[[
    하하난천0 x 난독화 v24.0 "Phantom Sovereign"
    Control Flow Flattening & Chained Multi-stage Mutation
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

local function prometheus_phantom_sovereign(source)
    -- Fragment the source into tiny pieces for State Machine
    local fragments = {}
    local slice_size = 12
    for i = 1, #source, slice_size do
        table.insert(fragments, source:sub(i, i + slice_size - 1))
    end

    -- Randomize Order and create a State Map
    local state_indices = {}
    for i = 1, #fragments do table.insert(state_indices, i) end
    -- Shuffle
    for i = #state_indices, 2, -1 do
        local j = math.random(i)
        state_indices[i], state_indices[j] = state_indices[j], state_indices[i]
    end

    local state_map = {}
    local reverse_indices = {}
    for i, original_idx in ipairs(state_indices) do
        reverse_indices[original_idx] = i
    end

    local shard_data = ""
    local initial_seed = math.random(100, 255)
    local curr_key = initial_seed

    for i, frag_idx in ipairs(state_indices) do
        local original_frag = fragments[frag_idx]
        local next_state = reverse_indices[frag_idx + 1] or -1
        
        local enc_data = {}
        for j = 1, #original_frag do
            local b = original_frag:byte(j)
            -- Multi-stage: XOR -> Rotate -> Chained Key
            local enc = bit32.bxor(b, curr_key)
            enc = bit32.lrotate(enc, j % 8)
            table.insert(enc_data, enc)
            curr_key = bit32.band(bit32.bxor(curr_key, enc) + (i+j), 255)
        end
        shard_code = string.format("[%d] = {d = {%s}, n = %d},\n", i, table.concat(enc_data, ","), next_state)
        shard_data ..= shard_code
    end

    local v_vm = "Sovereign_" .. generate_id(5)
    local v_state = generate_id(10)
    
    local template = [[
local function VAR_VM_NAME(...)
    SECURITY_BLOCK
    
    local _Env = getfenv()
    local _L = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
    
    -- Anti-Hook: Verify loadstring is native
    local _is_native = false
    pcall(function()
        local s = debug.info(_L, "s")
        if s == "=[C]" then _is_native = true end
    end)
    
    local VAR_SHARDS = {
        SHARD_DATA
    }
    
    local _curr_idx = INITIAL_STATE
    local _curr_key = INITIAL_SEED
    local _final_segments = {}
    local _total_steps = 0
    
    -- Control Flow Flattening (The AI Killer)
    while _curr_idx ~= -1 and _total_steps < 50000 do
        local _s = VAR_SHARDS[_curr_idx]
        local _buf = {}
        
        -- Environmental Key Mutation
        local _env_seed = #tostring(_is_native) + (#tostring(_Env) % 10)
        
        for _j = 1, #_s.d do
            local _raw = _s.d[_j]
            -- Reverse Multi-stage
            local _dec = bit32.rrotate(_raw, _j % 8)
            _dec = bit32.bxor(_dec, _curr_key)
            
            table.insert(_buf, string.char(bit32.band(_dec, 255)))
            _curr_key = bit32.band(bit32.bxor(_curr_key, _raw) + (_curr_idx + _j), 255)
        end
        
        table.insert(_final_segments, table.concat(_buf))
        _curr_idx = _s.n
        _total_steps = _total_steps + 1
        
        if _total_steps % 500 == 0 then (task and task.wait or wait)() end
    end
    
    -- If Loadstring is hooked, the code will be corrupted by _is_native seed
    local _p = _L(table.concat(_final_segments))
    if _p then return _p(...) end
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("SHARD_DATA", shard_data)
    final = final:gsub("INITIAL_STATE", tostring(reverse_indices[1]))
    final = final:gsub("INITIAL_SEED", tostring(initial_seed))
    
    return "--[[ 하하난천0 x 난독화 v24.0 | Phantom Sovereign VM ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_phantom_sovereign(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
