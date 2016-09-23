package.path = package.path..";./../src/?.lua"
local skynet = require "skynet"
require "skynet.manager"
local json = require "dkjson"
local home_conf = require "home_conf"
local db = require "db"
local uniqueid = require "uniqueid"
local logger = require "logger"

local gate = ...
local homes = {}
local cmd = {}
local home = {}
local tokens = {}

local today
local subscribers = {}
local contract_command_list = {}
local contract



home.__index = home
function home.new()
	local t = setmetatable({}, home)
	local attr = {}
	attr.userid = 0
	attr.homelevel = 1
	attr.food = 0
	attr.wood = 0	
	attr.gold = 0
	attr.stone = 0
	attr.diamond = 0
	attr.techlevel = 1
	
	attr.seeking = {
		food = 0,
		wood = 0,
		gold = 0,
		stone = 0,
	}
	
	attr.seeked = {
		food = 0,
		wood = 0,
		gold = 0,
		stone = 0,
	}
	
	attr.trade = {
		food = 0,
		wood = 0,
		gold = 0,
		stone = 0,
	}
	
	attr.changenametimes = 1
	
	attr.name = 'null'
	t.attr = attr
	
	--[[attr.base = {
	addfood = 0,
	addwood = 0,
	addgold = 0,
	addstone = 0,
	
	}]]
	
	attr.tech = {
		food = 1,
		wood = 1,
		gold = 1,
		stone = 1,
	}
	
	
	t.homeconf = home_conf.home[attr.homelevel]
	t.seekingconf = home_conf.seeking[attr.homelevel]
	t.savetime = 0
	t.attrchanged = true
	t.msg = {}
	t.attrchangedtime = 0
	return t
end

local function check(t)
	local c = {food = 'food', wood = 'wood', gold = 'gold', stone = 'stone'}
	if c[t] then return true else return false end 
end

function home:onfirstcreate()
	local base = self.attr.base
	for k, v in pairs(base) do
		base[k] = math.random(1, 10)
	end
end

function home:onload()
	local attr = self.attr
	self.homeconf = home_conf.home[attr.homelevel]
	self.seekingconf = home_conf.seeking[attr.homelevel]
end

function home:load()
	local attr = db.get('player.'..self.attr.userid)
	if attr then
		local a = self.attr
		for	k, v in pairs(attr) do
			a[k] = v
		end
		logger.normal({id = a.userid, 'load'})
		self:onload()
		return true
	else
		--self:onfirstcreate()
	end
end

function home:save()
	db.set('player.'..self.attr.userid, self.attr)
end

function home:checkresource(p)
	local attr = self.attr
	if attr.food >= p.food and attr.wood >= p.wood and attr.gold >= p.gold and attr.stone >= p.stone then 
		return true
	else
		return false
	end
end

function home:mdecresource(p, s)
	local attr = self.attr
	if attr.diamond >= p.diamond and attr.food >= p.food and attr.wood >= p.wood and attr.gold >= p.gold and attr.stone >= p.stone then 
		attr.food = attr.food - p.food
		attr.wood = attr.wood - p.wood
		attr.gold = attr.gold - p.gold
		attr.stone = attr.stone - p.stone
		attr.diamond = attr.diamond - p.diamond
		logger.normal({id = attr.userid, t = "mdecresource", s = s, attr = p})
		return true
	else
		return false
	end	
end

local cincresource = {
	food = {t = 'food', max = 'maxfood'},
	wood = {t = 'wood', max = 'maxwood'},
	gold = {t = 'gold', max = 'maxgold'},
	stone = {t = 'stone', max = 'maxstone'},
}

function home:incresource(t, c, s)
	local attr = self.attr
	if not check(t) then return false end
	if attr[t] + c <= self.homeconf["max"..t] then
		attr[t]= attr[t] + c
		if c >= 100 then 
			logger.normal({t = 'incresource', k = t, s = s, l = c, id = attr.userid})
		end
		return true
	else
		return false
	end	
end

function home:decresource(t, c, s)
	local attr = self.attr
	if not check(t) then return false end 
	if attr[t] >= c then 
		attr[t] = attr[t] - c
		if c >= 100 then 
			logger.normal({t = 'decresource', k = t, s = s, l = c, id = attr.userid})
		end
		return true
	else
		return false 
	end
end

function home:canwork(c)
	local p = 0 
	for	k, v in pairs(self.attr.seeking) do
		p = p + v
	end
	return self.attr.homelevel > p 
end

