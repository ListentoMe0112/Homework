#!/usr/bin/luna
--dbagent示例

-- ************************* ↓dbagent的依赖↓ ************************
lbus = require("lbus")
router_helper = hive.import("router_helper.lua");
-- ************************* ↑dbagent的依赖↑ ************************


-- ************************* ↓记录结构↓ ************************
-- clients[gameSrv.my_id] = {ss.token}
clients = clients or {}
-- ************************* ↑记录结构↑ ************************


-- ************************* ↓RPC调用↓ ************************
_G.s2s = s2s or {}; --所有server间的rpc定义在s2s中

s2s.newClient = function(socket, ...)
    local arg={...} 
    -- print("New Client, serverId = "..arg[1].."\tss.token = "..arg[2])
    clients[arg[1]] = clients[arg[1]] or {}
    clients[arg[1]][#clients[arg[1]] + 1] = arg[2]
    print(clients[arg[1]], clients[arg[1]][#clients[arg[1]]])
end
-- ************************* ↑RPC调用↑ ************************


-- ************************* ↓主体运行逻辑↓ ************************
function main()
	socket_mgr = lbus.create_socket_mgr(100);
    router_helper.setup(socket_mgr, "dbagent", hive.args[1]);

    while true do
		socket_mgr.wait(50);
        router_helper.update(now);
    end
end
main()
-- ************************* ↑主体运行逻辑↑ ************************
