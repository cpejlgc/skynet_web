local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local SOCKET_NUMBER = 0

local CMD = {}

function add_web_agent_cmd(cmd, process)      -- 这样合适吗？
    CMD[cmd] = process
end

local webapp_name, body_size_limit = ...
local webapp = require(webapp_name)

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        -- skynet.error(string.format("fd = %d, %s", id, err))
    end
end


function CMD.update()
    skynet.fork(function ()
        while true do
            skynet.sleep(60 * 100)           -- 60s
            if SOCKET_NUMBER == 0 then
                break
            end
        end
        logger.info("after update service exit %08x", skynet.self())
        skynet.exit()                        -- 没有连接存在了
    end)
end

function CMD.info()
    logger.info("socket connect number %s", SOCKET_NUMBER)
end

function CMD.exit()
    -- body
end

function CMD.socket( fd, addr)
    SOCKET_NUMBER = SOCKET_NUMBER + 1
    socket.start(fd)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), tonumber(body_size_limit))
    if code then
        if code ~= 200 then
            response(fd, code)
        else
            local path, query = urllib.parse(url)
            local q = {}
            if query then
                q = urllib.parse_query(query)
            end             
            response(fd, webapp.http_request(addr, url, method, header, path, q, body, fd))
        end
    else
        if url == sockethelper.socket_error then
            -- skynet.error("socket closed")
        else
            -- skynet.error(url)
        end
    end
    SOCKET_NUMBER = SOCKET_NUMBER - 1
    socket.close(fd)
end

skynet.start(function() 
    skynet.dispatch("lua", function(session, _, command, ...)
        local f = CMD[command]
        if not f then
            if session ~= 0 then
                skynet.ret(skynet.pack(nil))
            end
            return
        end
        if session == 0 then
            return f(...)
        end
        skynet.ret(skynet.pack(f(...)))
    end)
end)