function home:homeupgrade()
	local attr = self.attr
	local conf = self.homeconf
	if conf then	
		if self:mdecresource(conf) then
			attr.homelevel = attr.homelevel + 1
			self.homeconf = home_conf.home[attr.homelevel]
			self.seekingconf = home_conf.seeking[attr.homelevel]
			logger.normal({s = 'homeupgrade', id = attr.userid, l = attr.homelevel})
			return {ret = true}
		else
			return {ret = false, msg = 'resource not encogh'}
		end
	else
		return {ret = false, msg = 'max level'}
	end	
end

function home:techupgrade()
	local attr = self.attr
	if conf then
		if self:mdecresource(conf) then
			attr.techlevel = attr.techlevel + 1 
			logger.normal({s = 'techupgrade', id = attr.userid, l = attr.homelevel})
			return {ret = true}
		else
			return {ret = false, msg = 'resource not encogh'}
		end
	else
		return {ret = false, msg = 'max level'}
	end	
end

local ctech = {
		food = 'seekingfoodlevel',
		wood = 'seekingwoodlevel',
		gold = 'seekinggoldlevel',
		stone = 'seekingstonelevel',
}

function home:techadd(t)
	local p = ctech[t]
	if not p then return false end 
	local attr = self.attr.tech

	local t = 0
	for	k, v in pairs(attr) do
		t = t + v
	end
	
	if t < self.attr.techlevel then
		attr[p] = attr[p] + 1
		logger.normal({s = 'techadd', t = 't', l = attr[p], id = attr.userid})
		return true
	end
	
	return false
end

function home:techsub(t)
	local p = ctech[t]
	if not p then return false end 
	local attr = self.attr.tech
	if attr[p] > 0 then 
		attr[p] = attr[p] - 1
		logger.normal({s = 'techsub', t = 't', l = attr[p], id = attr.userid})
		return true
	end
	
	return false
end

function home:send(t, unique)
	if unique then 
		for	k, v in pairs(self.msg) do
			if v.id == t.id then
				k = nil
			end
		end
	end
	table.insert(self.msg, t)
end

function home:seekingresource(t)
	if not check(t) then return false end
	if self:canwork(1) then 	
		self.attr.seeking[t] = self.attr.seeking[t] + 1
		logger.normal({s = 'seekingresource', t = t, id = self.attr.userid})
		return true
	else
		return false
	end
end

function home:fullresource(a, b)
	return self.attr[a] >= self.homeconf[b]
end

function home:updateseekingresource(t)
	if not check(t) then return false end
	if home.fullresource(self, t, "max"..t) then return false end
	local attr = self.attr
	local seeked = attr.seeked
	local seeking = attr.seeking
	local get = seeked[t]
	local f = seeking[t]
	if f > 0 and get >= f then 
		seeked[t] = get - f
		self:incresource(t, f, 'seekingresource')
		self.attrchanged = true
		return
	end
	if f > 0 then 
		local m = math.random(1, self.seekingconf[t] - attr.tech[t] * 2)
		--print(m, t)
		if m == 1 then
			seeked[t] = math.random(attr.homelevel * 100, attr.homelevel * 1000)
			logger.normal({id = attr.userid, s = "seekedresource", t = s, l = seeked[t]})
		end
	end
end

function home:stopseekingresource(t, c)
	if not check(t) then return false end
	local attr = self.attr
	local seeking = attr.seeking
	if seeking[t] >= c then 
		seeking[t] = seeking[t] - c
		logger.normal({id = attr.userid, s = 'stopseekingresource', t = t, l = seeking[t]})
		return true
	end
	
	return false
end

function home:update(now)
	self.savetime = self.savetime + 1 
	if self.savetime >= 100 then 
		self.savetime = 0
		self:save()
		logger.normal({id = self.attr.userid, s = 'save'})
	end
	
	self.attrchangedtime = self.attrchangedtime + 1
	if self.attrchangedtime > 5 and self.attrchanged then 
		--self:send(self:getattr(), true)
		self.attrchangedtime = 0
		self.attrchanged = false
	end
	
	self:updateseekingresource('food')
	self:updateseekingresource('wood')
	self:updateseekingresource('gold')
	self:updateseekingresource('stone')
end

function home:getattr()
	return {attr = self.attr}
end

