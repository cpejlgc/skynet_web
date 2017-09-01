-- lua扩展

-- table扩展

-- 返回table大小
table.size = function(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- 判断table是否为空
table.empty = function(t)
    return not next(t)
end

-- 返回table索引列表
table.indices = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, k)
    end
    return result
end

-- 返回table值列表
table.values = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, v)
    end
    return result
end

-- 浅拷贝
table.clone = function(t, nometa)
    local result = {}
    if not nometa then
        setmetatable(result, getmetatable(t))
    end
    for k, v in pairs (t) do
        result[k] = v
    end
    return result
end

--清空表
table.clear = function(array)
    if type(array)~="table" then
        return
    end
    for k,_ in pairs(array) do
        array[k] = nil
    end
end

-- 深拷贝
table.copy = function(t, nometa)   
    local result = {}

    if not nometa then
        setmetatable(result, getmetatable(t))
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = table.copy(v)
        else
            result[k] = v
        end
    end
    return result
end

table.merge = function(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

table.unique_insert = function(t,val)
    for k,v in pairs(t) do
        if v==val then return end
    end
    table.insert(t,val)
end

table.delete = function(t,val)
    for k,v in pairs(t) do
        if v==val then
            table.remove(t, k)
            return val
        end
    end
end

--根据table某个字段获取值,array所有值为table结构
table.key_find = function(array, key, val)
    for k, v in ipairs(array) do 
        if v[key] == val then
            return v 
        end
    end
    return nil
end

table.key_delete = function(array, key, val)
    for k, v in ipairs(array) do 
        if v[key] == val then
            table.remove(array,k)
            return  
        end
    end
    return 
end

--删除所有v[key] = val的值
table.key_delete_all = function(array, key, val)
    local i = 1
    while i<= #array do
        if array[i][key] == val then
            table.remove(array, i)
        else
            i = i + 1
        end
    end
end

--删除多个数据
table.array_delete = function(array, t_val)
    for k,v in pairs(t_val) do
        table.delete(array, v)
    end
end

--检测某个值是否在table里面
table.member = function(array, val)
    for k,v in ipairs(array) do
        if v==val then
            return true
        end
    end
    return false
end

--连接
table.link = function(dest, obj)
    for k, v in pairs(obj) do
        table.insert(dest,v)
    end
end

table.insertto = function (dest, obj)
    for k, v in ipairs(obj) do
        table.insert(dest, v)
    end
    return dest
end

-- string扩展

-- 下标运算
do
    local mt = getmetatable("")
    local _index = mt.__index

    mt.__index = function (s, ...)
        local k = ...
        if "number" == type(k) then
            return _index.sub(s, k, k)
        else
            return _index[k]
        end
    end
end

function string.split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end
    
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

string.ltrim = function(s, c)
    local pattern = "^" .. (c or "%s") .. "+"
    return (string.gsub(s, pattern, ""))
end

string.rtrim = function(s, c)
    local pattern = (c or "%s") .. "+" .. "$"
    return (string.gsub(s, pattern, ""))
end

string.trim = function(s, c)
    return string.rtrim(string.ltrim(s, c), c)
end

_tostring = tostring
local function dump(obj)
    local cache = {}
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val, level)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        elseif type(val) == "table" then
            if cache[val] then
                return "[" .. cache[val] .. "]"
            else
                return "[" .. dumpObj(val, level, ".") .. "]"
            end
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level, path)
        if type(val) == "table" then
            return dumpObj(val, level, path)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level, path)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        if cache[obj] then
            return cache[obj]
        end
        cache[obj] = string.format('"%s"', path)
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            if type(k) == "table" then  
                tokens[#tokens + 1] = getIndent(level) .. wrapKey(k, level) .. " = " .. wrapVal(v, level, path .. cache[k] .. ".") .. ","
            else
                tokens[#tokens + 1] = getIndent(level) .. wrapKey(k, level) .. " = " .. wrapVal(v, level, path .. k .. ".") .. ","
            end
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0, ".")
end

_tostring = tostring
do
    local _tostring = tostring
    tostring = function(v)
        if type(v) == 'table' then
            return dump(v)
        else
            return _tostring(v)
        end
    end
end

-- math扩展
do
	local _floor = math.floor
	math.floor = function(n, p)
		if p and p ~= 0 then
			local e = 10 ^ p
			return _floor(n * e) / e
		else
			return _floor(n)
		end
	end
end

math.round = function(n, p)
        local e = 10 ^ (p or 0)
        return math.floor(n * e + 0.5) / e
end


-- lua面向对象扩展
function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua

        function cls.new(...)
            local instance = setmetatable({}, {__index = cls})
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

function iskindof(obj, classname)
    local t = type(obj)
    local mt
    if t == "table" then
        mt = getmetatable(obj)
    elseif t == "userdata" then
        mt = tolua.getpeer(obj)
    end

    while mt do
        if mt.__cname == classname then
            return true
        end
        mt = mt.super
    end

    return false
end
