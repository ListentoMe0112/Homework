lbus = require("lbus")

socket_mgr = lbus.create_socket_mgr(10000);
-- 用于存放连接的ss
sessions = {};
-- 用于存放最近的对话记录
message = {};

listener = socket_mgr.listen("127.0.0.1", 9999);

session_count = 0;
message_count = 0;
message_speed = 0;
error_count = 0;
errors = {};

-- {k: Roomowner ss.token; v: Players In Room， a set}
rooms = {};
-- {k: ss.token; v: Players [In] Room Represented by ss.toekn}
playersInroom = {};
-- {k: ss.token; v: Players [Out] Room Represented by ss.toekn}
playersOutroom = {};
-- {k: ss.token; v: RoomId}

listener.on_accept = function(ss)

    -- 把新连接的ss加入到sessions中
    sessions[ss.token] = ss;
    
    session_count = session_count + 1;
    -- for k,v in pairs(sessions) do
    --     print(k,v, v.token)
    -- end
    -- Set ss a new out room player
    playersOutroom[ss.token] = ss;
    -- print("[Server] New Client Conect")

    -- 设置回调函数，需要在这里实现玩家的退出游戏响应
    ss.on_error = function(err)
        -- 若掉线玩家是房主则房间取消, 同时房间内玩家从房间内部退出到匹配大厅
        if rooms[ss.token] then
            for k,v in paris(rooms[ss.token]) do
                if k ~= ss.token then
                    playersInroom[k] = nil
                    playersOutroom[k] = v
                end
            end
            playersInroom[ss.token] = nil
            rooms[ss.token] = nil
        -- 如果掉线玩家不是房主
        else
            for k, v in paris(rooms) do
                if v[ss.token] then
                    v[ss.token] = nil
                end
                playersInroom[ss.token] = nil
            end
        end
        
        sessions[ss.token] = nil;
        session_count = session_count - 1;
        error_count = error_count + 1;
        if errors[err] == nil then
            errors[err] = 1;
            print(err);
        end
    end

    ss.on_call = function(msg,...)      -- 对对端发来消息的的回调
    --        = 0               信息发往所有非己玩家
    --        = 9999            加入指定房间
    --        = 10000           创建房间
    --        = 10001           离开房间
    --        > 0 and < 9999    同token为指定数值的玩家通讯
    --        = -1              询问所有已加入玩家列表
    --        = -2              询问所有已创建房间，以及房间人数
    --        = -3              询问已经加入房间的玩家
    --        = -4              询问未加入房间的玩家
        local token, msg = string.match(msg, "(%--%d+)%+%+%+%+(.*)")
        token = tonumber(token)
        print(token, msg)
        -- 如果指定通讯端口则对指定端口进行call √
        if (token > 0 and token < 9999) then
            for k,v in pairs(sessions) do
                if v.token == token then
                    msg = "1".."++++"..msg
                    v.call(msg)
                end
            end 
        -- 信息发往所有非己玩家 √
        elseif token == 0 then          
            modified = false
            for k,v in ipairs(sessions) do
                if (v ~= ss) then
                    if not modified then
                        msg = "1".."++++"..msg
                        modified = true
                    end
                    v.call(msg)
                end
            end
        -- 询问所有已加入玩家列表 √
        elseif token == -1 then          
            local players = ""
            for k,v in ipairs(sessions) do
                if (v ~= ss) then
                   players = players..tostring(v.token)..","
                end
            end
            players = "2".."++++"..players
            ss.call(players)
        -- 询问所有房间以及房间人数 √
        elseif token == -2 then   
            local roomsRet = "";
            for k,v in pairs(rooms) do
                -- print("here")
                -- roomsRet = roomsRet..tostring(k)..":"..tostring(v)..",";
                roomsRet = roomsRet..tostring(k)..":";
                for v_k, v_v in pairs(v) do
                    roomsRet = roomsRet..tostring(v_v)..","
                end
                roomsRet = roomsRet.."  "
            end

            roomsRet = "3".."++++"..roomsRet
            print(roomsRet)
            ss.call(roomsRet)
        -- 询问所有已加入房间的玩家
        elseif token == -3 then
            local playersRet = "";
            for k,v in pairs(playersInroom) do
                playersRet = playersRet..tostring(k)..","
            end
            playersRet = "2".."++++"..playersRet
            ss.call(playersRet)
        -- 询问所有未加入房间的玩家
        elseif token == -4 then
            local playersRet = "";
            for k,v in pairs(playersOutroom) do
                playersRet = playersRet..tostring(k)..","
            end
            playersRet = "2".."++++"..playersRet
            ss.call(playersRet)
        -- 加入房间 √
        elseif token == 9999 then         
            -- print("[Player Into Room]")
            local roomId = tonumber(msg);
            -- print("roomId", roomId);
            if rooms[roomId] then
                if #rooms[roomId] < 3 then
                    rooms[roomId][#rooms[roomId] + 1] = ss.token
                    -- 玩家加入房间 则玩家从outroom集合转移到inroom集合
                    playersOutroom[ss.token] = nil
                    playersInroom[ss.token] = ss
                    ss.call("1".."++++".."Join in Room Successfully");
                    if #rooms[roomId] == 3 then
                        -- 自动开始游戏
                        local win_token = 0;
                        local max_cur = 0;
                        local res = 0;
                        for k,v in pairs(rooms[roomId]) do
                            sessions[v].call("1".."++++".."The Game Started")
                            res = math.random(6) 
                            sessions[v].call("1".."++++".."You have gotten "..res) 
                            if res > max_cur then
                                max_cur = res;
                                win_token = v;
                            end
                            print(max_cur, win_token)
                        end

                        for k,v in pairs(rooms[roomId]) do
                            if v == win_token then
                                sessions[v].call("1".."++++".."Congratulation! You have won this game")
                            else
                                sessions[v].call("1".."++++".."Sorry, You have lose this game")
                            end
                        end
                    end
                else
                    ss.call("1".."++++".."Room Full, Please Join another room!");
                end
            else
                ss.call("1".."++++".."No Such Room\n");
            end
        -- 创建房间 √
        elseif token == 10000 then
            -- Create room identified with ss.token and init the number of players(in room) to 1
            -- print("[Create New Room]")
            if rooms[ss.token] then
                ss.call("1".."++++".."You have created one room before")
            else
                rooms[ss.token] = {}
                rooms[ss.token][1] = ss.token;
                playersInroom[ss.token] = ss.token;
                playersOutroom[ss.token] = nil;
                print(rooms[ss.token][1])
            end
            -- print(ss.token)
            -- for k,v in pairs(rooms) do
            --     print(k,v)
            -- end
        -- 退出房间
        elseif token == 10001 then
            -- 如果退出玩家是房主, 将房间内的玩家退出房间，并删除房间
            roomId = tonumber(msg)
            for k,v in pairs(rooms[roomId]) do
                if v == ss.token then
                    sessions[v].call("1".."++++".."Your Escaped and Lose This Game!")
                else
                    sessions[v].call("1".."++++".."Sorry, Game Aborted Cauesed by Lossing Players")
                end
            end

            if rooms[ss.token] then
                for k,v in paris(rooms[ss.token]) do
                    if k ~= ss.token then
                        playersInroom[k] = nil
                        playersOutroom[k] = v
                    end
                end
                playersInroom[ss.token] = nil
                playersOutroom[ss.token] = ss
                rooms[ss.token] = nil
            -- 如果退出玩家不是房主
            else
                for k, v in paris(rooms) do
                    if v[ss.token] then
                        v[ss.token] = nil
                    end
                    playersInroom[ss.token] = nil
                    playersOutroom[ss.token] = ss
                end
            end
        -- 开始游戏
        elseif token == 20000 then -- 玩家开始玩骰子游戏
            -- 玩家房间满3人，且只有房主能够开始游戏，房间内玩家开始游戏
            if playersInroom[ss.token] and rooms[ss.token] and #rooms[ss.token] == 3 then
                print(#rooms[ss.token])
                local win_token;
                local max_cur;
                local roomInfo = rooms[ss.token]
                for k,v in pairs(roomInfo) do
                    print(k, v)
                    local res;
                    if v == ss.token then
                        ss.call("1".."++++".."The Game Started")
                        res = math.random(6)
                        win_token = v;
                        max_cur = res;
                        ss.call("1".."++++".."You have gotten "..res)  
                    else
                        sessions[v].call("1".."++++".."The Game Started")
                        res = math.random(6) 
                        sessions[v].call("1".."++++".."You have gotten "..res) 
                    end

                    if res > max_cur then
                        max_cur = res;
                        win_token = v;
                    end
                    print(max_cur, win_token)
                end
                
                for k,v in pairs(roomInfo) do
                    if v == win_token then
                        if v == ss.token then
                            ss.call("1".."++++".."Congratulation! You have won this game")
                        else
                            sessions[v].call("1".."++++".."Congratulation! You have won this game")
                        end
                    else
                        if v == ss.token then
                            ss.call("1".."++++".."Sorry, You have lose this game")
                        else 
                            sessions[v].call("1".."++++".."Sorry, You have lose this game")
                        end
                    end
                end

            elseif type(playersInroom[ss.token]) == "nil" then
                ss.call("1".."++++".."Sorry, You are not in room.")
            elseif  type(rooms[ss.token]) == "nil" then
                print("here")
                ss.call("1".."++++".."Sorry, You are not the owner of the room.")
            elseif #rooms[ss.token] < 3 then
                ss.call("1".."++++".."Sorry, the Players in room is not up to 3.")
            end

        end

        message_count = message_count + 1;
        message_speed = message_speed + 1;
    end
end

print_time = hive.get_time_ms();

hive.run = function()
    socket_mgr.wait(100);

    local now = hive.get_time_ms();
    if now > print_time then
        local speed = message_speed // 2;
        -- print("session_count="..session_count..", message_count="..message_count..", message_speed="..speed);
        print_time = now + 2000;
        message_speed = 0;
    end
end

