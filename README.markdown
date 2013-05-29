# Introduction

lua-resty-rabbitmq - Lua RabbitMQ client library which uses cosocket api for
communication over STOMP 1.2 with a RabbitMQ broker which has the STOMP plugin.

# Limitations

This library is opinionated and has certain assumptions and limitations which
may be addressed in future;

- RabbitMQ server should have the STOMP adapter enabled that supports STOMP v1.2
- Assumption that users, vhost, exchanges, queues and bindings are already setup
- In the first version our aim to implement an extensible library with persistent
publishing semantics and heartbeat

# STOMP v1.2 Client Implementation

This library uses STOMP 1.2 for communication with RabbitMQ broker and
implements extensions and restrictions of the RabbitMQ Stomp plugin.

Internally, RabbitMQ uses AMQP to communicate further. This way the library
enables implementation of consumers and producers which communicate with the
RabbitMQ broker over STOMP, over AMQP. The protocol is frame based and has a
command, headers and body terminated by an EOL (^@) which consists of `\r` (013)
and required `\n` (010) over a TCP stream:

    COMMAND
    header1:value1
    header2: value2

    BODY^@

COMMAND is followed by EOL, then EOL separated header in key:value pair format
and then a blank line which is where the BODY starts and the frame is terminated
by ^@ EOL. COMMAND and headers are UTF-8 encoded.

## Connection

To connect we create and send a CONNECT frame over a TCP socket provided by the
cosocket api connecting to the broker IP, both IPv4 and IPv6 are supported. In
the frame we use login, passcode for authentication, accept-version to enforce
client STOMP version support and host to select the VHOST of the broker.

    CONNECT
    accept-version:1.2
    login:guest
    passcode:guest
    host:/devnode
    heart-beat:optional

    ^@

On error, an ERROR frame is returned for example:

    ERROR
    message:Bad CONNECT
    content-type:text/plain
    version:1.0,1.1,1.2
    content-length:32

    Access refused for user 'admin'^@

On successful connection, we are returned a CONNECTED frame by the broker, for
example:

    CONNECTED
    session:session-sGF0vjCKH1bLhFr6w9QwuQ
    heart-beat:0,0
    server:RabbitMQ/3.0.4
    version:1.2

For creating a connection, username, password, vhost, heartbeat, broker host and
port should be provided.

## Publishing

We can publish messages to an exchange with a routing key, persistence mode,
delivery mode and other header using the SEND command:

    SEND
    destination:/exchange/exchange_name/routing_key
    app-id: luaresty
    delivery-mode:2
    persistent:true
    content-type:json/application
    content-length:5

    hello^@

Note that content-length includes the message and EOL byte.

## API Documentation

TODO: FIXME once API spec if finalized

## Example

A simple producer that can send reliable persistent message to an exchange with
some binding with publisher confirms:

    local rabbitmq = require "resty.rabbitmq"

    local mq, err = rabbitmq:new()
    if not mq then
          return
    end

    mq:set_timeout(5000)

    local ok, err = mq:connect {
                        host = "127.0.0.1",
                        port = 61613,
                        username = "guest",
                        password = "guest",
                        vhost = "/"
                    }

    if not ok then
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
        return
    end

    local ok, err = mq:confirm()
    if not ok then
        return
    end

    local ok, err = mq:set_keepalive(0, 10000)
    if not ok then
        return
    end

# Contact

Author: Rohit Yadav ([bhaisaab](mailto:bhaisaab@apache.org))

You may drop an email to the author or contact the [openresty google group](https://groups.google.com/forum/?fromgroups#!forum/openresty-en).

# Copyright and License

This module is licensed under the MIT license.

FIXME: add header.
