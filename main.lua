--
-- Imports.
--

package.path = mp.command_native({'expand-path', '~~/script-modules/?.lua;'}) .. package.path

local mp = require('mp')
local utils = require('mp.utils')
local assdraw = require('mp.assdraw')
local input = require 'user-input-module'

--
-- Constants.
--

local DEFS = {
    empty = '_',
    keybind = 'L',
    message_duration = 2
}

--
-- Overall state for the app and the current video.
--

local app = {
    keys_bound = false,
}

local vi = {
    loop = false,
    start = false,
    stop = false,
    m1 = false,
    m2 = false,
}

--
-- Getting user input.
--

function get_reply_demo()
    -- Within mpv, getting user input appears to happen asynchronously,
    -- so the process cannot happen in a natural sequential fashion.
    -- You have to supply a reply-handling function. Any state needed
    -- by the handler can be passed along.
    get_reply(
        'foo: ',
        handle_fubb_reply,
        nil,
        {prefix = 'PRE-', val = 99}
    )
end

function handle_fubb_reply(reply, err, t)
    -- The handler gets the reply, an error or nil, and any state
    -- information passed by the original get_reply() caller.
    if err then
        message(err)
    else
        message(t.prefix .. reply .. ' ' .. t.val)
    end
end

function get_reply(prompt, handler, default_reply, data_to_handler)
    -- See get_user_input() docs for other properties, but
    -- the basic ones are shown here.
    local t = {
        request_text = prompt,
        default_input = default_reply,
        source = 'LoopLlama',
    }
    input.get_user_input(handler, t, data_to_handler)
end

--
-- Utilities.
--

function log(...)
    mp.msg.log('info', ...)
end

function iif(val, a, b)
    if val then
        return a
    else
        return b
    end
end

function rounded(n, digits, default)
    if n == nil then
        return default
    else
        local fmt = string.format('%%0.%sf', digits)
        return string.format(fmt, n)
    end
end

--
-- MISC OTHER.
--

function message(text, duration)
    local ass = mp.get_property_osd('osd-ass-cc/0')
    return mp.osd_message(ass .. text, duration or options.message_duration)
end

function clearMenu()
    local window_w, window_h = mp.get_osd_size()
    mp.set_osd_ass(window_w, window_h, '')
    mp.osd_message('', 0)
end

function displayLoop()
    local msg = table.concat({
        'Loop: ',
        rounded(vi.start, 2, DEFS.empty),
        ' - ',
        rounded(vi.stop, 2, DEFS.empty),
        ' [',
        iif(vi.loop, 'on', 'off'),
        ']',
    })
    clearMenu()
    message(msg)
end

function set_loop_start()
    vi.start = mp.get_property_number('time-pos')
    displayLoop()
end

function set_loop_stop()
    vi.stop = mp.get_property_number('time-pos')
    displayLoop()
end

function on_timepos_change()
    local curr = mp.get_property_number('time-pos')
    if vi.stop and curr and curr >= vi.stop then
        mp.set_property_native('time-pos', vi.start)
    end
end

function toggle_looping()
    if vi.loop == false then
        if vi.start and vi.stop then
            vi.loop = true
            mp.observe_property('time-pos', 'string', on_timepos_change)
            displayLoop()
        end
    else
        vi.loop = false
        mp.unobserve_property(on_timepos_change)
        displayLoop()
    end
end

function write_input_bindings()
    local x = mp.get_property_native('input-bindings')
    local j = utils.format_json(x)
    local path = '/Users/mhindman/Downloads/input-bindings.json'
    local fh = io.open(path, 'w')
    fh:write(j)
    fh:close()
end

function main()

    if app.keys_bound then
        mp.remove_key_binding('set-loop-start')
        mp.remove_key_binding('set-loop-stop')
        mp.remove_key_binding('toggle-looping')
        mp.remove_key_binding('clear-menu')
        app.keys_bound = false
        message('bindings cleared')
    else
        mp.add_forced_key_binding('[', 'set-loop-start', set_loop_start)
        mp.add_forced_key_binding(']', 'set-loop-stop', set_loop_stop)
        mp.add_forced_key_binding('l-l', 'toggle-looping', toggle_looping)
        mp.add_forced_key_binding('ESC', 'clear-menu', clearMenu)
        app.keys_bound = true
        log('hello', 'world')
    end
end

mp.add_forced_key_binding('L', 'toggle-app-bindings', main)

