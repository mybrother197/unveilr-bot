--!nocheck
--[[
    Prometheus X v12.3 "Phantom VM"
    Ultimate Stability for Roblox Executors
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local id = ""
    for i = 1, len or 16 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_phantom_vm(source)
    -- 1. Rock-Solid Environment Verification
    -- Using values that are 100% constant across ALL Roblox environments
    local key_derivation = [[
local _0x_Key = 0
pcall(function()
    _0x_Key = _0x_Key + #typeof(game)      -- 8 ("Instance")
    _0x_Key = _0x_Key + #game.ClassName    -- 9 ("DataModel")
    _0x_Key = _0x_Key + (type(spawn) == "function" and 10 or 5) -- Stable Check
end)
]]

    -- 2. Scramble logic
    local function encrypt(src)
        -- 8 + 9 + 10 = 27 (Default for Roblox)
        local expected_key = 27
        local out = {}
        for i = 1, #src do
            out[i] = bit32.bxor(src:byte(i), expected_key)
        end
        return out, expected_key
    end

    local data, base_key = encrypt(source)
    local hex_data = ""
    for _, b in ipairs(data) do hex_data ..= string.format("%02x", b) end

    -- 3. Dynamic Code Slicer
    local chunks = {}
    local chunk_size = 12
    for i = 1, #hex_data, chunk_size do
        table.insert(chunks, hex_data:sub(i, i + chunk_size - 1))
    end
    local chunk_table = "{" .. '"' .. table.concat(chunks, '","') .. '"' .. "}"

    local v_chunks = generate_id(10)
    local v_res = generate_id(10)
    local v_fkey = generate_id(10)
    
    local decoder_template = [[
local V_CHUNKS = CHUNK_DATA;
KEY_DERIVATION;
local V_FKEY = _0x_Key;
local V_RES = {};
for _, ch in ipairs(V_CHUNKS) do
    for i = 1, #ch, 2 do
        local b = tonumber(ch:sub(i, i+1), 16);
        if b then
            local rb = bit32.bxor(b, V_FKEY);
            table.insert(V_RES, string.char(rb));
        end
    end
end;
local _src = table.concat(V_RES);
local _run = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load;
local _f, _e = _run(_src);
if _f then _f() else error(_e or "Failed to load") end;
]]
    
    local function safe_replace(str, p, r)
        return (str:gsub(p, function() return tostring(r) end))
    end

    local decoder = decoder_template
    decoder = safe_replace(decoder, "V_CHUNKS", v_chunks)
    decoder = safe_replace(decoder, "CHUNK_DATA", chunk_table)
    decoder = safe_replace(decoder, "KEY_DERIVATION", key_derivation)
    decoder = safe_replace(decoder, "V_FKEY", v_fkey)
    decoder = safe_replace(decoder, "V_RES", v_res)

    -- Final Product
    local final = "--[[ Prometheus X Phantom v12.3 ]]\n"
    final ..= "(function(...)\n"
    final ..= "    local _Env = getfenv();\n"
    final ..= "    pcall(function() if _Env.P == 'getfenv()' then while true do end end end);\n"
    final ..= "    " .. (decoder:gsub("\n", " ")) .. "\n"
    final ..= "end)(...)\n"

    return final
end

local input_file = process.args[1]
local output_file = process.args[2]

if not input_file then return end

local source = fs.readFile(input_file)
local success, result = pcall(prometheus_phantom_vm, source)

if not success then
    print("Obfuscation error: " .. tostring(result))
    process.exit(1)
end

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
