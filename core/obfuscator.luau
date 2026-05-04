--!nocheck
--[[
    하하난천0 x 난독화 v15.0 "Acheron VM"
    AI-Immune Fragmented Logic & Token Bombing
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "l1IioO0" -- Characters hard for both humans and AI to distinguish
    local id = "_"
    for i = 1, len or 16 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

-- Generate massive mathematical junk to drown the AI's context window
local function generate_massive_junk(amount)
    local res = ""
    for i = 1, amount do
        local v1 = generate_id(8)
        local v2 = generate_id(8)
        res ..= string.format("local %s = math.sin(math.pi / %d) * math.cos(%d);\n", v1, math.random(1,100), math.random(1,100))
        res ..= string.format("local %s = (%s + %d) / %d;\n", v2, v1, math.random(10,100), math.random(1,5))
        if i % 10 == 0 then res ..= string.format("if %s > %s then %s = %s end;\n", v1, v2, v2, v1) end
    end
    return res
end

local function prometheus_acheron_vm(source)
    -- 1. Chained Encryption with Dynamic Slicing
    local function chained_encrypt(src)
        local key = math.random(20, 240)
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
    local hex_parts = {}
    for _, b in ipairs(data) do table.insert(hex_parts, string.format("%02x", b)) end

    -- 2. Fragmented Decoder Logic
    -- Instead of a loop, we use recursive dispatch with many layers
    local v_key = generate_id(10)
    local v_data = generate_id(12)
    local v_dec = generate_id(12)
    local v_final = generate_id(12)
    
    local heavy_decoder = [[
local function DISP_ID(idx, p_key, acc)
    if idx > #DATA_ID / 2 then return acc end
    local b = tonumber(DATA_ID:sub(idx*2-1, idx*2), 16)
    local real = bit32.bxor(b, p_key)
    local next_key = bit32.bxor(b, idx % 256)
    table.insert(acc, string.char(real))
    
    -- Recursive splitting to bypass simple loop analysis
    if idx % 50 == 0 then
        task.wait() -- Anti-unveilr and performance break
    end
    return DISP_ID(idx + 1, next_key, acc)
end
]]
    
    -- Since recursion has stack limits, we use a trampoline-like structure
    local fragment_template = [[
local __D = "DATA_HEX"
local __K = START_KEY
local __R = {}
local __I = 1
while __I <= #__D / 2 do
    local __B = tonumber(__D:sub(__I*2-1, __I*2), 16)
    __R[__I] = string.char(bit32.bxor(__B, __K))
    __K = bit32.bxor(__B, __I % 256)
    __I = __I + 1
    -- Junk insertion inside the loop
    if __I % 13 == 0 then local _j = math.sqrt(__I) end
end
local _f = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
_f(table.concat(__R))()
]]

    -- 3. Assembly
    local watermark = "--[[ 하하난천0 x 난독화 v15.0 | AI-IMMUNE ]]\n"
    local final = watermark .. "(function(...)\n"
    
    -- Security First
    final ..= Security.GetAntiTamper() .. "\n"
    
    -- TOKEN BOMB: Drown the AI in 500 lines of complex junk
    final ..= generate_massive_junk(100) .. "\n"
    
    -- Main Logic (Scattered)
    local decoder = fragment_template:gsub("__D", v_data):gsub("DATA_HEX", table.concat(hex_parts)):gsub("__K", v_key):gsub("START_KEY", tostring(start_key)):gsub("__B", generate_id(8)):gsub("__R", generate_id(8)):gsub("__I", generate_id(8))
    
    final ..= "local " .. v_key .. " = " .. tostring(start_key) .. ";\n"
    final ..= decoder:gsub("\n", " ") .. "\n"
    
    -- More Junk
    final ..= generate_massive_junk(50) .. "\n"
    
    final ..= "end)(...)\n"
    
    return final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_acheron_vm(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
