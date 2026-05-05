--!nocheck
--[[
    하하난천0 x 난독화 v26.0 "Void Nexus"
    Polymorphic Operation Generator & CFF Loadstring Evasion
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyz"
    local id = "_"
    for i = 1, len or 16 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_void_nexus(source)
    local seed = math.random(50, 200)
    
    local decoy1 = "print('[Void Nexus] Extraneous Analysis Intercepted!'); for _=1, 100 do math.random() end"
    local decoy2 = "local _x=0; for _=1, 50 do _x=_x+1 end; return _x"
    
    local function make_chunks(str, kind)
        local c = {}
        local c_size = 64
        for i=1, #str, c_size do
            table.insert(c, { kind=kind, data=str:sub(i, i+c_size-1) })
        end
        return c
    end
    
    local unified = {}
    for _, v in ipairs(make_chunks(source, 0)) do table.insert(unified, v) end
    for _, v in ipairs(make_chunks(decoy1, 1)) do table.insert(unified, v) end
    for _, v in ipairs(make_chunks(decoy2, 2)) do table.insert(unified, v) end
    
    -- Shuffle unified array
    for i = #unified, 2, -1 do
        local j = math.random(i)
        unified[i], unified[j] = unified[j], unified[i]
    end
    
    local states = {}
    for i=1, #unified do
        states[i] = math.random(10000, 99999) + i
    end
    
    local shard_strings = {}
    local curr_key = seed
    
    for i = 1, #unified do
        local chunk = unified[i]
        local state_id = states[i]
        local next_state = states[i+1] or -1
        
        local op_id = math.random(1, 4)
        local hex_buf = {}
        
        for j=1, #chunk.data do
            local b = chunk.data:byte(j)
            local enc = 0
            if op_id == 1 then enc = bit32.bxor(b, curr_key)
            elseif op_id == 2 then enc = bit32.band(bit32.bxor(b, bit32.bnot(curr_key)), 255)
            elseif op_id == 3 then enc = (b + curr_key) % 256
            elseif op_id == 4 then enc = (b - curr_key) % 256
            end
            
            if enc < 0 then enc = enc + 256 end
            table.insert(hex_buf, string.format("%02x", enc))
            
            curr_key = bit32.band(curr_key + b + j, 255)
        end
        
        local hex_str = table.concat(hex_buf)
        local poly_type = math.random(1, 3)
        local d_str = ""
        if poly_type == 1 then d_str = string.format("'%s'", hex_str)
        elseif poly_type == 2 then d_str = string.format("function() return '%s' end", hex_str)
        elseif poly_type == 3 then d_str = string.format("{'%s'}", hex_str)
        end
        
        table.insert(shard_strings, string.format("[%d] = {d=%s, n=%d, t=%d, op=%d}", state_id, d_str, next_state, chunk.kind, op_id))
    end
    
    local v_vm = "Nexus_" .. generate_id(5)
    
    local template = [[
local function VAR_VM_NAME(...)
    local _ARGS = {...}
    local _Env = getfenv()
    SECURITY_BLOCK
    
    local _SHARDS = {
        SHARD_DATA
    }
    
    local _env_k = (#tostring(math.sin) == 8) and 0 or 1
    local _curr_key = INITIAL_SEED + _env_k
    local _state = INITIAL_STATE
    local _buffers = { {}, {}, {} }
    
    -- Control Flow Flattening (CFF) state machine
    while _state ~= -1 do
        local _s = _SHARDS[_state]
        if type(_s) == "function" then _s = _s() end -- Handle Self-Modified states
        if not _s then break end
        
        -- Polymorphic Data Retrieval
        local _raw_d = _s.d
        if type(_raw_d) == "function" then _raw_d = _raw_d() end
        if type(_raw_d) == "table" then _raw_d = _raw_d[1] end
        
        local _op = _s.op
        local _buf = {}
        
        for _j = 1, #_raw_d, 2 do
            local _enc = tonumber(_raw_d:sub(_j, _j+1), 16)
            local _dec = 0
            
            -- Polymorphic Operations
            if _op == 1 then _dec = bit32.bxor(_enc, _curr_key)
            elseif _op == 2 then _dec = bit32.band(bit32.bxor(_enc, bit32.bnot(_curr_key)), 255)
            elseif _op == 3 then _dec = (_enc - _curr_key) % 256
            elseif _op == 4 then _dec = (_enc + _curr_key) % 256
            end
            
            table.insert(_buf, string.char(bit32.band(_dec, 255)))
            
            local _bidx = math.floor(_j/2) + 1
            _curr_key = bit32.band(_curr_key + _dec + _bidx, 255)
        end
        
        -- Environmental Buffer Targeting
        local _tgt = (_s.t + _env_k) % 3 + 1
        table.insert(_buffers[_tgt], table.concat(_buf))
        
        -- Self-Modifying Code: Erase memory footprint dynamically
        _SHARDS[_state] = function() return nil end
        
        _state = _s.n
    end
    
    local _REAL_TARGET = (0 + _env_k) % 3 + 1
    local _final_code = table.concat(_buffers[_REAL_TARGET])
    
    -- Loadstring Evasion (Wrapper & Metatable)
    local _L_Name = string.char(108,111,97,100,115,116,114,105,110,103)
    local _L = _Env[_L_Name] or _Env.load or load
    
    if _L then
        local _wrapper = function()
            local _f, _e = _L(_final_code)
            if _f then 
                pcall(function() if setfenv then setfenv(_f, _Env) end end)
                return _f(unpack(_ARGS)) 
            end
        end
        return _wrapper()
    end
end
VAR_VM_NAME(...)
]]
    
    local final = template:gsub("VAR_VM_NAME", v_vm)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("SHARD_DATA", table.concat(shard_strings, ",\n        "))
    final = final:gsub("INITIAL_SEED", tostring(seed))
    final = final:gsub("INITIAL_STATE", tostring(states[1]))
    
    return "--[[ 하하난천0 x 난독화 v26.0 | Void Nexus Engine ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_void_nexus(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
