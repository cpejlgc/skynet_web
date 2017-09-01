local skynet = require "skynet"
require "skynet.manager"

skynet.start(function ( ... )
    skynet.error("test main start")
    skynet.newservice("debug_console", 8000)
    if not skynet.getenv "daemon" then
        local console = skynet.uniqueservice("console")
    end
    
    local handle = skynet.newservice("srv_web", 8080, "examples/webapp", 65536)
    skynet.name(".web", handle)
end)