function home:waitmsg()
	while #self.msg == 0 do
		skynet.sleep(10)
	end	
	return {count = #self.msg}
end

function home:changename(name)
	local attr = self.attr
	if attr.changenametimes > 0 then 
		attr.changenametimes = attr.changenametimes - 1
		attr.name = name
		logger.normal({id = attr.userid, s = 'changename', t = name})
		return true
	end
	
	return false
end

function home:addchangenametime()
	self.attr.changenametimes = self.attr.changenametimes + 1 
	return true
end

function home:selling_contract(t, count, price)
	if not check(t) then return false end 
	local attr = self.attr
	if self:decresource(t, count, 'selling_contract') then
		return skynet.call("trade", "lua", "selling_contract", t, count, price, attr.userid)	
	end
	return false
end

function home:forwards_selling_contract(t, count, price, date)
	if not check(t) then return false end 
	local attr = self.attr
	return skynet.call("trade", "lua", "forwards_selling_contract", t, count, price, date, attr.userid)
end

function home:buying_contract(id)
	local c = skynet.call("trade", "lua", "get_contract", id)
	if c then
		if self.attr.gold >= c.p and skynet.call("trade", "lua", "buying_contract", id, h.attr.userid) then 	
			return self:decresource("gold", c.p, "buying_contract")
		end
	end
	return false
end

function home:trade_subscribe()
	subscribers[self.attr.userid] = self.attr.userid
	return true
end

function home:trade_unsubscribe()
	subscribers[self.attr.userid] = nil
	return true
end

function home:trade_publish(i, c)
	self:send({id = "trade_publish", index = i, ret = c})
end

function home:trade_get_contract(lstart, lend)
	local r = {}
	if lstart <= 0 then return false end 
	if lend - lstart > 20 then lend = lstart + 20 end --最多20
	if lend > #contract_command_list then lend = #contract_command_list end
	for	i = lstart, lend do
		local t = contract_command_list[i]
		if t then 
			self:trade_publish(i, t)
		else
			break
		end
	end
	return lend - lstart + 1
end

function cmd.trade_publish(c)
	table.insert(contract_command_list, c)
	local i = #contract_command_list
	for	k, v in pairs(subscribers) do 
		v:publish(i, c)
	end
end

function cmd.selling_contract(h, p)
	return {ret = h:selling_contract(p.type, p.count, p.price)}
end

function cmd.forwards_selling_contract(h, p)
	return {ret = h:forwards_selling_contract(p.type, p.count, p.price, p.date)}
end

function cmd.buying_contract(h, p)
	return {ret = h:buying_contract(p.order)}
end

function cmd.cancal_contract(h, p)
	return {ret = skynet.call("trade", "lua", "cancal_contract", p.order, h.attr.userid, "user")}
end

function cmd.resell_forwards_selling_contract(h, p)
	return {ret = skynet.call("trade", "lua", "resell_forwards_selling_contract", p.order, p.price, h.attr.userid)}	
end

function cmd.trade_get_contract(h, p)
	return {ret = h:trade_get_contract(p.s, p.e)}
end

function cmd.seekingresource(h, p)
	return {ret = h:seekingresource(p.type)}
end

function cmd.stopseekingresource(h, p)
	return {ret = h:stopseekingresource(p.type, 1)}
end

function cmd.getattr(h)
	return h:getattr()
end

function cmd.homeupgrade(h)
	return {ret = h:homeupgrade()}
end

function cmd.changename(h, p)
	if h:changename(p.name) then 
		return {ret = true}
	else
		return {ret = false}
	end
end

function cmd.login(userid)
	local token = uniqueid()
	local h = homes[userid]
	if not h then
		h = home.new()
		h.attr.userid = userid
		h:load()
		homes[userid] = h
	end
	tokens[token] = userid
	return token
end

local failret = '{"ret" : false}'
local failret2 = '{"ret1" : false}'
function cmd.client(body)
	body = json.decode(body)
	if not body then return failret end
	local token, c = body.token, body.id
	local userid = tokens[token]
	if not (c and userid) then return failret2 end
	tokens[token] = nil
	local h = homes[userid]
	if not h then cmd.login(userid) h = homes[body.userid] end
	
	local result
	if cmd[c] then 
		result = cmd[c](h, body)
	else
		result = {ret = false}
	end
	
	result.id = c
	
	
	local msg
	if #h.msg == 0 then 
		msg = {}
	else
		msg = h.msg
		h.msg = {}
	end
	table.insert(msg, result)
	
	local t = {}
	token = uniqueid()
	t.token = token
	tokens[token] = userid
	t.ret = msg
	local s = json.encode(t)
	return s
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = cmd[command]
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.fork(function()
		while true do
		local now = skynet.now() * 10
		today = os.time()
		for k, v in pairs(homes) do
			v:update(now)
		end
		skynet.sleep(100)
		end
	end)
end)