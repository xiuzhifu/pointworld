package.path = package.path..";./../src/?.lua"
local skynet = require "skynet"
require "skynet.manager"
local uniqueid = require "uniqueid"
local redis = require "redis"
local json = require "dkjson"
local logger = require "logger"
logger.setloggername('trade')

local db 
local m = {}
local conf = {
	host = "127.0.0.1" ,
	port = 8888 ,
}
local guidingprice = {
	food = 0,
	wood = 0,
	gold = 0,
	stone = 0,
}
local homes
local contract
local dealcontract = {}
local contract_command_list = {}
local function publish(c)
	for	k, v in ipairs(homes) do
		skynet.call(v, "lua", "trade_publish", c)
	end
end

local function contract_command_list_add(c)
	table.insert(contract_command_list, c)
	publish(c)
end



local changed = true

function m.buying_contract(id, buyer)
	local c = contract[id]
	if c then
		contract[id] = nil
		changed = true
		c.b = buyer
		c.ss = "deal"
		dealcontract[id] = c
		contract_command_list_add({t = 'bebuyed', id})
		logger.normal(c)
		return true
	else
		return false
	end
end

function m.cancal_contract(id, seller, r)
	local c = contract[id] 
	if c and c.s == seller then 
		contract[id] = nil
		changed = true
		c.ss = 'cancal'..r
		contract_command_list_add({t = 'cancal', id})
		logger.normal(c)
		return true
	else
		return false 
	end
end

function m.selling_contract(resource, count, price, seller)
	local c = {id = uniqueid(), r = resource,  c = count, p = price, s = seller, t = "now"}
	local s = json.encode(c)
	changed = true
	db:set(c.id, s)
	contract[c.id] = c
	contract_command_list_add(c)
	logger.normal(c)
	return true 
end

function m.forwards_selling_contract(resource, count, price, date, seller)
	local c = {id = uniqueid(), r = resource,  c = count, p = price, s = seller, d = date, g = seller, t = "forwards"}
	contract[c.id] = c
	local s = json.encode(c)
	changed = true
	db:set(c.id, s)
	contract_command_list_add(c)
	logger.normal(c)
	return true
end

function m.resell_forwards_selling_contract(id, price, seller)
	local c = dealcontract[id]
	if c and c.b == seller then
		local t = {id = uniqueid(), r = c.r,  c = c.c, p = c.p, s = c.s, d = c.d, g = seller, t = "forwards"}
		contract[c.id] = t
		dealcontract[id] = nil
		local s = json.encode(t)
		changed = true
		contract_command_list_add(c)
		logger.normal(t)
		logger.normal({t = "resell", from = c.id, to = t.id})
		return true
	end
	return false
end

function m.get_contract(id)
	local c = contract[id]
	if c then 
		return c 
	else
		return nil
	end
end

function m.get_all_contract()
	if changed then 
		changed = false
		return contract_s	
	end
	return nil
end

local function handle_contract()
	local today = os.time()
	for k, v in pairs(dealcontract) do
		if v.t == 'now' then 
			skynet.call("homemgr", "lua", "callhome", v.b, "tradeincresource", v.r, r.c)
			skynet.call("homemgr", "lua", "callhome", v.s, "tradeincresource", "gold", r.p)
			v = nil
		end
	end
end

local function handle_forwards_contract()
	for k, v in pairs(dealcontract) do
		if v.t == 'forwards' then 
			if not v.sendgold then 
				skynet.call("homemgr", "lua", "callhome", v.g, "tradeincresource", "gold", r.p)
				v.sendgold = true
			end
			if today >= v.d  then
				if v.b then 
					skynet.call("homemgr", "lua", "callhome", v.b, "tradeincresource", v.r, r.c)
					skynet.call("homemgr", "lua", "callhome", v.s, "tradedecresource", v.r, r.c)
				else
					m.cancal_contract(v.id, v.s, 'due')
				end
			end
		end
	end
end

local function reload()
	contract = {}
	local keys = db:keys("", "", 10000000)
	
	for	k, v  in pairs(keys) do
		contract[v] = json.decode(db:get(v))
		contract_command_list_add(contract[v])
	end
end

skynet.start(function()
	homes = skynet.call("homemgr", "lua", "gethomes")
	db = redis.connect(conf)
	reload()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = m[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.fork(function()
		while true do
			handle_contract()
			skynet.sleep(1)
		end
	end)
	
	skynet.fork(function()
		while true do
			handle_forwards_contract()
			skynet.sleep(1)
		end
	end)
	skynet.register "trade"
end)