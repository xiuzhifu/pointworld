local skynet = require "skynet"
skynet.start(function()
	skynet.error("init service start")
	skynet.error("Init service end")	
	skynet.exit()
end)