--!nocheck
--[[
    Prometheus X v9.0 - Premium Obfuscator
    Based on Multi-layer XOR + C-fill + Logic VM
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

-- ── 환경 초기화 ──
math.randomseed(os.time() * 1000)
for _ = 1, 10 do math.random() end

local function generate_id(len, prefix)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZlIlIlOoO"
    local id = prefix or "_"
    for i = 1, len or 10 do
        local rand = math.random(1, #chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function obf_int(n)
    local a = math.random(5, 15)
    local b = math.random(5, 15)
    local diff = n - (a * b)
    if diff >= 0 then
        return string.format("(%d*%d+%d)", a, b, diff)
    else
        return string.format("(%d*%d-%d)", a, b, -diff)
    end
end

local function hexlit(data)
    local h = ""
    for i = 1, #data do
        h ..= string.format("%02x", data:byte(i))
    end
    -- 랜덤 분할
    local parts = {}
    local split = math.random(80, 150) * 2
    local i = 1
    while i <= #h do
        parts[#parts+1] = h:sub(i, i + split - 1)
        i += split
    end
    return '"' .. table.concat(parts, '".. "') .. '"'
end

-- ── Junk Code Templates ──
local function generate_junk(vp_count)
    local templates = {
        function() return string.format("local %s=%d;", generate_id(8), math.random(0,9999)) end,
        function() return string.format("local %s=nil;%s=false;", generate_id(8), generate_id(8)) end,
        function() return string.format("pcall(function() return %s end);", generate_id(6)) end,
        function() return string.format("local %s=math.max(%d,%d);", generate_id(8), math.random(1,100), math.random(1,100)) end
    }
    local res = ""
    for _ = 1, vp_count or 5 do
        res ..= templates[math.random(#templates)]()
    end
    return res
end

-- ── Principal VM Obfuscation ──
local function prometheus_x_obfuscate(source)
    -- Hidden Constants
    local LS_char = "string.char(108,111,97,100,115,116,114,105,110,103)"
    
    -- Layer 1: Enhanced XOR + Additive
    local function encrypt_l1(src)
        local xk = math.random(10, 250)
        local ak = math.random(5, 100)
        local res = {}
        for i = 1, #src do
            local b = src:byte(i)
            res[i] = string.char((bit32.bxor(b, xk) + ak + (i-1)) % 256)
        end
        return table.concat(res), xk, ak
    end

    local l1_code, xk, ak = encrypt_l1(source)
    
    -- VM Layout (Simplified bytecode engine inside XOR layers)
    local bytecode = hexlit(l1_code)
    
    local v_load = generate_id(8, "ld_")
    local v_xk = generate_id(8, "xk_")
    local v_ak = generate_id(8, "ak_")
    local v_bc = generate_id(8, "bc_")
    local v_res = generate_id(8, "res_")
    
    -- Core Engine Logic
    local core = string.format([[
local %s = getfenv and getfenv()[%s] or _G[%s];
local %s = %s;
local %s = %s;
local %s = %s;
local %s = {};
local i = 1;
%s:gsub('..', function(c)
    local b = (tonumber(c, 16) - %s - (i-1)) %% 256;
    %s[i] = string.char(bit32.bxor(b, %s));
    i = i + 1;
end);
%s(table.concat(%s))();
]], v_load, LS_char, LS_char, v_xk, obf_int(xk), v_ak, obf_int(ak), v_bc, bytecode, v_res, v_bc, v_ak, v_res, v_xk, v_load, v_res)

    -- C-fill Wrapping
    local function cfill_encode(data)
        local seps = {"a","b","d","e","f","g","h","j","k"}
        local out = {}
        for i = 1, #data do
            local b = data:byte(i)
            local hi = math.floor(b / 16)
            local lo = b % 16
            out[#out+1] = string.rep("C", hi) .. seps[math.random(#seps)]
            out[#out+1] = string.rep("C", lo) .. seps[math.random(#seps)]
        end
        return table.concat(out)
    end

    local final_cfill = cfill_encode(core)
    
    -- Final Loader
    local v_e = generate_id(10, "enc_")
    local v_t = generate_id(10, "tbl_")
    local v_k = generate_id(10, "k_")
    local v_c = generate_id(5, "c_")
    
    local loader = string.format([[
local %s = "%s";
local %s, %s, %s, %s = {}, 0, false, 0;
%s:gsub('.', function(%s)
    if %s == 'C' then %s = %s + 1
    else
        if not %s then %s = %s; %s = true
        else %s[#%s+1] = string.char(%s*16 + %s); %s = false end
        %s = 0
    end
end);
(loadstring or load)(table.concat(%s))();
]], v_e, final_cfill, v_t, v_k, "is_hi", v_k, v_e, v_c, v_c, v_k, v_k, "is_hi", "hi_v", v_k, "is_hi", v_t, v_t, "hi_v", v_k, "is_hi", v_k, v_t)

    -- Oneliner transformation
    local function oneliner(s)
        return s:gsub("\n", " "):gsub("%s+", " ")
    end

    return "--[[ Prometheus X v9.0 ]]\n" .. generate_junk(10) .. oneliner(loader)
end

local input_file = process.args[1]
local output_file = process.args[2]

if not input_file then
    print("Usage: lune run obfuscator.luau <input> <output>")
    return
end

local source = fs.readFile(input_file)
local success, result = pcall(prometheus_x_obfuscate, source)

if not success then
    print("Obfuscation error: " .. tostring(result))
    process.exit(1)
end

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
