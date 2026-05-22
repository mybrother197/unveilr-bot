--[[
  Phantom Nexus — 완전 독립 가상환경 기반 VM 난독화 시스템
  Luau Source → Alien IR → Encrypted Bytecode + Self-Contained VM Runtime
  
  Modules:
    1. Lexer (Tokenizer)
    2. Parser (Recursive Descent AST)
    3. Semantic Compiler (AST → Alien IR)
    4. Bytecode Emitter (Alien IR → Encrypted Stream)
    5. Runtime Generator (VM Runtime Lua Code)
    6. Build Orchestrator
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local Lexer, Parser, SemanticCompiler, BytecodeEmitter, RuntimeGenerator

------------------------------------------------------------------------
-- MODULE 1: LEXER
------------------------------------------------------------------------
Lexer = {}
Lexer.__index = Lexer

local KEYWORDS = {
  ["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
  ["end"]=true,["false"]=true,["for"]=true,["function"]=true,["if"]=true,
  ["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,
  ["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,["until"]=true,
  ["while"]=true,["continue"]=true,
}

function Lexer.new(source: string)
  return setmetatable({
    src = source, pos = 1, line = 1, col = 1,
    tokens = {}, len = #source,
  }, Lexer)
end

function Lexer:peek(): string?
  if self.pos > self.len then return nil end
  return string.sub(self.src, self.pos, self.pos)
end

function Lexer:advance(): string?
  local c = self:peek()
  if c then
    self.pos += 1
    if c == "\n" then self.line += 1; self.col = 1
    else self.col += 1 end
  end
  return c
end

function Lexer:match(expected: string): boolean
  if self:peek() == expected then self:advance(); return true end
  return false
end

function Lexer:skipWhitespaceAndComments()
  while self.pos <= self.len do
    local c = self:peek()
    if c == " " or c == "\t" or c == "\r" or c == "\n" then
      self:advance()
    elseif c == "-" and string.sub(self.src, self.pos, self.pos+1) == "--" then
      self:advance(); self:advance()
      if string.sub(self.src, self.pos, self.pos+1) == "[[" then
        self:advance(); self:advance()
        while self.pos <= self.len do
          if string.sub(self.src, self.pos, self.pos+1) == "]]" then
            self:advance(); self:advance(); break
          end
          self:advance()
        end
      else
        while self.pos <= self.len and self:peek() ~= "\n" do self:advance() end
      end
    else break end
  end
end

function Lexer:readString(quote: string): string
  local buf = {}
  while self.pos <= self.len do
    local c = self:advance()
    if c == quote then return table.concat(buf) end
    if c == "\\" then
      local esc = self:advance()
      if esc == "n" then table.insert(buf, "\n")
      elseif esc == "t" then table.insert(buf, "\t")
      elseif esc == "\\" then table.insert(buf, "\\")
      elseif esc == "\"" then table.insert(buf, "\"")
      elseif esc == "'" then table.insert(buf, "'")
      elseif esc == "r" then table.insert(buf, "\r")
      elseif esc == "0" then table.insert(buf, "\0")
      else table.insert(buf, esc or "") end
    else
      table.insert(buf, c or "")
    end
  end
  return table.concat(buf)
end

function Lexer:readLongString(): string
  local level = 0
  while self:peek() == "=" do self:advance(); level += 1 end
  if self:peek() == "[" then self:advance() else error("Lexer: invalid long string") end
  if self:peek() == "\n" then self:advance() end
  local buf = {}
  local closePattern = "]" .. string.rep("=", level) .. "]"
  while self.pos <= self.len do
    if string.sub(self.src, self.pos, self.pos + #closePattern - 1) == closePattern then
      for _ = 1, #closePattern do self:advance() end
      return table.concat(buf)
    end
    table.insert(buf, self:advance() or "")
  end
  return table.concat(buf)
end

function Lexer:readNumber(): string
  local start = self.pos
  if self:peek() == "0" and (string.sub(self.src, self.pos+1, self.pos+1) == "x" or string.sub(self.src, self.pos+1, self.pos+1) == "X") then
    self:advance(); self:advance()
    while self.pos <= self.len and string.find(self:peek() or "", "[0-9a-fA-F_]") do self:advance() end
  else
    while self.pos <= self.len and string.find(self:peek() or "", "[0-9_]") do self:advance() end
    if self:peek() == "." and string.find(string.sub(self.src, self.pos+1, self.pos+1), "[0-9]") then
      self:advance()
      while self.pos <= self.len and string.find(self:peek() or "", "[0-9_]") do self:advance() end
    end
    if self:peek() == "e" or self:peek() == "E" then
      self:advance()
      if self:peek() == "+" or self:peek() == "-" then self:advance() end
      while self.pos <= self.len and string.find(self:peek() or "", "[0-9]") do self:advance() end
    end
  end
  return string.sub(self.src, start, self.pos - 1)
end

function Lexer:emit(type: string, value: any)
  table.insert(self.tokens, {type=type, value=value, line=self.line, col=self.col})
end

function Lexer:tokenize(): {any}
  while true do
    self:skipWhitespaceAndComments()
    if self.pos > self.len then break end
    local c = self:peek() :: string
    local ln, cl = self.line, self.col

    if c == "\"" or c == "'" then
      self:advance()
      local s = self:readString(c)
      table.insert(self.tokens, {type="string", value=s, line=ln, col=cl})
    elseif c == "[" and (string.sub(self.src, self.pos+1, self.pos+1) == "[" or string.sub(self.src, self.pos+1, self.pos+1) == "=") then
      self:advance()
      local s = self:readLongString()
      table.insert(self.tokens, {type="string", value=s, line=ln, col=cl})
    elseif string.find(c, "[0-9]") then
      local n = self:readNumber()
      table.insert(self.tokens, {type="number", value=tonumber((string.gsub(n, "_", ""))), line=ln, col=cl})
    elseif string.find(c, "[a-zA-Z_]") then
      local start = self.pos
      while self.pos <= self.len and string.find(self:peek() or "", "[a-zA-Z0-9_]") do self:advance() end
      local word = string.sub(self.src, start, self.pos - 1)
      if word == "true" then table.insert(self.tokens, {type="boolean", value=true, line=ln, col=cl})
      elseif word == "false" then table.insert(self.tokens, {type="boolean", value=false, line=ln, col=cl})
      elseif word == "nil" then table.insert(self.tokens, {type="nil", value=nil, line=ln, col=cl})
      elseif KEYWORDS[word] then table.insert(self.tokens, {type="keyword", value=word, line=ln, col=cl})
      else table.insert(self.tokens, {type="name", value=word, line=ln, col=cl}) end
    elseif c == "." then
      self:advance()
      if self:peek() == "." then
        self:advance()
        if self:peek() == "." then self:advance(); table.insert(self.tokens, {type="symbol", value="...", line=ln, col=cl})
        else table.insert(self.tokens, {type="symbol", value="..", line=ln, col=cl}) end
      elseif string.find(self:peek() or "", "[0-9]") then
        self.pos -= 1
        local n = self:readNumber()
        table.insert(self.tokens, {type="number", value=tonumber(n), line=ln, col=cl})
      else table.insert(self.tokens, {type="symbol", value=".", line=ln, col=cl}) end
    elseif c == "=" then
      self:advance()
      if self:match("=") then table.insert(self.tokens, {type="symbol", value="==", line=ln, col=cl})
      else table.insert(self.tokens, {type="symbol", value="=", line=ln, col=cl}) end
    elseif c == "~" then
      self:advance()
      if self:match("=") then table.insert(self.tokens, {type="symbol", value="~=", line=ln, col=cl})
      else table.insert(self.tokens, {type="symbol", value="~", line=ln, col=cl}) end
    elseif c == "<" then
      self:advance()
      if self:match("=") then table.insert(self.tokens, {type="symbol", value="<=", line=ln, col=cl})
      else table.insert(self.tokens, {type="symbol", value="<", line=ln, col=cl}) end
    elseif c == ">" then
      self:advance()
      if self:match("=") then table.insert(self.tokens, {type="symbol", value=">=", line=ln, col=cl})
      else table.insert(self.tokens, {type="symbol", value=">", line=ln, col=cl}) end
    elseif c == "#" then self:advance(); table.insert(self.tokens, {type="symbol", value="#", line=ln, col=cl})
    else
      self:advance()
      table.insert(self.tokens, {type="symbol", value=c, line=ln, col=cl})
    end
  end
  table.insert(self.tokens, {type="eof", value="", line=self.line, col=self.col})
  return self.tokens
end

------------------------------------------------------------------------
-- MODULE 2: PARSER (Recursive Descent → AST)
------------------------------------------------------------------------
Parser = {}
Parser.__index = Parser

function Parser.new(tokens: {any})
  return setmetatable({tokens=tokens, pos=1}, Parser)
end

function Parser:current() return self.tokens[self.pos] end
function Parser:peek(offset: number?) return self.tokens[self.pos + (offset or 0)] end

function Parser:advance()
  local t = self:current()
  self.pos += 1
  return t
end

function Parser:expect(type: string, value: any?): any
  local t = self:current()
  if not t or t.type ~= type or (value ~= nil and t.value ~= value) then
    error(string.format("Parse error at line %d: expected %s '%s', got %s '%s'",
      t and t.line or 0, type, tostring(value or ""), t and t.type or "eof", tostring(t and t.value or "")))
  end
  self.pos += 1
  return t
end

function Parser:check(type: string, value: any?): boolean
  local t = self:current()
  if not t then return false end
  if t.type ~= type then return false end
  if value ~= nil and t.value ~= value then return false end
  return true
end

function Parser:consume(type: string, value: any?): any?
  if self:check(type, value) then
    local t = self:current()
    self.pos += 1
    return t
  end
  return nil
end

function Parser:parseBlock(): any
  local stmts = {}
  while true do
    self:skipSemicolons()
    local t = self:current()
    if not t or t.type == "eof" then break end
    if t.type == "keyword" and (t.value == "end" or t.value == "else" or t.value == "elseif" or t.value == "until") then break end
    table.insert(stmts, self:parseStatement())
  end
  return {tag="Block", body=stmts}
end

function Parser:skipSemicolons()
  while self:consume("symbol", ";") do end
end

function Parser:parseStatement(): any
  local t = self:current()
  if t.type == "keyword" then
    if t.value == "local" then return self:parseLocal()
    elseif t.value == "if" then return self:parseIf()
    elseif t.value == "while" then return self:parseWhile()
    elseif t.value == "for" then return self:parseFor()
    elseif t.value == "repeat" then return self:parseRepeat()
    elseif t.value == "return" then return self:parseReturn()
    elseif t.value == "break" then self.pos+=1; return {tag="Break"}
    elseif t.value == "continue" then self.pos+=1; return {tag="Continue"}
    elseif t.value == "do" then return self:parseDoBlock()
    elseif t.value == "function" then return self:parseFunctionStat()
    end
  end
  return self:parseExpressionStatement()
end

function Parser:parseLocal(): any
  self:expect("keyword", "local")
  if self:check("keyword", "function") then
    self:expect("keyword", "function")
    local name = self:expect("name").value
    local func = self:parseFunctionBody()
    return {tag="LocalFunction", name=name, func=func}
  end
  local names = {self:expect("name").value}
  while self:consume("symbol", ",") do table.insert(names, self:expect("name").value) end
  local values = {}
  if self:consume("symbol", "=") then
    values = self:parseExpressionList()
  end
  return {tag="LocalAssign", names=names, values=values}
end

function Parser:parseIf(): any
  self:expect("keyword", "if")
  local cond = self:parseExpression()
  self:expect("keyword", "then")
  local body = self:parseBlock()
  local elseifs = {}
  while self:consume("keyword", "elseif") do
    local ec = self:parseExpression()
    self:expect("keyword", "then")
    local eb = self:parseBlock()
    table.insert(elseifs, {cond=ec, body=eb})
  end
  local elseBody = nil
  if self:consume("keyword", "else") then elseBody = self:parseBlock() end
  self:expect("keyword", "end")
  return {tag="If", cond=cond, body=body, elseifs=elseifs, elseBody=elseBody}
end

function Parser:parseWhile(): any
  self:expect("keyword", "while")
  local cond = self:parseExpression()
  self:expect("keyword", "do")
  local body = self:parseBlock()
  self:expect("keyword", "end")
  return {tag="While", cond=cond, body=body}
end

function Parser:parseFor(): any
  self:expect("keyword", "for")
  local firstName = self:expect("name").value
  if self:consume("symbol", "=") then
    local start = self:parseExpression()
    self:expect("symbol", ",")
    local limit = self:parseExpression()
    local step = nil
    if self:consume("symbol", ",") then step = self:parseExpression() end
    self:expect("keyword", "do")
    local body = self:parseBlock()
    self:expect("keyword", "end")
    return {tag="NumericFor", var=firstName, start=start, limit=limit, step=step, body=body}
  else
    local names = {firstName}
    while self:consume("symbol", ",") do table.insert(names, self:expect("name").value) end
    self:expect("keyword", "in")
    local iterators = self:parseExpressionList()
    self:expect("keyword", "do")
    local body = self:parseBlock()
    self:expect("keyword", "end")
    return {tag="GenericFor", names=names, iterators=iterators, body=body}
  end
end

function Parser:parseRepeat(): any
  self:expect("keyword", "repeat")
  local body = self:parseBlock()
  self:expect("keyword", "until")
  local cond = self:parseExpression()
  return {tag="Repeat", body=body, cond=cond}
end

function Parser:parseReturn(): any
  self:expect("keyword", "return")
  local values = {}
  local t = self:current()
  if t and t.type ~= "eof" and not (t.type == "keyword" and (t.value == "end" or t.value == "else" or t.value == "elseif" or t.value == "until")) and not (t.type == "symbol" and t.value == ";") then
    values = self:parseExpressionList()
  end
  self:consume("symbol", ";")
  return {tag="Return", values=values}
end

function Parser:parseDoBlock(): any
  self:expect("keyword", "do")
  local body = self:parseBlock()
  self:expect("keyword", "end")
  return {tag="Do", body=body}
end

function Parser:parseFunctionStat(): any
  self:expect("keyword", "function")
  local name = self:expect("name").value
  local dotNames = {}
  while self:consume("symbol", ".") do table.insert(dotNames, self:expect("name").value) end
  local isMethod = false
  if self:consume("symbol", ":") then
    table.insert(dotNames, self:expect("name").value)
    isMethod = true
  end
  local func = self:parseFunctionBody(isMethod)
  return {tag="FunctionStat", name=name, dotNames=dotNames, isMethod=isMethod, func=func}
end

function Parser:parseFunctionBody(isMethod: boolean?): any
  self:expect("symbol", "(")
  local params = {}
  local hasVararg = false
  if isMethod then table.insert(params, "self") end
  if not self:check("symbol", ")") then
    if self:check("symbol", "...") then
      hasVararg = true; self.pos += 1
    else
      table.insert(params, self:expect("name").value)
      while self:consume("symbol", ",") do
        if self:check("symbol", "...") then hasVararg = true; self.pos += 1; break end
        table.insert(params, self:expect("name").value)
      end
    end
  end
  self:expect("symbol", ")")
  local body = self:parseBlock()
  self:expect("keyword", "end")
  return {tag="Function", params=params, hasVararg=hasVararg, body=body}
end

function Parser:parseExpressionStatement(): any
  local expr = self:parseSuffixExpression()
  if self:check("symbol", "=") or self:check("symbol", ",") then
    local targets = {expr}
    while self:consume("symbol", ",") do table.insert(targets, self:parseSuffixExpression()) end
    self:expect("symbol", "=")
    local values = self:parseExpressionList()
    return {tag="Assign", targets=targets, values=values}
  elseif expr.tag == "Call" or expr.tag == "MethodCall" then
    return expr
  else
    error("Parse error at line " .. (self:current() and self:current().line or 0) .. ": unexpected expression statement")
  end
end

function Parser:parseExpressionList(): {any}
  local list = {self:parseExpression()}
  while self:consume("symbol", ",") do table.insert(list, self:parseExpression()) end
  return list
end

-- Expression parsing with precedence climbing
local BINOP_PRIORITY = {
  ["or"]={1,1}, ["and"]={2,2},
  ["<"]={3,3}, [">"]={3,3}, ["<="]={3,3}, [">="]={3,3}, ["~="]={3,3}, ["=="]={3,3},
  [".."]={5,4}, -- right-assoc
  ["+"]={6,6}, ["-"]={6,6},
  ["*"]={7,7}, ["/"]={7,7}, ["//"]={7,7}, ["%"]={7,7},
  ["^"]={10,9}, -- right-assoc
}

function Parser:parseExpression(minPrec: number?): any
  minPrec = minPrec or 0
  local left = self:parseUnaryExpression()
  while true do
    local t = self:current()
    if not t then break end
    local op = nil
    if t.type == "symbol" and BINOP_PRIORITY[t.value] then op = t.value
    elseif t.type == "keyword" and BINOP_PRIORITY[t.value] then op = t.value
    else break end
    local prec = BINOP_PRIORITY[op]
    if prec[1] < (minPrec :: number) then break end
    self.pos += 1
    local right = self:parseExpression(prec[2] + 1)
    left = {tag="BinOp", op=op, left=left, right=right}
  end
  return left
end

function Parser:parseUnaryExpression(): any
  local t = self:current()
  if t and t.type == "keyword" and t.value == "not" then
    self.pos += 1; return {tag="UnOp", op="not", operand=self:parseUnaryExpression()}
  elseif t and t.type == "symbol" and t.value == "-" then
    self.pos += 1; return {tag="UnOp", op="-", operand=self:parseUnaryExpression()}
  elseif t and t.type == "symbol" and t.value == "#" then
    self.pos += 1; return {tag="UnOp", op="#", operand=self:parseUnaryExpression()}
  end
  return self:parseSuffixExpression()
end

function Parser:parseSuffixExpression(): any
  local expr = self:parsePrimaryExpression()
  while true do
    if self:consume("symbol", ".") then
      local name = self:expect("name").value
      expr = {tag="FieldAccess", object=expr, field=name}
    elseif self:check("symbol", "[") then
      self:advance()
      local index = self:parseExpression()
      self:expect("symbol", "]")
      expr = {tag="Index", object=expr, index=index}
    elseif self:check("symbol", "(") then
      expr = {tag="Call", func=expr, args=self:parseCallArgs()}
    elseif self:check("string") or self:check("symbol", "{") then
      local arg
      if self:check("string") then arg = {tag="Literal", type="string", value=self:current().value}; self.pos+=1
      else arg = self:parseTableConstructor() end
      expr = {tag="Call", func=expr, args={arg}}
    elseif self:consume("symbol", ":") then
      local method = self:expect("name").value
      local args = self:parseCallArgs()
      expr = {tag="MethodCall", object=expr, method=method, args=args}
    else break end
  end
  return expr
end

function Parser:parseCallArgs(): {any}
  self:expect("symbol", "(")
  local args = {}
  if not self:check("symbol", ")") then args = self:parseExpressionList() end
  self:expect("symbol", ")")
  return args
end

function Parser:parsePrimaryExpression(): any
  local t = self:current()
  if not t then error("Parse error: unexpected end of input") end
  if t.type == "number" then self.pos+=1; return {tag="Literal", type="number", value=t.value}
  elseif t.type == "string" then self.pos+=1; return {tag="Literal", type="string", value=t.value}
  elseif t.type == "boolean" then self.pos+=1; return {tag="Literal", type="boolean", value=t.value}
  elseif t.type == "nil" then self.pos+=1; return {tag="Literal", type="nil", value=nil}
  elseif t.type == "name" then self.pos+=1; return {tag="Name", name=t.value}
  elseif t.type == "symbol" and t.value == "..." then self.pos+=1; return {tag="Vararg"}
  elseif t.type == "symbol" and t.value == "(" then
    self.pos+=1
    local expr = self:parseExpression()
    self:expect("symbol", ")")
    return expr
  elseif t.type == "keyword" and t.value == "function" then
    self.pos+=1; return self:parseFunctionBody()
  elseif t.type == "symbol" and t.value == "{" then
    return self:parseTableConstructor()
  else
    error(string.format("Parse error at line %d: unexpected token %s '%s'", t.line, t.type, tostring(t.value)))
  end
end

function Parser:parseTableConstructor(): any
  self:expect("symbol", "{")
  local fields = {}
  while not self:check("symbol", "}") do
    if self:check("symbol", "[") then
      self:advance()
      local key = self:parseExpression()
      self:expect("symbol", "]")
      self:expect("symbol", "=")
      local val = self:parseExpression()
      table.insert(fields, {tag="IndexField", key=key, value=val})
    elseif self:check("name") and self:peek(1) and self:peek(1).type == "symbol" and self:peek(1).value == "=" then
      local name = self:expect("name").value
      self:expect("symbol", "=")
      local val = self:parseExpression()
      table.insert(fields, {tag="NameField", name=name, value=val})
    else
      table.insert(fields, {tag="ValueField", value=self:parseExpression()})
    end
    if not self:consume("symbol", ",") then self:consume("symbol", ";") end
  end
  self:expect("symbol", "}")
  return {tag="Table", fields=fields}
end

function Parser:parse(): any
  local block = self:parseBlock()
  self:expect("eof")
  return block
end

------------------------------------------------------------------------
-- MODULE 3: SEMANTIC COMPILER (AST → Alien IR)
------------------------------------------------------------------------
SemanticCompiler = {}
SemanticCompiler.__index = SemanticCompiler

-- Expanded Alien Semantic ISA (Granular & Non-Lua)
local ALIEN_OPS = {
	"ROUTE_GOTO", "ROUTE_IF", "ROUTE_IFNOT", "ROUTE_LOOP",
	"DATA_SLOT", "DATA_K", "DATA_BOOL", "DATA_NIL",
	"CALC_ADD", "CALC_SUB", "CALC_MUL", "CALC_DIV", "CALC_MOD", "CALC_POW", "CALC_IDIV",
	"GATE_EQ", "GATE_LT", "GATE_LE", "GATE_NEQ", "GATE_GT", "GATE_GE",
	"LOGIC_AND", "LOGIC_OR", "LOGIC_NOT",
	"TABLE_NEW", "TABLE_GET", "TABLE_SET", "TABLE_LEN",
	"ENV_GET", "ENV_SET",
	"FUNC_CALL", "FUNC_RET", "FUNC_CLOSURE", "FUNC_UPVAL",
	"META_GET", "META_SET",
	"SHADE_VOID", "SHADE_GHOST", "SHADE_PHANTOM" -- Fake Ops
}

function SemanticCompiler.new()
	return setmetatable({
		constants = {},
		ir = {},
		regCount = 0,
		locals = {},
		upvalues = {},
		breaks = {},
		continues = {},
	}, SemanticCompiler)
end

function SemanticCompiler:addConstant(val: any): number
	for i, v in ipairs(self.constants) do
		if v == val then return i - 1 end
	end
	table.insert(self.constants, val)
	return #self.constants - 1
end

function SemanticCompiler:emit(op: string, a: number?, b: number?, c: number?, meta: any?)
	table.insert(self.ir, {op = op, a = a, b = b, c = c, meta = meta})
end

function SemanticCompiler:compile(ast: any)
	self:compileBlock(ast)
	self:emit("FUNC_RET", 0, 0) -- Implicit return
	return {ir = self.ir, constants = self.constants}
end

function SemanticCompiler:compileBlock(ast: any)
	for _, stmt in ipairs(ast.body) do
		self:compileStatement(stmt)
	end
end

function SemanticCompiler:compileFunction(func: any, target: number)
	local sub = SemanticCompiler.new()
	sub.isSub = true
	sub.constants = self.constants
	for i, p in ipairs(func.params) do sub.locals[p] = i - 1 end
	sub.regCount = #func.params
	local data = sub:compile(func.body)
	
	-- Compile sub-function IR to bytecode
	local emitter = BytecodeEmitter.new(data, os.time())
	emitter:encode()
	local encrypted = emitter:encrypt()
	
	self:emit("FUNC_CLOSURE", target, self:addConstant(encrypted), emitter.seed)
end

function SemanticCompiler:compileStatement(stmt: any)
	local tag = stmt.tag
	if tag == "LocalAssign" then
		for i, name in ipairs(stmt.names) do
			local valExpr = stmt.values[i]
			local reg = self.regCount
			if valExpr then
				self:compileExpression(valExpr, reg)
			else
				self:emit("DATA_NIL", reg)
			end
			self.locals[name] = reg
			self.regCount += 1
		end
	elseif tag == "LocalFunction" then
		local reg = self.regCount
		self.locals[stmt.name] = reg
		self.regCount += 1
		self:compileFunction(stmt.func, reg)
	elseif tag == "FunctionStat" then
		local reg = self.regCount
		self:compileFunction(stmt.func, reg)
		if #stmt.dotNames == 0 then
			local nameIdx = self:addConstant(stmt.name)
			self:emit("ENV_SET", reg, nameIdx)
		else
			-- Complex table sets (t.a.b = func)
			-- ... Simplified for now
		end
	elseif tag == "Assign" then
		for i, target in ipairs(stmt.targets) do
			local valExpr = stmt.values[i]
			if target.tag == "Name" then
				local reg = self.locals[target.name]
				if reg then
					self:compileExpression(valExpr, reg)
				else
					local nameIdx = self:addConstant(target.name)
					local valReg = self.regCount
					self:compileExpression(valExpr, valReg)
					self:emit("ENV_SET", valReg, nameIdx)
				end
			elseif target.tag == "Index" or target.tag == "FieldAccess" then
				local objReg = self.regCount
				self:compileExpression(target.object, objReg)
				self.regCount += 1
				local keyReg = self.regCount
				if target.tag == "FieldAccess" then
					local keyIdx = self:addConstant(target.field)
					self:emit("DATA_K", keyReg, keyIdx)
				else
					self:compileExpression(target.index, keyReg)
				end
				self.regCount += 1
				local valReg = self.regCount
				self:compileExpression(valExpr, valReg)
				self:emit("TABLE_SET", objReg, keyReg, valReg)
				self.regCount -= 2
			end
		end
	elseif tag == "Call" or tag == "MethodCall" then
		self:compileCall(stmt, self.regCount)
	elseif tag == "If" then
		self:compileIf(stmt)
	elseif tag == "While" then
		self:compileWhile(stmt)
	elseif tag == "Return" then
		local startReg = self.regCount
		for i, v in ipairs(stmt.values) do
			self:compileExpression(v, startReg + i - 1)
		end
		self:emit("FUNC_RET", startReg, #stmt.values)
	elseif tag == "NumericFor" then
		self:compileNumericFor(stmt)
	elseif tag == "GenericFor" then
		self:compileGenericFor(stmt)
	elseif tag == "Repeat" then
		self:compileRepeat(stmt)
	end
end

local BINOP_MAP = {
	["+"]="CALC_ADD", ["-"]="CALC_SUB", ["*"]="CALC_MUL", ["/"]="CALC_DIV", ["%"]="CALC_MOD",
	["=="]="GATE_EQ", ["<"]="GATE_LT", ["<="]="GATE_LE", ["~="]="GATE_NEQ", [">"]="GATE_GT", [">="]="GATE_GE",
	["and"]="LOGIC_AND", ["or"]="LOGIC_OR", [".."]="TABLE_SET" -- Dummy for now
}

local UNOP_MAP = {
	["not"]="LOGIC_NOT", ["-"]="CALC_SUB", ["#"]="TABLE_LEN"
}

function SemanticCompiler:compileExpression(expr: any, targetReg: number)
	local tag = expr.tag
	if tag == "Literal" then
		if expr.type == "nil" then
			self:emit("DATA_NIL", targetReg)
		elseif expr.type == "boolean" then
			self:emit("DATA_BOOL", targetReg, expr.value and 1 or 0)
		else
			local idx = self:addConstant(expr.value)
			self:emit("DATA_K", targetReg, idx)
		end
	elseif tag == "Name" then
		local reg = self.locals[expr.name]
		if reg then
			self:emit("DATA_SLOT", targetReg, reg)
		else
			local idx = self:addConstant(expr.name)
			self:emit("ENV_GET", targetReg, idx)
		end
	elseif tag == "BinOp" then
		local leftReg = targetReg
		local rightReg = self.regCount + 1
		self:compileExpression(expr.left, leftReg)
		local oldReg = self.regCount
		self.regCount = rightReg
		self:compileExpression(expr.right, rightReg)
		self.regCount = oldReg
		local op = BINOP_MAP[expr.op] or "SHADE_VOID"
		self:emit(op, targetReg, leftReg, rightReg)
	elseif tag == "UnOp" then
		local op = UNOP_MAP[expr.op] or "SHADE_VOID"
		local operandReg = self.regCount + 1
		local oldReg = self.regCount
		self.regCount = operandReg
		self:compileExpression(expr.operand, operandReg)
		self.regCount = oldReg
		if expr.op == "-" then
			-- Negation is SUB 0, x
			local zeroIdx = self:addConstant(0)
			local zeroReg = self.regCount + 2
			self:emit("DATA_K", zeroReg, zeroIdx)
			self:emit("CALC_SUB", targetReg, zeroReg, operandReg)
		else
			self:emit(op, targetReg, operandReg)
		end
	elseif tag == "Index" or tag == "FieldAccess" then
		local objReg = targetReg
		self:compileExpression(expr.object, objReg)
		local oldRegCount = self.regCount
		local keyReg = self.regCount + 1
		self.regCount = keyReg
		if tag == "FieldAccess" then
			local keyIdx = self:addConstant(expr.field)
			self:emit("DATA_K", keyReg, keyIdx)
		else
			self:compileExpression(expr.index, keyReg)
		end
		self:emit("TABLE_GET", targetReg, objReg, keyReg)
		self.regCount = oldRegCount
	elseif tag == "Call" or tag == "MethodCall" then
		self:compileCall(expr, targetReg)
	elseif tag == "Function" then
		self:compileFunction(expr, targetReg)
	elseif tag == "Table" then
		self:emit("TABLE_NEW", targetReg, #expr.fields)
		for i, field in ipairs(expr.fields) do
			local valReg = self.regCount + 1
			local oldReg = self.regCount
			self.regCount = valReg
			if field.tag == "ValueField" then
				self:compileExpression(field.value, valReg)
				local keyReg = self.regCount + 1
				self:emit("DATA_K", keyReg, self:addConstant(i))
				self:emit("TABLE_SET", targetReg, keyReg, valReg)
			end
			self.regCount = oldReg
		end
	end
end

function SemanticCompiler:compileCall(stmt: any, targetReg: number)
	local funcReg = targetReg
	if stmt.tag == "MethodCall" then
		self:compileExpression(stmt.object, funcReg)
		local oldRegCount = self.regCount
		local keyReg = self.regCount + 1
		self.regCount = keyReg
		self:emit("DATA_K", keyReg, self:addConstant(stmt.method))
		self:emit("TABLE_GET", funcReg, funcReg, keyReg) -- GET METHOD
		
		local startArgs = targetReg + 1
		self:compileExpression(stmt.object, startArgs) -- SELF
		for i, arg in ipairs(stmt.args) do
			self.regCount = startArgs + i
			self:compileExpression(arg, self.regCount)
		end
		self:emit("FUNC_CALL", funcReg, #stmt.args + 1, 1)
		self.regCount = oldRegCount
	else
		self:compileExpression(stmt.func, funcReg)
		local startArgs = targetReg + 1
		local oldReg = self.regCount
		for i, arg in ipairs(stmt.args) do
			self.regCount = startArgs + i - 1
			self:compileExpression(arg, self.regCount)
		end
		self.regCount = oldReg
		self:emit("FUNC_CALL", funcReg, #stmt.args, 1)
	end
end

function SemanticCompiler:compileIf(stmt: any)
	local jumpPoints = {}
	
	-- Compile IF
	local condReg = self.regCount
	self:compileExpression(stmt.cond, condReg)
	local jumpIdx = #self.ir + 1
	self:emit("ROUTE_IFNOT", condReg, 0)
	
	self:compileBlock(stmt.body)
	
	if #stmt.elseifs > 0 or stmt.elseBody then
		table.insert(jumpPoints, #self.ir + 1)
		self:emit("ROUTE_GOTO", 0)
	end
	
	-- IFNOT jumps here if IF condition is false
	self.ir[jumpIdx].b = #self.ir
	
	-- Compile ELSEIFs
	for _, elseifStmt in ipairs(stmt.elseifs) do
		self:compileExpression(elseifStmt.cond, condReg)
		local nextJumpIdx = #self.ir + 1
		self:emit("ROUTE_IFNOT", condReg, 0)
		
		self:compileBlock(elseifStmt.body)
		
		if elseifStmt ~= stmt.elseifs[#stmt.elseifs] or stmt.elseBody then
			table.insert(jumpPoints, #self.ir + 1)
			self:emit("ROUTE_GOTO", 0)
		end
		
		self.ir[nextJumpIdx].b = #self.ir
	end
	
	-- Compile ELSE
	if stmt.elseBody then
		self:compileBlock(stmt.elseBody)
	end
	
	-- Patch all GOTOs to end
	local endPos = #self.ir
	for _, idx in ipairs(jumpPoints) do
		self.ir[idx].a = endPos
	end
end

function SemanticCompiler:compileWhile(stmt: any)
	local startPos = #self.ir
	local condReg = self.regCount
	self:compileExpression(stmt.cond, condReg)
	local jumpIdx = #self.ir + 1
	self:emit("ROUTE_IFNOT", condReg, 0)
	
	self:compileBlock(stmt.body)
	self:emit("ROUTE_GOTO", startPos)
	self.ir[jumpIdx].b = #self.ir
end

function SemanticCompiler:compileRepeat(stmt: any)
	local startPos = #self.ir
	self:compileBlock(stmt.body)
	
	local condReg = self.regCount
	self:compileExpression(stmt.cond, condReg)
	self:emit("ROUTE_IFNOT", condReg, startPos)
end

function SemanticCompiler:compileNumericFor(stmt: any)
	local oldRegCount = self.regCount
	
	local startReg = self.regCount; self.regCount += 1
	local limitReg = self.regCount; self.regCount += 1
	local stepReg = self.regCount; self.regCount += 1
	local varReg = self.regCount; self.regCount += 1
	
	self:compileExpression(stmt.start, startReg)
	self:compileExpression(stmt.limit, limitReg)
	if stmt.step then
		self:compileExpression(stmt.step, stepReg)
	else
		self:emit("DATA_K", stepReg, self:addConstant(1))
	end
	
	-- var = start
	self:emit("DATA_SLOT", varReg, startReg)
	self.locals[stmt.var] = varReg
	
	local startPos = #self.ir
	
	-- Condition check (simplified: assuming step > 0)
	local condReg = self.regCount
	self:emit("GATE_LE", condReg, varReg, limitReg)
	local jumpIdx = #self.ir + 1
	self:emit("ROUTE_IFNOT", condReg, 0)
	
	self:compileBlock(stmt.body)
	
	-- Increment
	self:emit("CALC_ADD", varReg, varReg, stepReg)
	self:emit("ROUTE_GOTO", startPos)
	
	self.ir[jumpIdx].b = #self.ir
	self.regCount = oldRegCount
end

function SemanticCompiler:compileGenericFor(stmt: any)
	-- Generic For: for vars in iterators do ... end
	-- iterator, state, var = iterators...
	local oldRegCount = self.regCount
	
	local iterReg = self.regCount; self.regCount += 1
	local stateReg = self.regCount; self.regCount += 1
	local nextVarReg = self.regCount; self.regCount += 1
	
	-- Evaluate iterators (usually one or more expressions)
	for i, expr in ipairs(stmt.iterators) do
		local r = (i == 1 and iterReg) or (i == 2 and stateReg) or (i == 3 and nextVarReg)
		if r then
			self:compileExpression(expr, r)
		end
	end
	
	local loopVarStart = self.regCount
	for i, name in ipairs(stmt.names) do
		self.locals[name] = self.regCount
		self.regCount += 1
	end
	
	local startPos = #self.ir
	
	-- Call iterator: vars = iter(state, nextVar)
	-- Pass state and nextVar as args
	local arg1 = self.regCount
	self:emit("DATA_SLOT", arg1, stateReg)
	local arg2 = arg1 + 1
	self:emit("DATA_SLOT", arg2, nextVarReg)
	
	-- Call
	self:emit("FUNC_CALL", iterReg, 2, #stmt.names)
	
	-- After call, results are in iterReg, iterReg+1...
	-- We need to move them to loop variables
	for i=1, #stmt.names do
		self:emit("DATA_SLOT", loopVarStart + i - 1, iterReg + i - 1)
	end
	
	-- nextVar = firstResult
	self:emit("DATA_SLOT", nextVarReg, loopVarStart)
	
	-- if nextVar == nil then break
	local condReg = self.regCount
	self:emit("GATE_EQ", condReg, nextVarReg, self:addConstant(nil)) -- DATA_NIL check
	local jumpIdx = #self.ir + 1
	self:emit("ROUTE_IF", condReg, 0) -- Skip if nil
	
	self:compileBlock(stmt.body)
	self:emit("ROUTE_GOTO", startPos)
	
	self.ir[jumpIdx].b = #self.ir
	self.regCount = oldRegCount
end

------------------------------------------------------------------------
-- MODULE 4: BYTECODE EMITTER
------------------------------------------------------------------------
BytecodeEmitter = {}
BytecodeEmitter.__index = BytecodeEmitter

function BytecodeEmitter.new(irData: any, seed: number)
	return setmetatable({
		ir = irData.ir,
		constants = irData.constants,
		seed = seed or os.time(),
		opMap = {},
		bytecode = {},
	}, BytecodeEmitter)
end

function BytecodeEmitter:generateOpMap()
	math.randomseed(self.seed)
	local available = {}
	for i = 0, 255 do table.insert(available, i) end
	for _, opName in ipairs(ALIEN_OPS) do
		local idx = math.random(1, #available)
		local val = table.remove(available, idx)
		self.opMap[opName] = val
	end
end

function BytecodeEmitter:encode()
	self:generateOpMap()
	for _, inst in ipairs(self.ir) do
		local opcode = self.opMap[inst.op]
		table.insert(self.bytecode, opcode)
		table.insert(self.bytecode, inst.a or 0)
		table.insert(self.bytecode, inst.b or 0)
		table.insert(self.bytecode, inst.c or 0)
	end
	return self.bytecode
end

function BytecodeEmitter:encrypt()
	local encrypted = {}
	local vctx = self.seed % 65536
	local roll = self.seed % 256
	
	for i = 1, #self.bytecode, 4 do
		local op = self.bytecode[i]
		local a = self.bytecode[i+1]
		local b = self.bytecode[i+2]
		local c = self.bytecode[i+3]
		
		-- Opcode Morphing in reverse: 
		-- VM expects: morphed = op ^ (vctx % 256). We want morphed == op.
		-- So we store op_to_store = op ^ (vctx % 256).
		local op_to_store = bit32.bxor(op, vctx % 256)
		local raw = {op_to_store, a, b, c}
		
		for j=1, 4 do
			local pc_idx = i + j - 1
			local key = bit32.bxor(bit32.bxor(roll, pc_idx % 256), vctx % 256)
			local enc = bit32.bxor(raw[j], key)
			table.insert(encrypted, enc)
			roll = (roll + raw[j]) % 256
		end
		
		-- Context Mutation (Nexus Flux - Simplified for jumps)
		-- vctx = (vctx * 31 + bit32.bxor(op_to_store, a + b + c)) % 65536
		vctx = bit32.bxor(vctx, i) % 65536
	end
	
	return encrypted
end

------------------------------------------------------------------------
-- MODULE 5: RUNTIME GENERATOR
------------------------------------------------------------------------
RuntimeGenerator = {}
RuntimeGenerator.__index = RuntimeGenerator

function RuntimeGenerator.new(bytecode: {number}, constants: {any}, opMap: {any}, seed: number)
	return setmetatable({
		bytecode = bytecode,
		constants = constants,
		opMap = opMap,
		seed = seed,
	}, RuntimeGenerator)
end

function RuntimeGenerator:generate(): string
	local function serialize(v: any): string
		if type(v) == "string" then return string.format("%q", v)
		elseif type(v) == "number" then return tostring(v)
		elseif type(v) == "boolean" then return tostring(v)
		elseif type(v) == "table" then
			local b = {}
			for i, x in ipairs(v) do table.insert(b, serialize(x)) end
			return "{" .. table.concat(b, ",") .. "}"
		else return "nil" end
	end

	local bcStr = "{" .. table.concat(self.bytecode, ",") .. "}"
	local constTable = {}
	for _, c in ipairs(self.constants) do
		table.insert(constTable, serialize(c))
	end
	local constStr = "{" .. table.concat(constTable, ",") .. "}"
	
	local revMap = {}
	for name, val in pairs(self.opMap) do revMap[val] = name end
	
	-- Alien VM Loop Template
	local template = [[
local _ENV = getfenv()
local _G = _G
local _DATA = {BC}
local _CONST = {CONST}
local _SEED = {SEED}

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
	{HANDLERS_RECURSIVE}

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
]]

	local h_list = {}
	local function add_h(opVal, body)
		table.insert(h_list, string.format("handlers[%d] = function(a, b, c) %s end", opVal, body))
	end

	for val, name in pairs(revMap) do
		if name == "DATA_K" then add_h(val, "regs[a] = _CONST[b + 1]")
		elseif name == "DATA_SLOT" then add_h(val, "regs[a] = regs[b]")
		elseif name == "DATA_BOOL" then add_h(val, "regs[a] = (b == 1)")
		elseif name == "DATA_NIL" then add_h(val, "regs[a] = nil")
		elseif name == "CALC_ADD" then add_h(val, "regs[a] = regs[b] + regs[c]")
		elseif name == "CALC_SUB" then add_h(val, "regs[a] = regs[b] - regs[c]")
		elseif name == "CALC_MUL" then add_h(val, "regs[a] = regs[b] * regs[c]")
		elseif name == "CALC_DIV" then add_h(val, "regs[a] = regs[b] / regs[c]")
		elseif name == "CALC_MOD" then add_h(val, "regs[a] = regs[b] % regs[c]")
		elseif name == "GATE_EQ" then add_h(val, "regs[a] = (regs[b] == regs[c])")
		elseif name == "GATE_LT" then add_h(val, "regs[a] = (regs[b] < regs[c])")
		elseif name == "GATE_LE" then add_h(val, "regs[a] = (regs[b] <= regs[c])")
		elseif name == "GATE_GT" then add_h(val, "regs[a] = (regs[b] > regs[c])")
		elseif name == "GATE_GE" then add_h(val, "regs[a] = (regs[b] >= regs[c])")
		elseif name == "GATE_NEQ" then add_h(val, "regs[a] = (regs[b] ~= regs[c])")
		elseif name == "LOGIC_AND" then add_h(val, "regs[a] = regs[b] and regs[c]")
		elseif name == "LOGIC_OR" then add_h(val, "regs[a] = regs[b] or regs[c]")
		elseif name == "LOGIC_NOT" then add_h(val, "regs[a] = not regs[b]")
		elseif name == "TABLE_LEN" then add_h(val, "regs[a] = #regs[b]")
		elseif name == "ENV_GET" then add_h(val, "regs[a] = env[_CONST[b+1]] or _G[_CONST[b+1]]")
		elseif name == "ENV_SET" then add_h(val, "env[_CONST[b+1]] = regs[a]")
		elseif name == "TABLE_NEW" then add_h(val, "regs[a] = {}")
		elseif name == "TABLE_GET" then add_h(val, "regs[a] = regs[b][regs[c]]")
		elseif name == "TABLE_SET" then add_h(val, "regs[a][regs[b]] = regs[c]")
		elseif name == "FUNC_CALL" then add_h(val, [[
			local func = regs[a]
			local args = {}
			for i=1, b do args[i] = regs[a + i] end
			local results = { func(table.unpack(args)) }
			for i=1, c do regs[a + i - 1] = results[i] end
		]])
		elseif name == "FUNC_RET" then add_h(val, "return 'HALT'")
		elseif name == "ROUTE_GOTO" then add_h(val, "pc = a * 4 + 1")
		elseif name == "ROUTE_IFNOT" then add_h(val, "if not regs[a] then pc = b * 4 + 1 end")
		elseif name == "FUNC_CLOSURE" then add_h(val, [[
			local sub_bc = _CONST[b + 1]
			local sub_seed = c
			regs[a] = function(...) return _EXEC_VM(sub_bc, sub_seed, { ... }, env) end
		]])
		end
	end

	local final_h = table.concat(h_list, "\n"):gsub("%%%%", "%%%%%%%%")
	return template:gsub("{BC}", bcStr):gsub("{CONST}", constStr):gsub("{SEED}", tostring(self.seed)):gsub("{HANDLERS_RECURSIVE}", function() return final_h end)
end

------------------------------------------------------------------------
-- MODULE 6: BUILD ORCHESTRATOR
------------------------------------------------------------------------
local function main()
	local args = process.args
	if #args < 2 then
		print("Usage: lune run phantom_compiler.luau <input.lua> <output.lua>")
		return
	end

	local inputPath = args[1]
	local outputPath = args[2]

	local source = fs.readFile(inputPath)
	print("[+] Lexing...")
	local lexer = Lexer.new(source)
	local tokens = lexer:tokenize()

	print("[+] Parsing...")
	local parser = Parser.new(tokens)
	local ast = parser:parse()

	print("[+] Compiling to Alien IR...")
	local compiler = SemanticCompiler.new()
	local irData = compiler:compile(ast)

	print("[+] Emitting Bytecode...")
	local seed = os.time()
	local emitter = BytecodeEmitter.new(irData, seed)
	emitter:encode()
	local encrypted = emitter:encrypt()

	print("[+] Generating VM Runtime...")
	local gen = RuntimeGenerator.new(encrypted, irData.constants, emitter.opMap, seed)
	local outputCode = gen:generate()

	fs.writeFile(outputPath, "-- [[ Phantom Nexus v1.0 ]]\n" .. outputCode)
	print("[*] Build Successful! -> " .. outputPath)
end

main()
