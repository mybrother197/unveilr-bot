--[[ Prometheus VM v8.0 | Bytecode Engine ]]
local function _VMmlPojHRuvu(...)
    local _0x_Data = {
        Bytecode = {{1,1,1,},{2,2,2,},{3,1,1,0,},{4,0,0,0,},},
        Constants = {"\x70\x72\x69\x6E\x74",0,},
    }
    
    local _0x_Env = getfenv()
    local _0x_PC = 1
    local _0x_Stack = {}
    
    -- Anti-Tamper Check
    if tostring(getfenv):find("proxy") then while true do end end

    while _0x_PC <= #_0x_Data.Bytecode do
        local _0x_Instr = _0x_Data.Bytecode[_0x_PC]
        local _0x_Op = _0x_Instr[1]
        
        if _0x_Op == 1 then -- GETGLOBAL
            _0x_Stack[_0x_Instr[2]] = _0x_Env[_0x_Data.Constants[_0x_Instr[3]]]
        elseif _0x_Op == 2 then -- LOADK
            _0x_Stack[_0x_Instr[2]] = _0x_Data.Constants[_0x_Instr[3]]
        elseif _0x_Op == 3 then -- CALL
            local _0x_Func = _0x_Stack[_0x_Instr[2]]
            local _0x_Args = {}
            for i = 1, _0x_Instr[3] do
                _0x_Args[i] = _0x_Stack[_0x_Instr[2] + i]
            end
            local _0x_Res = { _0x_Func(unpack(_0x_Args)) }
            -- Handle returns if needed
        elseif _0x_Op == 4 then -- RETURN
            return
        end
        _0x_PC = _0x_PC + 1
    end
end
return _VMmlPojHRuvu(...)
