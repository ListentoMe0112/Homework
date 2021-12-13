lbus = require("lbus")

socket_mgr = lbus.create_socket_mgr(10000);

errors = {};



function init_session(ss)
    
    ss.on_connect = function(res)
        print("[Client] Connect Successfully");   
        if res == "ok" then      
            return;
        end      
    end

    ss.on_call = function(msg, ...)
        -- 如果token == 1 说明返回来的是信息 直接打印就行
        -- 如果token == 2 说明返回的是玩家 需要进行处理
        -- 如何token == 3 说明返回的是房间 需要进行处理
        local token, amsg = string.match(msg, "(%d)%+%+%+%+(.*)")
        -- print(token, amsg)
        token = tonumber(token)
        if (token == 1) then
            io.write("Receive: "..amsg.."\n")
        elseif (token == 2) then
            for w in string.gmatch( amsg,"%d+" ) do
                print(string.format("Players.token = %d", w))
            end
        elseif (token == 3) then
            -- print("here")
            for w in string.gmatch( amsg, "%d+:[%d+,]+") do
                print(w)
                local roomId, peoples = string.match(w, "(%d+):(.*)");
                print(peoples)
                local s = ""
                for people in string.gmatch( peoples, "(%d+)") do
                    print(people)
                    s = s.." "..tostring(people)
                end
                -- print("Here")
                print(string.format("RoomId: %d, Players: %s", roomId, s));
            end
        end
    end

    ss.on_error = function(err)
        print("[Error]");
        if errors[err] == nil then
            errors[err] = 1;
            print(err);
        end        
    end 
end

local ss = socket_mgr.connect("127.0.0.1", 9999, 2000);
if ss then
    init_session(ss);
end

hive.run = function()
    socket_mgr.wait(100);
    --        = 0               信息发往所有非己玩家
    --        = 9999            加入指定房间
    --        = 10000           创建房间
    --        = 10001           离开房间
    --        = 20000           玩骰子游戏, 后面需要跟房间号， 只有房主能开始游戏
    --        > 0 and < 9999    同token为指定数值的玩家通讯
    --        = -1              询问所有已加入玩家列表
    --        = -2              询问所有已创建房间，以及房间人数
    --        = -3              询问已经加入房间的玩家
    --        = -4              询问未加入房间的玩家
    io.write("Usage: ")
    local use = io.read()
    io.write("Input: ")
    local msg = io.read()
    ss.call(use.."++++"..msg)
end

