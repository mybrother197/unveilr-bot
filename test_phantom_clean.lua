--[[ Prometheus X Phantom v12.5 ]]
local lPsppIPIECDJ = function(...)
    local _Env = getfenv()
    pcall(function() if _Env.P == 'getfenv()' then while true do end end end)
    local iGlneLXhEB = {"6b6972756f33","2b321611"} local _0x_Key = 0 pcall(function()     _0x_Key = _0x_Key + #typeof(game)     _0x_Key = _0x_Key + #game.ClassName     _0x_Key = _0x_Key + (type(spawn) == "function" and 10 or 5) end)  local yXxffwviGX = _0x_Key local trfrVZcJNr = {} for _, ch in ipairs(iGlneLXhEB) do     for i = 1, #ch, 2 do         local b = tonumber(ch:sub(i, i+1), 16)         if b then             local rb = bit32.bxor(b, yXxffwviGX)             table.insert(trfrVZcJNr, string.char(rb))         end     end end local _src = table.concat(trfrVZcJNr) local _run = (getfenv and getfenv()[string.char(108,111,97,100,115,116,114,105,110,103)]) or loadstring or load local _f, _e = _run(_src) if _f then _f() else error(_e or "Failed to load") end 
end
return lPsppIPIECDJ(...)
