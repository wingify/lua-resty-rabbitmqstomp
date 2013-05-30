-- lua-resty-rabbitmq: Opinionated RabbitMQ (STOMP) client lib
-- Copyright (C) 2013 Rohit Yadav (bhaisaab), Wingify
-- Opensourced at Wingify in New Delhi under the MIT License

local tcp = ngx.socket.tcp
local len = string.len
local concat = table.concat
local setmetatable = setmetatable
local error = error

module(...)

_VERSION = "0.1"

local STATE_CONNECTED = 1
local STATE_COMMAND_SENT = 2
local mt = { __index = _M }


function new(self)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    return setmetatable({ sock = sock }, mt)
end


function set_timeout(self, timeout)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end


function _login(self, user, passwd, vhost)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local req = "CONNECT\x0d\x0a" ..
                "accept-version:1.2\x0d\x0a" ..
                "login:" .. user .. "\x0d\x0a" ..
                "passcode:" .. passwd .. "\x0d\x0a" ..
                "host:" .. vhost .. "\x0d\x0a" ..
                "heart-beat:0,0\x0d\x0a" ..
                "\x0d\x0a\x00\x0d\x0a"
    local ok, err = sock:send(req)
    if not ok then
        return ok, err
    end

    self.state = STATE_CONNECTED
    -- FIXME: Check CONNECTION frame for errors etc.
    local resp = sock:receiveuntil("\x00", {inclusive = true})
    local data, err, partial = resp()
    return ok, data
end


function connect(self, opts)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local host = opts.host
    if not host then
        host = "127.0.0.1"
    end

    local port = opts.port
    if not port then
        port = 61613  -- stomp port
    end

    local username = opts.username
    if not username then
        username = "guest"
    end

    local password = opts.password
    if not password then
        password = "guest"
    end

    local vhost = opts.vhost
    if not vhost then
        vhost = "/"
    end

    local pool = opts.pool
    if not pool then
        pool = concat({username, vhost, host, port}, ":")
    end

    local ok, err = sock:connect(host, port, { pool = pool })
    if not ok then
        return nil, "failed to connect: " .. err
    end

    local reused = sock:getreusedtimes()
    if reused and reused > 0 then
        self.state = STATE_CONNECTED
        return 1
    end

    return _login(self, username, password, vhost)
end


function send(self, msg, exchange, binding, app_id, persistence, content_type)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    -- FIXME: Implement a generator for creating response from a dictionary
    local req = "SEND\x0d\x0a" ..
                "destination:/exchange/" ..
                    exchange .. "/" ..
                    binding .. "\x0d\x0a" ..
                "app-id:" .. app_id  .. "\x0d\x0a" ..
                "receipt:m123\x0d\x0a" ..
                "persistent:" .. persistence  .. "\x0d\x0a" ..
                "content-type:" .. content_type .. "\x0d\x0a" ..
                "\x0d\x0a" ..
                msg .. "\x0d\x0a\x0d\x0a\x00\x0d\x0a"
    local ok, err = sock:send(req)
    if not ok then
        return nil, err
    end
    -- FIXME: Check resp has RECEIPT
    local resp = sock:receiveuntil("\x00", {inclusive = true})
    local data, err, partial = resp()
    if data ~= nil then
        return 1, data
    else
        return nil, err
    end
end


function set_keepalive(self, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    if self.state ~= STATE_CONNECTED then
        return nil, "cannot be reused in the current connection state: "
                    .. (self.state or "nil")
    end

    self.state = nil
    return sock:setkeepalive(...)
end


function get_reused_times(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:getreusedtimes()
end


function _logout(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    self.state = nil
    if self.state == STATE_CONNECTED then
        -- Graceful shutdown
        sock:send("DISCONNECT\x0d\x0areceipt:0\x0d\x0a\x0d\x0a\x00\x0d\x0a")
        sock:receive("*a")
    end
    return sock:close()
end


function close(self)
    return _logout(self)
end


local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
