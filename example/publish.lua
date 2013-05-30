-- publish.lua - RabbitMQ STOMP publisher example

pcall(ngx.eof)

local rabbitmq = require "resty.rabbitmq"

function publish()
    local mq, err = rabbitmq:new()
    if not mq then
        ngx.log(ngx.ERR, "NEW OBJ ERROR")
        return
    end

    mq:set_timeout(1000)

    local ok, err = mq:connect {
                      host = "127.0.0.1",
                      port = 61613,
                      username = "guest",
                      password = "guest",
                      vhost = "/devnode"
                  }
    if not ok then
        ngx.log(ngx.ERR, "CONN ERROR: " .. err)
        return
    end

    local msg = "{'a': 'test'}"
    local exchange = "test"
    local binding = "binding"
    local app_id = "luaresty"
    local persistent = "true"
    local content_type = "application/json"

    local ok, err = mq:send(msg, exchange, binding, app_id, persistent, content_type)
    if not ok then
        ngx.log(ngx.ERR, "MSG SEND ERROR: " .. err)
        return
    end

    local ok, err = mq:confirm()
    if not ok then
        ngx.log(ngx.ERR, "MSG CONFIRMS ERROR: " .. err)
        return publish()
    end

    local ok, err = mq:set_keepalive(0, 1000)
    if not ok then
        ngx.log(ngx.ERR, "KEEPALIVE ERROR: " .. err)
        return
    end
end

publish()
