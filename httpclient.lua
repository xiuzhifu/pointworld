local http = require "socket.http"
local socket = require "socket"
local ltn12 = require "ltn12"
local json = require "dkjson"
local player_conf = require "player_conf"
local cfg = (require "home_conf").home

local function send_request(s, p)
	if p.token then s.token = p.token end
	s = json.encode(s)
	print(s)
	local t = {}
	local url = "http://127.0.0.1:8080/"
	if p.gate then 
		url = url.."?gate="..p.gate
	end
	local r 
	while true do
		r = nil
		http.request{
		url = url,
		  method = "POST",  
		  headers =   
		  {  
			["Content-Type"] = "application/x-www-form-urlencoded",  
			["Content-Length"] = #s,  
		  },  
		  source = ltn12.source.string(s),  
		  sink = ltn12.sink.table(t)  
		}
	
		r = table.concat(t)
		if r and r ~= "" then break end
	end
	print("r", r)
	local c = json.decode(r)
	if c and c.token then p.token = c.token else p.token = nil end
	return c or {}
end

local function logic(p)
	r = send_request({id = "getattr"}, p)
	local attr 
	for k, v in pairs(r.ret) do
		if v.id == "getattr" then 
			attr = v.attr
			break
		end
	end
	local c = cfg[attr.homelevel]
	if attr.food < c.maxfood then 
		send_request({id = "stopseekingresource", type = "food"}, p)
		send_request({id = "stopseekingresource", type = "wood"}, p)
		send_request({id = "stopseekingresource", type = "gold"}, p)
		send_request({id = "stopseekingresource", type = "stone"}, p)
		send_request({id = "seekingresource", type = "food"}, p)
	else 
		send_request({id = "stopseekingresource", type = "food"}, p)
		send_request({id = "stopseekingresource", type = "wood"}, p)
		send_request({id = "stopseekingresource", type = "gold"}, p)
		send_request({id = "stopseekingresource", type = "stone"}, p)
		send_request({id = "seekingresource", type = "wood"}, p)
	end
	print("name: "..attr.name.." homelevel: "..attr.homelevel.." food:"..attr.food.." maxfood: "..c.maxfood, "wood:"..attr.wood.." maxwood: "..c.maxwood)
	if attr.food == c.maxfood and attr.wood == c.maxwood then 
		send_request({id = "homeupgrade"}, p)
	end
	
	send_request({id = "selling_contract", type = "food", count = 1, price = 100}, p)
	send_request({id = "forwards_selling_contract", type = "food", count = 1, price = 100, date = os.time()}, p)
	send_request({id = "get_all_contract"}, p)
	socket.sleep(1)
end

local r 
while true do
	for	k, v in pairs(player_conf) do
		if not v.logined then 
			r = send_request({id = "login_auth", username = v.name, password = v.password}, v)
			if not r.token then 
				r = send_request({id = "login_register", username= v.name, password = v.password, email = "kk@qq.com"}, v)
				if r.ret == "true" then 
					r = send_request({id = "login_auth", username = v.name, password = v.password}, v)
					if not r.token then 
						print("register account error")
						exit(1)
					end
				end
			end
			v.token = r.token
			v.gate = r.gate
			send_request({id = "changename", name = v.name}, v)
			v.logined = true
		else
			logic(v)
		end
	end
end











gate = r.gate
while true do

end





