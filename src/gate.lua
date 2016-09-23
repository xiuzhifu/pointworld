package.path = package.path..";./../src/?.lua"
local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local json = require "dkjson"
local auth
local homes 

local connection = {}

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_, id)
		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		print(url, body)
		if code and body then
			if code ~= 200 then
				response(id, code)
			else
				local result = ""

				local path, query = urllib.parse(url)
				if query ~= '' then
					local q = urllib.parse_query(query)
					local h = homes[tonumber(q.gate)]
					if h then 
						result = skynet.call(h, "lua", "client", body)
					else
						result = "false"
					end
				else
					result = skynet.call(auth, "lua", body)
				end
				print(result)
				response(id, code, result.."\n", {["Access-Control-Allow-Origin"] = "*"})
				socket.close(id)
			end
		else
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
	end)
	homes = skynet.call("homemgr", "lua", "gethomes")
	auth = skynet.newservice("account_auth")
end)
