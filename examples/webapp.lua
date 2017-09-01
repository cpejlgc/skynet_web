local skynet = require "skynet"
local webapp = require "web.app"
local wsapp = require "examples.wsapp"

-- 允许跨域请求
webapp.before(".*", function (req, res)
    res.headers["Access-Control-Allow-Origin"] = "*"
    res.headers["Access-Control-Allow-Methods"] = "*"
    res.headers["Access-Control-Allow-Credentials"] = "true"
    return true
end)


webapp.get("^/hello$", function (req, res)
    res.body = "Hello World"
    return false
end)

webapp.post("^/hello$", function (req, res)
    res:json({query = req.query})
    return false
end)


webapp.use("^/api/:name", function (req, res)
    local name = req.params.name
    res:json({ code = 200, name = name, time = skynet.time()})
    return true
end)


webapp.after("^/api/*", function (req, res)
    -- TODO: api请求后日志记录
    print(req.path, req.params, res.body)
    return true
end)

-- 静态文件下载
webapp.static("^/static/*", "./examples")

-- http 升级为 websocket 协议
webapp.use("^/ws$", function (...)
    wsapp.process(...)
end)

return webapp