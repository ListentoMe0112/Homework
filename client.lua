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
        local token, amsg = string.match(msg, "(%d)%+%+%+%+(%g*)")
        -- print(token, amsg)
        token = tonumber(token)
        if (token == 1) then
            io.write("Receive: "..amsg.."\n")
        elseif (token == 2) then
            for w in string.gmatch( amsg,"%d+" ) do
                print(string.format("Players.token = %d", w))
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
    -- usage: = 0  信息发往所有非己玩家
    --        > 0  同token为指定数值的玩家通讯
    --        = -1 询问所有已加入玩家列表
    -- msg的数据结构为 usage++++msg
    -- io.write("<Usage> 0: send to all. >1: send to special socket stream. =-1: query for players now existed\n")
    io.write("Usage: ")
    local use = io.read()
    io.write("Input: ")
    local msg = io.read()
    ss.call(use.."++++"..msg)
end

