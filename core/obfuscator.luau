--!nocheck
--[[
    하하난천0 x 난독화 v20.2 "Hybrid Titan"
    15.2 Reliability + 20.1 Scale (Roblox Optimized)
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

local function prometheus_hybrid_titan(source)
    local seed = math.random(50, 255)
    local bytecode_hex = {}
    local curr = seed
    for i = 1, #source do
        local b = source:byte(i)
        local enc = bit32.bxor(b, curr)
        table.insert(bytecode_hex, string.format("%02x", enc))
        curr = bit32.bxor(enc, (seed + i) % 256)
    end

    local hex_data = table.concat(bytecode_hex)
    local chunks = {}
    local chunk_size = 512
    for i = 1, #hex_data, chunk_size do
        table.insert(chunks, string.format("'%s'", hex_data:sub(i, i + chunk_size - 1)))
    end

    local v_vm_name = "TitanVM_" .. generate_id(5)
    local v_data = generate_id(10)
    local v_res = generate_id(10)
    local v_key = generate_id(10)

    local template = [[
local function VAR_VM_NAME(...)
    SECURITY_BLOCK
    
    local VAR_KEY = SEED_VAL
    local VAR_DATA = table.concat({BYTECODE_CHUNKS})
    local VAR_RES = {}
    
    local _c = VAR_KEY
    for i = 1, #VAR_DATA, 2 do
        local b = tonumber(VAR_DATA:sub(i, i+1), 16)
        local rb = bit32.bxor(b, _c)
        table.insert(VAR_RES, string.char(bit32.band(rb, 255)))
        _c = bit32.bxor(b, (VAR_KEY + (i+1)/2) % 256)
        
        if i % 10000 == 0 then 
            local _w = (task and task.wait) or wait
            if _w then _w() end
        end
    end
    
    local _f = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
    if _f then
        _f(table.concat(VAR_RES))(...)
    end
end
VAR_VM_NAME(...)
]]

    local final = template:gsub("VAR_VM_NAME", v_vm_name)
    final = final:gsub("SECURITY_BLOCK", Security.GetAntiTamper())
    final = final:gsub("VAR_KEY", v_key)
    final = final:gsub("SEED_VAL", tostring(seed))
    final = final:gsub("VAR_DATA", v_data)
    final = final:gsub("BYTECODE_CHUNKS", table.concat(chunks, ","))
    final = final:gsub("VAR_RES", v_res)
    
    return "--[[ 하하난천0 x 난독화 v20.2 | Hybrid Titan Engine ]]\n" .. final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_hybrid_titan(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
