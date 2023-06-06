

package.path = mp.command_native({"expand-path", "~~/script-modules/?.lua;"})..package.path
local input = require "user-input-module"

-- Lua uses 1-based arrays!
local msgs = {"test1", "test2", "test3", ""}
local i = 0;

function handle_reply(reply, err)
    if reply then
        mp.msg.log("info", reply)
        mp.osd_message(reply)
    end
end

local function mh_demo_func()

    input.get_user_input(handle_reply, { request_text = "Enter YouTube URL:" })

	-- mp.osd_message(msgs[i + 1])
    -- i = (i + 1) % #msgs

	-- if i == #msgs then
	-- 	i = 1
	-- else
	-- 	i = i + 1
	-- end

end

-- mp.add_key_binding("Z", "mh_demo_func", mh_demo_func)

