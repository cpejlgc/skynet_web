skynetroot = "./skynet/"
root="./"
thread = 8
harbor = 0
start = "main"  -- main script
bootstrap = "snlua bootstrap"   -- The service for bootstrap

gameservice = root.."service/?.lua;" ..
            "./examples/?.lua"

luaservice = skynetroot.."service/?.lua;" .. gameservice

lualoader = skynetroot .. "lualib/loader.lua"
preload = "./examples/preload.lua"   -- run preload.lua before every lua service run
snax = gameservice
cpath = skynetroot.."cservice/?.so;".. "" ..root.."cservice/?.so" 

lua_path = skynetroot .. "lualib/?.lua;" ..
            -- skynetroot .. "lualib/compat10/?.lua;" ..
            root .. "examples/?.lua;" ..
            root .. "lualib/?.lua;"..
            root .. "lualib/rpc/?.lua;".. 
            "./lualib/?.lua;" ..
            "./?.lua" 
            
lua_cpath = skynetroot .. "luaclib/?.so;" .. root .."luaclib/?.so" 

logpath = $LOG_PATH

if $DAEMON then
      daemon = "./run/skynet.pid"
      logger = logpath .. "skynet-error.log"
end