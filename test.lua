local t = {}
local g = 0
b = {}
for	i= 0, 100 do
	b[i] = 0
end
math.randomseed(os.time())
for j = 1, 100000 do
for	i = 1, 100 do
	local j = math.random(1, 100)
	if j == 10 then g = g + 1 end
end
b[g] = b[g] + 1
g = 0


end

for	k, v in pairs(b) do
	if v > 0 then 
	print(k, v)
	end
end

