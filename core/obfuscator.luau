--!nocheck
--[[
    Prometheus X v11.1 "Infinite Trap"
    Final fix for assembly syntax errors.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local id = ""
    for i = 1, len or 14 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_infinite_trap(source)
    -- 1. Brutal Infinite Loop & Memory Bomb
    local trap = [[
local _0x_Env = getfenv()
local _0x_T = tostring
local _0x_Trap = function()
    local _0x_Mem = {}
    local function _0x_Infinite()
        for i = 1, 100000 do table.insert(_0x_Mem, {i}) end 
        return _0x_Infinite()
    end
    while true do _0x_Infinite() end
end

local _0x_is_fake = false
pcall(function()
    if _0x_Env.P == "getfenv()" then _0x_is_fake = true end
    if not _0x_T(getfenv):find("function:") then _0x_is_fake = true end
    if getmetatable(_0x_Env) then _0x_is_fake = true end
end)

if _0x_is_fake then
    _0x_Trap()
end
]]

    -- 2. Scramble logic
    local function encrypt(src)
        local key = math.random(11, 255)
        local out = {}
        for i = 1, #src do out[i] = bit32.bxor(src:byte(i), key) end
        return out, key
    end

    local data, key = encrypt(source)
    local hex_data = ""
    for _, b in ipairs(data) do hex_data ..= string.format("%02x", b) end

    -- 3. Obfuscated Decoder
    local v_ld = generate_id(10)
    local v_bt = generate_id(10)
    local v_xk = generate_id(10)
    
    local decoder_template = [[
local V_LD = getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]
local V_BT = "HEX_DATA"
local V_XK = KEY_VAL
local _out = {}
for i = 1, #V_BT, 2 do
    local b = tonumber(V_BT:sub(i, i+1), 16)
    table.insert(_out, string.char(bit32.bxor(b, V_XK)))
end
V_LD(table.concat(_out))()
]]
    
    local function safe_replace(str, p, r)
        return (str:gsub(p, function() return tostring(r) end))
    end

    local decoder = decoder_template
    decoder = safe_replace(decoder, "V_LD", v_ld)
    decoder = safe_replace(decoder, "V_BT", v_bt)
    decoder = safe_replace(decoder, "HEX_DATA", hex_data)
    decoder = safe_replace(decoder, "V_XK", v_xk)
    decoder = safe_replace(decoder, "KEY_VAL", key)

    -- Final Product (Using simple concat for safety)
    local final = "--[[ Prometheus X v11.1 | UNVEILR-KILLER ]]\n"
    final ..= trap .. ";\n"
    final ..= "(function()\n"
    final ..= (decoder:gsub("\n", " ")) .. "\n"
    final ..= "end)()"

    return final
end

local input_file = process.args[1]
local output_file = process.args[2]

if not input_file then return end

local source = fs.readFile(input_file)
local success, result = pcall(prometheus_infinite_trap, source)

if not success then
    print("Obfuscation error: " .. tostring(result))
    process.exit(1)
end

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
