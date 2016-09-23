local index = 0
return function ()
	index = index + 1
	--return tostring(os.time())..string.format("%05d", index % 100000)-- 5 + 10 + 17
	return string.format("%010d", index % 1000000000)
end