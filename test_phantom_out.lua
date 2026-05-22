-- [[ Phantom Nexus v1.0 ]]
local _ENV = getfenv()
local _G = _G
local _DATA = {182,185,184,191,9,235,245,250,35,192,221,218,6,38,38,55,196,53,58,62,228,124,123,116,211,170,168,163,127,249,128,187,9,17,22,17,138,116,118,1779493173,204,51,49,8,212,18,25,2,128,127,127,102,190,185,187,180,93,165,156,155,48,49,57,70,112,135,133,140,58,192,201,198,49,74,67,68,205,74,85,67,186,192,194,245,67,138,130,147,79,120,127,117,199,29,20,23,252,57,14,9,132,93,98,104,221,45,38,33,147,162,160,169,28,248,227,236,90,237,228,251,36,96,88,91,224,0,11,244,85,237,238,233,95,38,35,60,18,232,234,237,225,234,235,244}
local _CONST = {10,20,"print","Result of a + b: ",15,"is greater than 15","is less than or equal to 15",{216,90,93,90,236,148,149,146,19,19,19,41,26,222,214,247,38,215,212,223,7,23,16,31,184,95,83,74,225,128,135,184,111,255,254,249,37,220,219,212,45,19,18,21,167,92,91,124,254,163,160,163,171,72,73,70},1,2,3,"Table element 1:","Done!"}
local _SEED = 1779493186

local bit32 = bit32 or _ENV.bit32
local _bxor = bit32.bxor

local function _EXEC_VM(bc, seed, args, env)
	local bc_len = #bc
	local pc = 1
	local regs = {}
	local vctx = seed % 65536
	local handlers = {}
	
	-- Sentinel: Seal Environment
	local _print = env.print or _G.print or print
	local _type = env.type or _G.type or type
	local _tostring = env.tostring or _G.tostring or tostring
	local _os_clock = (env.os and env.os.clock) or (_G.os and _G.os.clock) or (os and os.clock) or function() return 0 end
	
	-- Pass arguments to registers
	if args then
		for i, v in ipairs(args) do regs[i-1] = v end
	end

	-- Handlers same as parent for PoC
	handlers[195] = function(a, b, c) regs[a] = (regs[b] > regs[c]) end
handlers[245] = function(a, b, c) regs[a] = _CONST[b + 1] end
handlers[237] = function(a, b, c) regs[a] = regs[b][regs[c]] end
handlers[137] = function(a, b, c) pc = a * 4 + 1 end
handlers[155] = function(a, b, c) regs[a] = regs[b] end
handlers[251] = function(a, b, c) env[_CONST[b+1]] = regs[a] end
handlers[152] = function(a, b, c) regs[a] = (regs[b] < regs[c]) end
handlers[82] = function(a, b, c) regs[a] = (b == 1) end
handlers[72] = function(a, b, c) regs[a] = {} end
handlers[75] = function(a, b, c) return 'HALT' end
handlers[205] = function(a, b, c) regs[a] = not regs[b] end
handlers[206] = function(a, b, c) regs[a][regs[b]] = regs[c] end
handlers[214] = function(a, b, c) regs[a] = regs[b] / regs[c] end
handlers[189] = function(a, b, c) regs[a] = regs[b] + regs[c] end
handlers[116] = function(a, b, c) if not regs[a] then pc = b * 4 + 1 end end
handlers[77] = function(a, b, c) regs[a] = (regs[b] <= regs[c]) end
handlers[11] = function(a, b, c) regs[a] = regs[b] % regs[c] end
handlers[99] = function(a, b, c) regs[a] = (regs[b] >= regs[c]) end
handlers[159] = function(a, b, c) regs[a] = env[_CONST[b+1]] or _G[_CONST[b+1]] end
handlers[133] = function(a, b, c) regs[a] = #regs[b] end
handlers[216] = function(a, b, c) 			local sub_bc = _CONST[b + 1]
			local sub_seed = c
			regs[a] = function(...) return _EXEC_VM(sub_bc, sub_seed, { ... }, env) end
		 end
handlers[182] = function(a, b, c) regs[a] = nil end
handlers[142] = function(a, b, c) regs[a] = regs[b] or regs[c] end
handlers[45] = function(a, b, c) regs[a] = regs[b] - regs[c] end
handlers[65] = function(a, b, c) regs[a] = (regs[b] == regs[c]) end
handlers[236] = function(a, b, c) 			local func = regs[a]
			local args = {}
			for i=1, b do args[i] = regs[a + i] or nil end
			local results = { func(table.unpack(args)) }
			for i=1, c do regs[a + i - 1] = results[i] end
		 end
handlers[168] = function(a, b, c) regs[a] = regs[b] and regs[c] end
handlers[246] = function(a, b, c) regs[a] = regs[b] * regs[c] end
handlers[179] = function(a, b, c) regs[a] = (regs[b] ~= regs[c]) end

	local function _LOOP()
		local roll = seed % 256
		local epoch = 0
		local last_tick = _os_clock()
		
		while pc <= bc_len do
			-- Sentinel: Timing Oracle
			epoch = epoch + 1
			if epoch % 128 == 0 then
				if _os_clock() - last_tick > 0.5 then
					vctx = _bxor(vctx, 0xDEADC0DE)
				end
				last_tick = _os_clock()
			end

			-- Stage 1: Individual Decryption
			local raw = {bc[pc], bc[pc+1], bc[pc+2], bc[pc+3]}
			local inst = {}
			for i=1, 4 do
				local key = _bxor(_bxor(roll, (pc + i - 1) % 256), vctx % 256)
				local d = _bxor(raw[i], key)
				inst[i] = d
				roll = (roll + d) % 256
			end
			pc = pc + 4

			local op = inst[1]
			local a = inst[2]
			local b = inst[3]
			local c = inst[4]

			-- Opcode Morphing based on vctx
			local morphed_op = _bxor(op, vctx % 256)
			local h = handlers[morphed_op]
			
			if h then
				local res = h(a, b, c)
				
				-- Context Mutation (Nexus Flux - Simplified for jumps)
				vctx = _bxor(vctx, pc - 4) % 65536
				
				if res == "HALT" then
					local returns = {}
					for i=a, a + b - 1 do table.insert(returns, regs[i]) end
					return table.unpack(returns)
				end
			else
				-- Trap State: Scramble context on invalid op
				vctx = _bxor(vctx, 0xDEADC0DE)
			end
		end
	end
	return _LOOP()
end

-- Main entry
local main_bc = _DATA
local main_seed = _SEED
_EXEC_VM(main_bc, main_seed, {}, _ENV)
