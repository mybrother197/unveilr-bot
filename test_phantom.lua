local a = 10
local b = 20
local c = a + b
print("Result of a + b: ", c)

local function test(x)
	if x > 15 then
		print(x, "is greater than 15")
	else
		print(x, "is less than or equal to 15")
	end
end

test(c)
test(a)

local t = {1, 2, 3}
print("Table element 1:", t[1])
print("Done!")
