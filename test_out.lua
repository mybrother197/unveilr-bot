--[[ 하하난천0 x 난독화 v27.0 | Sentinel Nexus Engine ]]
local function Sentinel__EHBG(...)
    local _ARGS = {...}
    local _Env = getfenv()
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

    
    -- Black Hole Seeding: Key is implicitly modified by security checks
    local _S = (132 + bit32.band(_K_OFFSET, 255)) % 256
    
    local _NODES = {
        [898774] = {d='ec01f50202af02f2', n=365118, o=3},
        [365118] = {d=function() return '3e7a' end, n=-1, o=2}
    }
    
    local _ptr = 898774
    local _key = _S
    local _stream = {}
    
    while _ptr ~= -1 do
        local _node = _NODES[_ptr]
        if not _node then break end
        
        local _raw = _node.d
        if type(_raw) == "function" then _raw = _raw() end
        local _op = _node.o
        
        local _buf = {}
        for i = 1, #_raw, 2 do
            local _enc = tonumber(_raw:sub(i, i+1), 16)
            local _dec = 0
            if _op == 1 then _dec = bit32.bxor(_enc, _key)
            elseif _op == 2 then _dec = (_enc - _key) % 256
            elseif _op == 3 then _dec = (_enc + _key) % 256
            end
            
            table.insert(_buf, string.char(bit32.band(_dec, 255)))
            _key = bit32.band(_key + _enc + (math.floor(i/2) + 1), 255)
        end
        
        table.insert(_stream, table.concat(_buf))
        _NODES[_ptr] = nil 
        _ptr = _node.n
    end
    
    local _L_Name = string.char(108,111,97,100,115,116,114,105,110,103)
    local _L = _Env[_L_Name] or _Env.load or load
    
    if _L then
        local _r, _e = _L(table.concat(_stream))
        if _r then
            pcall(function() if setfenv then setfenv(_r, _Env) end end)
            return _r(unpack(_ARGS))
        end
    end
end
Sentinel__EHBG(...)
