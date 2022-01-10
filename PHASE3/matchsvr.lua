#!/usr/bin/luna
--matchsvr示例
lbus = require("lbus")
router_helper = hive.import("router_helper.lua");

_G.s2s = s2s or {}; --所有server间的rpc定义在s2s中

matchWaited = {}


s2s.newMatch = function(socket, ...)
    local arg={...} 
    print("Enter newMatch Function")
    local player = {["gameSrv"] = arg[1], ["ss.token"] = arg[2]}
    matchWaited[#matchWaited + 1] = player
    -- 等待匹配玩家人数>=3 即可以开始游戏
    if #matchWaited >= 3 then
        -- 从匹配队列中取出三名玩家
        local playersInroom = {}
        for i = 1, 3 do
            playersInroom[#playersInroom + 1] = matchWaited[#matchWaited]
            matchWaited[#matchWaited] = nil
        end
        local win_token = 1
        local max_cur = 1
        for i = 1, 3 do
            print("In matchServer: "..playersInroom[i]["gameSrv"].."\t"..playersInroom[i]["ss.token"])
            current_router.forward_target(tonumber(playersInroom[i]["gameSrv"]), "msgToClients", tonumber(playersInroom[i]["ss.token"]),"The Game Started")
            local res = math.random(6) 
            current_router.forward_target(tonumber(playersInroom[i]["gameSrv"]), "msgToClients", tonumber(playersInroom[i]["ss.token"]),"You have gotten "..res)
            if max_cur < res then
                max_cur = res
                win_token = i
            end
        end

        for i = 1, 3 do
            if i == win_token then
                current_router.forward_target(tonumber(playersInroom[i]["gameSrv"]), "msgToClients", tonumber(playersInroom[i]["ss.token"]),"Congratulation! You have won this game")
            else
                current_router.forward_target(tonumber(playersInroom[i]["gameSrv"]), "msgToClients", tonumber(playersInroom[i]["ss.token"]),"Sorry, You have lose this game")
            end
        end

    -- 玩家不够，匹配中
    else
        -- print("Before forward_target")
        -- print(current_router)
        -- print(arg[1], arg[2])
        current_router.forward_target(tonumber(arg[1]), "msgToClients", tonumber(arg[2]), "Please Wait for more players.")
        -- print("After forward_target")
    end
end

hive.run = function()
    socket_mgr = lbus.create_socket_mgr(100);
    router_helper.setup(socket_mgr, "matchsvr", hive.args[1]);
    local next_reload_time = 0;
    while true do
		socket_mgr.wait(50);
        router_helper.update(now);
    end
end

