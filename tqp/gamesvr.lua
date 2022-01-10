#!/usr/bin/luna
--gamesvr示例
lbus = require("lbus")
router_helper = hive.import("router_helper.lua");
_G.s2s = s2s or {}; --所有server间的rpc定义在s2s中


-- ************************* ↓RPC调用↓ **************************
function s2s.broadCasting(socket, ...)
    local arg={...}
    print(arg[1], arg[2])
    print(router_helper.my_id)
    if tonumber(arg[1]) ~= router_helper.my_id then
        print("enter function")
        local msg = "1++++"..arg[2]
        -- print("msg: "..msg)
        -- print(clients)
        for k,v in pairs(clients) do
            v.call(msg)
        end
    end
end

function s2s.msgToClients(socket, ...)
    local arg={...}
    -- print(arg[1], arg[2])
    -- print(type([arg[1]]), type([arg[2]]))
    if type(arg[1]) == "number" then
        -- print("Before call client")
        local msg = "1++++"..arg[2]
        -- print(msg)
        clients[arg[1]].call(msg)
        -- print("Before call client")
    end
end
-- ************************* ↑RPC调用↑ **************************


-- ************************* ↓Local调用↓ ************************
function broadCastInLocal(socket, info)
    local msg = "1++++"..info
    for k,v in pairs(clients) do
        if k ~= socket.token then
            v.call(msg)
        end
    end
end
-- ************************* ↑Local调用↑ ************************



-- ************************* ↓Local调用↓ ************************
clients = clients or {}
-- ************************* ↑Local调用↑ ************************

last_test = 0;

hive.run = function ()
	socket_mgr = lbus.create_socket_mgr(100);
    client_mgr = lbus.create_socket_mgr(100);
    
    router_helper.setup(socket_mgr, "gamesvr", hive.args[1]);
    listener = client_mgr.listen("127.0.0.1", tonumber(hive.args[2]));
    print(listener)

-- ************************* ↓对客户端的回调↓ ************************
    listener.on_accept = function(ss)
        print("GameServer On_accept")
        clients[ss.token] = ss;
        call_dbagent("newClient", ss.token)

        ss.on_call = function (msg,...)
            local op, info = string.match(msg, "(%--%d+)%+%+%+%+(.*)")
            print(op, info)
            op = tonumber(op)
            if op == 0 then
                broadCastInLocal(ss, info)
                broadcast_gameSrv("broadCasting", info)
            elseif op == 1 then
                call_matchsvr("newMatch", ss.token)
            end
        end
    end
-- ************************* ↑对客户端的回调↑ ************************


-- ************************* ↓主体运行逻辑↓ ************************
    while true do
		socket_mgr.wait(50);
        client_mgr.wait(50);
        router_helper.update(now);
        -- test_msg(now);
    end
-- ************************* ↑主体运行逻辑↑ ************************
end

