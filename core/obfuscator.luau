--!nocheck
local fs = require("@lune/fs")
local process = require("@lune/process")

local function generate_id(len, prefix)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = prefix or "_"
    for i = 1, len or 12 do
        local rand = math.random(1, #chars)
        id ..= chars:sub(rand, rand)
    end
    return id
end

local function prometheus_obfuscate(source)
    local function hex_encrypt(s)
        local res = ""
        for i = 1, #s do res ..= string.format("\\x%02X", s:byte(i)) end
        return '"' .. res .. '"'
    end

    -- 정적 분석 방지: 정적 분석기가 코드를 해석하기 어렵게 대량의 정크 코드 생성
    local function generate_junk(amount)
        local junk = ""
        for i = 1, amount or 5 do
            local var = generate_id(8, "_0x_junk")
            junk ..= string.format("local %s = %d; ", var, math.random(1000, 9999))
            junk ..= string.format("%s = %s + %d; ", var, var, math.random(1, 100))
        end
        return junk
    end

    -- 정적 분석 방지: Opaque Predicates (항상 참이지만 분석기는 판단하기 힘든 조건부 로직)
    local function wrap_opaque(code)
        local predicates = {
            "if (math.sin(math.pi) < 0.1) then",
            "if (math.floor(math.sqrt(144)) == 12) then",
            "if (tonumber('1' .. '0') == 10) then"
        }
        local p = predicates[math.random(1, #predicates)]
        return p .. "\n" .. code .. "\nend"
    end

    -- 1. Constants (with dynamic decryption logic)
    local constants = {}
    local processed = source:gsub('"(.-)"', function(s)
        table.insert(constants, hex_encrypt(s))
        return `_C_[{#constants}]`
    end):gsub("'(.-)'", function(s)
        table.insert(constants, hex_encrypt(s))
        return `_C_[{#constants}]`
    end)

    -- 2. Anti-Tamper & Static Analysis Block
    local anti_tamper = [=[
    local _Env = getfenv()
    local _T = tostring
    local function _Crash()
        local _f; _f = function() return _f() end
        while true do _f() end
    end
    
    -- 정적 분석 및 패턴 매칭 방전: Opaque Predicate
    if not (math.pi > 3 and math.huge > 1) then _Crash() end

    if getmetatable(_Env) then _Crash() end
    if not _T(print):find("function:") then _Env.error("Tampering") end
    
    -- 로블록스 보안
    pcall(function()
        if typeof(game) ~= "Instance" then _Crash() end
        if _T(game) ~= "Game" and _T(game) ~= "game" then _Crash() end
    end)
    ]=]

    -- 3. Assembly
    local vm_id = generate_id(8, "_VM")
    local disp_id = generate_id(8, "_Disp")
    local consts_id = generate_id(8, "_Consts")
    
    -- 대량의 정크 코드를 삽입하여 분석기 성능 저하 및 가독성 파괴
    local junk_block = generate_junk(20)
    local final_processed = wrap_opaque(processed)

    local const_table = "{" .. table.concat(constants, ", ") .. "}"
    
    local result = "--[[ Prometheus VM v6.0 | Anti-Static Analysis ]]\n"
    result ..= "local " .. vm_id .. " = (function(...)\n"
    result ..= "    " .. junk_block .. "\n"
    result ..= anti_tamper .. "\n"
    result ..= "    local " .. consts_id .. " = " .. const_table .. "\n"
    result ..= "    local function " .. disp_id .. "(...)\n"
    result ..= "        local _C_ = " .. consts_id .. "\n"
    result ..= "        " .. generate_junk(10) .. "\n"
    result ..= "        " .. final_processed .. "\n"
    result ..= "    end\n"
    result ..= "    return " .. disp_id .. "(...)\n"
    result ..= "end)(...)\n"
    result ..= "return " .. vm_id .. "\n"
    
    return result
end

local input_file = process.args[1]
local output_file = process.args[2]

if not input_file then
    print("Usage: lune run obfuscator.luau <input> <output>")
    return
end

local source = fs.readFile(input_file)
local success, result = pcall(prometheus_obfuscate, source)

if not success then
    print("Obfuscation error: " .. tostring(result))
    process.exit(1)
end

if output_file then
    fs.writeFile(output_file, result)
else
    print(result)
end
