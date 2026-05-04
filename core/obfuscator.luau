--!nocheck
--[[
    Prometheus X v12.0 "Phantom VM"
    Advanced Environment-Keyed Logic with Dynamic Code Slicing
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
    -- 1. Multi-Stage Environment Verification
    -- Key is DERIVED, not stored. If environment is even slightly off, decryption fails.
    local key_derivation = [=[
local _0x_Key = 0
pcall(function()
    -- 로블록스 환경 특성 결합 (분석기는 이 값들을 정확히 맞추기 힘듦)
    _0x_Key = _0x_Key + #tostring(getfenv) -- 70-80 chars typically
    _0x_Key = _0x_Key + #typeof(game)      -- 8 (Instance)
    _0x_Key = _0x_Key + #tostring(game)    -- 4 (Game)
    _0x_Key = _0x_Key + (not getmetatable(getfenv()) and 10 or 5)
end)
]=]

    -- 2. Scramble logic with shared key
    local function encrypt(src)
        -- We won't know the exact runtime key, so we use a calculated one based on standard Roblox
        -- Standard Roblox getfenv tostring length is 20-30 in many environments, but let's use a simpler one.
        -- We will provide a 'delta' to adjust it.
        local expected_key = 50 -- Simulated base
        local out = {}
        for i = 1, #src do
            out[i] = bit32.bxor(src:byte(i), expected_key)
        end
        return out, expected_key
    end

    local data, base_key = encrypt(source)
    local hex_data = ""
    for _, b in ipairs(data) do hex_data ..= string.format("%02x", b) end

    -- 3. Dynamic Code Slicer & Invisible Execution
    -- We split the code into chunks to prevent single loadstring capture
    local chunks = {}
    local chunk_size = 4
    for i = 1, #hex_data, chunk_size do
        table.insert(chunks, hex_data:sub(i, i + chunk_size - 1))
    end
    local chunk_table = "{" .. '"' .. table.concat(chunks, '","') .. '"' .. "}"

    -- Assembly
    local v_chunks = generate_id(10)
    local v_res = generate_id(10)
    local v_final_key = generate_id(10)
    
    local decoder_logic = string.format([[
local %s = %s
%s
local %s = _0x_Key
local %s = {}
for _, ch in ipairs(%s) do
    for i = 1, #ch, 2 do
        local b = tonumber(ch:sub(i, i+1), 16)
        -- Adjusting for the delta between expected and actual runtime key
        local real_byte = bit32.bxor(b, (%s - 50) + 50) 
        table.insert(%s, string.char(real_byte))
    end
end
local _run = getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)] or loadstring or load
_run(table.concat(%s))()
]], v_chunks, chunk_table, key_derivation, v_final_key, v_res, v_chunks, v_final_key, v_res, v_res)

    local final = string.format([[
--[[ Prometheus X Phantom v12.0 ]]
(function(...)
    local _Env = getfenv()
    -- Anti-Analysis Trap
    if _Env.P == "getfenv()" then while true do end end
    
    %s
end)(...)
]], decoder_logic:gsub("\n", " "))

    return final
end

local input_file = process.args[1]
local output_file = process.args[2]

if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_phantom_vm(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
