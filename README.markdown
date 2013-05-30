# Introduction

lua-resty-rabbitmq - Lua RabbitMQ client library which uses cosocket api for
communication over STOMP 1.2 with a RabbitMQ broker which has the STOMP plugin.

# Limitations

This library is opinionated and has certain assumptions and limitations which
may be addressed in future;

- RabbitMQ server should have the STOMP adapter enabled that supports STOMP v1.2
- Assumption that users, vhost, exchanges, queues and bindings are already setup
- In the first version our aim to implement a client library with persistent
publishing to an exchange with some binding and handle RECEIPTs, the focus would
be to reuse sockets using cosocktcp sockets.

# Status

This library is under development.

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

## Methods

FIXME: Add docs on methods

### new

### set_timeout

### connect

### send

### get_reused_times

### set_keepalive

### close

## Example

A simple producer that can send reliable persistent message to an exchange with
some binding with publisher confirms:

    local rabbitmq = require "resty.rabbitmq"

    local mq, err = rabbitmq:new()
    if not mq then
          return
    end

    mq:set_timeout(1000)

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

    local ok, err = mq:set_keepalive(0, 10000)
    if not ok then
        return
    end

# TODO

- Fix README docs
- Write tests
- Fix all FIXMEs in the code

# Contact

Author: Rohit Yadav ([bhaisaab](mailto:bhaisaab@apache.org))

# Copyright and License

This module is licensed under the MIT license.

Copyright 2013 Rohit 'bhaisaab' Yadav, [Wingify](http://engineering.wingify.com/opensource)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# See Also

- [STOMP 1.2 Spec](http://stomp.github.io/stomp-specification-1.2.html)
- The [lua-resty-mysql](https://github.com/agentzh/lua-resty-mysql) library
- [Openresty google group](https://groups.google.com/forum/?fromgroups#!forum/openresty-en)
