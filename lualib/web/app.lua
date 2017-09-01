local skynet = require "skynet"
local cjson = require "cjson"
local BEFORE_PROCESS = {}
local AFTER_PROCESS = {}
local PROCESS = {}              -- 处理模式
local INIT_PROCESS  = false     -- 是否已初始化
local SORT_PROCESS = {}         -- 排序后处理器

local function init_process()
    if INIT_PROCESS then
        return
    end
    INIT_PROCESS = true
    SORT_PROCESS = {}
    for _, v in ipairs(BEFORE_PROCESS) do 
        table.insert(SORT_PROCESS, v) 
    end
    for _, v in ipairs(PROCESS) do 
        table.insert(SORT_PROCESS, v)
    end 
    for _, v in ipairs(AFTER_PROCESS) do 
        table.insert(SORT_PROCESS, v) 
    end 
end

local function not_found_process(req, res)
    res.code = 404
    res.body = "<html><head><title>404 Not Found</title></head><body> <p>404 Not Found</p></body></html>"
    res.headers["Content-Type"]="text/html"
end

local function internal_server_error(req, res, errmsg)
    res.code = 500
    if IS_DEBUG then
        local body = "<html><head><title>Internal Server Error</title></head><body><p>500 Internal Server Error</p><p>%s</p></body></html>"
        res.body = string.format(body, errmsg)
    else
        res.body = "<html><head><title>Internal Server Error</title></head><body><p>500 Internal Server Error</p></body></html>"
    end
    res.headers["Content-Type"]="text/html"
    return res.code, res.body, res.headers
end

local web = {}

local function pre_pattern(path)
    local keys = {}
    for k in string.gmatch(path, "/:([%w_]+)") do
        table.insert(keys, k)
    end
    if #keys == 0 then
        return path
    end
    local pattern = string.gsub(path, "/:(%w+)", "/([%%w_]+)")
    return pattern, keys
end


function web.use(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(PROCESS, {path= path, pattern = pattern, keys=keys, process = process})
end

--是否有意义？方便处理排序？
function web.after(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(AFTER_PROCESS, {path= path, pattern = pattern, keys=keys, process = process})
end

--是否有意义？方便处理排序？
function web.before(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(BEFORE_PROCESS, {path= path, pattern = pattern, keys=keys, process = process})
end

function web.get(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(PROCESS, {path = path, pattern = pattern, keys=keys, process = process, method = "GET"})
end

function web.post(path, process)
    INIT_PROCESS  = false
    local pattern, keys = pre_pattern(path)
    table.insert(PROCESS, {path = path, pattern = pattern, keys=keys, process = process, method = "POST"})
end

local function static(root, file)
    file = root..file
    local fd = io.open(file, "r")
    local read = function ()
        local content = fd:read(1024 * 128)
        if content then
            return content
        else
            fd:close()
        end
    end
    return read
end

local file_content_type = {
    js = "text/javascript",
    html = "text/html",
    css = "text/css",
    jpg = "image/jpeg",
    jpeg = "image/jpeg",
    txt = "text/plain",
    json = "application/json",
}

-- 静态文件下载
function web.static(path, root)
    web.get(path, function (req, res)
        local file = req.path
        if string.find(file, "%.%s.") then      -- 禁止相对路径
            res.code = 404
            res.body = "NOT FOUND"
            return true
        end
        res.body = static(root, file)
        local suffix = string.match(file, "%.(%w+)$")
        res.headers["Content-Type"] = file_content_type[suffix]
        return true
    end)
end

-- TODO: 增加高级路由支持
function web.router()
    -- body
end

local REQ = {
--    ip = "192.168.1.123",
--    url = "/",
--    method = "GET",
--    body = "xx=xxx",
--    headers = {},
--    path = "",
}

local RES = {
--     code = 200
--     headers = {},
--     body = "",
--     hostname = "example.com",
}

function RES:json(tbl)
    local body = cjson.encode(tbl)
    self.headers["Content-Type"] = 'application/json'
    self.body = body
end

function RES:status(code)
    self.code = code
end

local function process(req, res)
    init_process()                              -- 延后初始化处理器
    -- 正则表达式匹配支持
    local found = false
    for _, match in ipairs(SORT_PROCESS) do 
        if match.method and req.method ~= match.method then
        elseif string.match(req.path, match.pattern) then
            found = true
            if match.keys then
                local args = table.pack(string.match(req.path, match.pattern))
                if #args == #match.keys then
                    local params = {}
                    for k,v in ipairs(args) do 
                        params[match.keys[k]] = v
                    end
                    req.params = params
                    if not match.process(req, res) then
                        break
                    end
                end
            elseif not match.process(req, res) then
                break
            end
        end
    end
    return found or not_found_process(req, res)
end

--处理http请求
function web.http_request(addr, url, method, headers, path, query, body, fd)
    local ip, _ = addr:match("([^:]+):?(%d*)$")
    local req = {ip = ip, url = url, method = method, headers = headers, 
            path = path, query = query, body = body, fd = fd, addr = addr}
    local res = {code = 200, body = nil, headers = {}}

    setmetatable(req, REQ)
    REQ.__index = REQ
    setmetatable(res, RES)
    RES.__index = RES
    local trace_err = ""
    local trace = function (e)
        trace_err  = e .. debug.traceback()
    end

    local ok = xpcall(process, trace, req, res)
    if not ok then
        skynet.error(trace_err)
        return internal_server_error(req, res, trace_err)
    end
    return res.code, res.body, res.headers
end

return web
