--!nocheck
--[[
    하하난천0 x 난독화 v15.2 "Stable Titan" (Rollback)
    Chained XOR encryption with 1200+ line security wall.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local id = "_"
    for i = 1, len or 12 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_stable_titan(source)
    local seed = math.random(50, 255)
    local data = {}
    local curr = seed
    for i = 1, #source do
        local b = source:byte(i)
        local enc = bit32.bxor(b, curr)
        data[i] = string.format("%02x", enc)
        curr = bit32.bxor(enc, (seed + i) % 256)
    end

    local hex_all = table.concat(data)
    local chunks = {}
    for i = 1, #hex_all, 128 do
        table.insert(chunks, string.format("'%s'", hex_all:sub(i, i + 127)))
    end

    local v_data = generate_id(10)
    local v_res = generate_id(10)
    local v_key = generate_id(10)
    
    local final = "--[[ 하하난천0 x 난독화 v15.2 | Stable Architecture ]]\n"
    final ..= "local function _Start(...)\n"
    
    -- Integration of 1200+ line Security Wall
    final ..= Security.GetAntiTamper() .. "\n"
    
    final ..= string.format("local %s = %d + (_Detected * 0)\n", v_key, seed)
    final ..= string.format("local %s = table.concat({%s})\n", v_data, table.concat(chunks, ","))
    final ..= string.format("local %s = {}\n", v_res)
    
    final ..= string.format([[
local _c = %s
for i = 1, #%s, 2 do
    local b = tonumber(%s:sub(i, i+1), 16)
    local rb = bit32.bxor(b, _c)
    table.insert(%s, string.char(rb))
    _c = bit32.bxor(b, (%s + (i+1)/2) %% 256)
end
local _f = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
_f(table.concat(%s))()
]], v_key, v_data, v_data, v_res, v_key, v_res)

    final ..= "end\n_Start(...)\n"
    
    return final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_stable_titan(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
