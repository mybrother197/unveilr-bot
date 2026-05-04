--!nocheck
--[[
    하하난천0 x 난독화 v17.0 "Eternal Shard"
    Metatable Proxy Decryption & Chained Rolling Keys
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Security = require("./Security")

math.randomseed(os.time())

local function generate_id(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local id = "_"
    for i = 1, len or 14 do
        local rand = math.random(#chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_eternal_shard(source)
    -- Chained rolling seed
    local seed = math.random(100, 255)
    local data = {}
    local curr = seed
    for i = 1, #source do
        local b = source:byte(i)
        local enc = bit32.bxor(b, curr)
        enc = bit32.bxor(enc, (i % 256))
        data[i] = enc
        curr = bit32.bxor(enc, (seed + i) % 256)
    end

    local shard_id = generate_id(12)
    local v_mem = generate_id(10)
    local v_key = generate_id(10)
    
    -- Split data into deep nested tables to confuse static analysis
    local function split_to_shards(tbl)
        local shard_code = ""
        local depth = 3
        for i = 1, #tbl, 8 do
            local slice = {}
            for j = i, math.min(i + 7, #tbl) do
                table.insert(slice, tbl[j])
            end
            shard_code ..= string.format("%s[%d] = {%s}\n", v_mem, math.floor(i/8) + 1, table.concat(slice, ","))
        end
        return shard_code
    end

    local final = "--[[ 하하난천0 x 난독화 v17.0 | Eternal Shard Engine ]]\n"
    final ..= "local function _Start(...)\n"
    final ..= Security.GetAntiTamper() .. "\n"
    
    -- Obfuscate the seed using environment markers
    final ..= string.format("local %s = %d + (_Detected * %d)\n", v_key, seed, math.random(500, 2000))
    final ..= string.format("local %s = {}\n", v_mem)
    final ..= split_to_shards(data)
    
    -- Metatable Decryptor (Eternal Shard core)
    final ..= string.format([[
local _p = {}
local _c = %s
setmetatable(_p, {
    __index = function(t, i)
        local sid = math.floor((i-1)/8) + 1
        local off = ((i-1) %% 8) + 1
        local d = %s[sid][off]
        local res = bit32.bxor(d, _c)
        res = bit32.bxor(res, (i %% 256))
        _c = bit32.bxor(d, (%s + i) %% 256)
        return string.char(res)
    end
})

local _s = {}
for i = 1, %d do
    _s[i] = _p[i]
end
local _f = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load
_f(table.concat(_s))()
]], v_key, v_mem, v_key, #source)

    final ..= "end\n_Start(...)\n"
    
    return final
end

local input_file = process.args[1]
local output_file = process.args[2]
if not input_file then return end

local source = fs.readFile(input_file)
local result = prometheus_eternal_shard(source)

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
