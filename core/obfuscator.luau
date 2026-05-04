--!nocheck
--[[
    하하난천0 x 난독화 v15.2 "Stable Titan"
    Fixes syntax corruption and executor limits
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
    -- 1. Chained Encryption
    local function chained_encrypt(src)
        local key = math.random(15, 250)
        local out = {}
        local prev = key
        for i = 1, #src do
            local b = src:byte(i)
            local enc = bit32.bxor(b, prev)
            out[i] = enc
            prev = bit32.bxor(enc, i % 256)
        end
        return out, key
    end

    local data, start_key = chained_encrypt(source)
    
    -- 2. Data Chunking (Preventing ultra-long strings)
    local chunks = {}
    local chunk_size = 128 -- Smaller, safer chunks
    local hex_all = ""
    for _, b in ipairs(data) do hex_all ..= string.format("%02x", b) end
    
    for i = 1, #hex_all, chunk_size do
        table.insert(chunks, '"' .. hex_all:sub(i, i + chunk_size - 1) .. '"')
    end
    
    -- 3. Stable Assembly
    local v_key = generate_id(10)
    local v_data = generate_id(12)
    local v_res = generate_id(10)
    local v_bt = generate_id(10)
    
    local final = "--[[ 하하난천0 x 난독화 v15.2 | Stable Architecture ]]\n"
    final ..= "(function(...)\n"
    
    -- Intense Security Block (1200+ Lines)
    final ..= Security.GetAntiTamper() .. "\n"
    
    -- Decoder Logic (Using safe multi-line structure)
    local decoder = string.format([[
local %s = %d
local %s = table.concat({%s})
local %s = {}
for i = 1, #%s / 2 do
    local b = tonumber(%s:sub(i*2-1, i*2), 16)
    local rb = bit32.bxor(b, %s)
    table.insert(%s, string.char(rb))
    %s = bit32.bxor(b, i %% 256)
end
local _f = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
_f(table.concat(%s))()
]], v_key, start_key, v_bt, table.concat(chunks, ","), v_res, v_bt, v_bt, v_key, v_res, v_key, v_res)

    final ..= decoder .. "\n"
    final ..= "end)(...)\n"
    
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
