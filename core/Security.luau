--!nocheck
--[[
    하하난천0 x 난독화 v28.0 "Black Hole" Security Wall
    Invisible Poisoning & Environment Fingerprinting
]]

local Security = {}

function Security.GetAntiTamper()
    return [[
local _K_OFFSET = 0
local _Dbg = debug and debug.info
local _E = getfenv()

-- Stealthy Environmental Scan
-- Directly bombards the key if markers exist
for _k, _v in pairs(_E) do
    local _s = tostring(_k)
    -- Target Unveilr / Luraph / Analysis Markers
    if _s == "P" or _s == "V" or _s == "TS" or _s:find("UNVEIL") or _s:find("LURAPH") then
        _K_OFFSET = _K_OFFSET + 88
    end
end

for _k, _v in pairs(_G) do
    local _s = tostring(_k)
    if _s:find("UNVEIL") or _s == "__A" then
        _K_OFFSET = _K_OFFSET + 111
    end
end

-- Native Verification: Supports both Roblox (=[C]) and local ([C])
local function _Check(f)
    if _Dbg then
        local s = _Dbg(f, "s")
        if not (s:find("C") or s:find("lune")) then 
            _K_OFFSET = _K_OFFSET + 55
        end
    end
end
_Check(loadstring or load)
_Check(getfenv)
]]
end

return Security
