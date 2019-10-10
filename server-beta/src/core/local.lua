local guide = require 'parser.guide'

local m = {}

function m:def(source, callback)
    if source.tag ~= 'self' then
        callback(source, 'local')
    end
    if source.ref then
        for _, ref in ipairs(source.ref) do
            if ref.type == 'setlocal' then
                callback(ref, 'set')
            end
        end
    end
    if source.tag == 'self' then
        local method = source.method
        local node = method.node
        self:eachDef(node, callback)
    end
end

function m:ref(source, callback)
    if source.tag ~= 'self' then
        callback(source, 'local')
    end
    if source.ref then
        for _, ref in ipairs(source.ref) do
            if ref.type == 'setlocal' then
                callback(ref, 'set')
            elseif ref.type == 'getlocal' then
                callback(ref, 'get')
            end
        end
    end
    if source.tag == 'self' then
        local method = source.method
        local node = method.node
        self:eachRef(node, callback)
    end
end

function m:field(source, key, callback)
    local refs = source.ref
    if refs then
        for i = 1, #refs do
            local ref = refs[i]
            if ref.type == 'getlocal' then
                local parent = ref.parent
                if key == guide.getKeyName(parent) then
                    self:childRef(parent, callback)
                end
            elseif ref.type == 'getglobal' then
                -- _ENV.XXX
                if key == guide.getKeyName(ref) then
                    callback(ref, 'get')
                end
            elseif ref.type == 'setglobal' then
                -- _ENV.XXX = XXX
                if key == guide.getKeyName(ref) then
                    callback(ref, 'set')
                end
            end
        end
    end
    if source.tag == 'self' then
        local method = source.method
        local node = method.node
        self:eachField(node, key, callback)
    end
    self:eachValue(source, function (src)
        if source ~= src then
            self:eachField(src, key, callback)
        end
    end)
end

function m:value(source, callback)
    callback(source)
    local refs = source.ref
    if refs then
        for i = 1, #refs do
            local ref = refs[i]
            if ref.type == 'setlocal' then
                self:eachValue(ref.value, callback)
            end
        end
    end
    if source.value then
        self:eachValue(source.value, callback)
    end
end

return m