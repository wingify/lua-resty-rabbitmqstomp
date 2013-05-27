-- lua-resty-rabbitmq: Client library for implementing producers and consumers
-- for RabbitMQ which communicate with the broker over STOMP v1.2 using ngx
-- cosocket api.
-- Copyright (C) 2013 Rohit Yadav (bhaisaab), Wingify
-- Opensourced at Wingify in New Delhi under the MIT License

local tcp = ngx.socket.tcp

module(...)

_VERSION = "0.01"

local mt = { __index = _M }


local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)
