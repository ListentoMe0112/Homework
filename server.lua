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

listener.on_accept = function(ss)

    -- 把新连接的ss加入到sessions中
    sessions[session_count+1] = ss;
    session_count = session_count + 1;
    for k,v in pairs(sessions) do
        print(k,v, v.token)
    end
    
    print("[Server] New Client Conect")

    -- 设置回调函数
    ss.on_error = function(err)
        sessions[ss.token] = nil;
        session_count = session_count - 1;
        error_count = error_count + 1;
        if errors[err] == nil then
            errors[err] = 1;
            print(err);
        end
    end
    
    -- 对对端发来消息的的回调
    ss.on_call = function(msg,...)
        local token, msg = string.match(msg, "(%--%d)%+%+%+%+(%w*)")
        token = tonumber(token)
        print(token, msg)

        -- 如果指定通讯端口则对指定端口进行call
        if (token > 0) then
            for k,v in ipairs(sessions) do
                if v.token == token then
                    msg = "1".."++++"..msg
                    v.call(msg)
                end
            end

        -- 信息发往所有非己玩家 √
        elseif token == 0 then
            print("here")
            modified = false
            for k,v in ipairs(sessions) do
                if (v ~= ss) then
                    if not modified then
                        msg = "1".."++++"..msg
                        modified = true
                    end
                    print(msg)
                    v.call(msg)
                end
            end
            
        -- 询问所有已加入玩家列表 
        elseif token == -1 then
            local players = ""
            for k,v in ipairs(sessions) do
                if (v ~= ss) then
                   players = players..tostring(v.token)..","
                end
            end
            players = "2".."++++"..players
            ss.call(players)
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

