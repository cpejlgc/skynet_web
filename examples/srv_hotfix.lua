local codecache = require "skynet.codecache"
local skynet = require "skynet"


skynet.start(function() 
    codecache.clear()               -- 更新代码
    skynet.send(".web", "lua","update")
    skynet.exit()
end)
