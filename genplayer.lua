local f = io.open("./player_conf.lua", "w+")
local d = 'return {\n'

for	i = 1, 10 do
	d = d .."	["..tostring(i).."] = {\n"
	d = d .."		name=".."'anmeng"..tostring(i).."',\n"
	d = d .."		password = 'password'},\n"
end
d = d .."}"
f:write(d)
f:close()
print(d)
print("success")