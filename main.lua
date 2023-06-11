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

local CON = {
    app = 'LoopLlama',
}

local DEFS = {
    empty = '_',
    msg_duration = 2,
}

local PROPS = {
    time_pos = 'time-pos',
    disable_ass_seq = 'osd-ass-cc/0',
    enable_ass_seq = 'osd-ass-cc/1',
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
        display(err)
    else
        display(t.prefix .. reply .. ' ' .. t.val)
    end
end

function get_reply(prompt, handler, default_reply, data_to_handler)
    -- See get_user_input() docs for other properties, but
    -- the basic ones are shown here.
    local t = {
        request_text = prompt,
        default_input = default_reply,
        source = CON.app,
    }
    input.get_user_input(handler, t, data_to_handler)
end

--
-- Utilities.
--

function log(...)
    mp.msg.log('info', ...)
end

function iff(cond, a, b)
    if cond then
        return a
    else
        return b
    end
end

function rounded(n, digits, default)
    if n then
        local fmt = string.format('%%0.%sf', digits)
        return string.format(fmt, n)
    else
        return default
    end
end

function get_current_pos()
    return mp.get_property_number(PROPS.time_pos)
end

function to_json(x)
    -- Convert object to JSON.
    return utils.format_json(x)
end

function write_file(txt, path)
    -- Write text to a file.
    local fh = io.open(path, 'w')
    fh:write(txt)
    fh:close()
end

--
-- Displaying text on screen.
--

function display(text, duration, allow_ass_seq)
    local ass = mp.get_property_osd(iff(
        allow_ass_seq,
        PROPS.enable_ass_seq,
        PROPS.disable_ass_seq
    ))
    return mp.osd_message(ass .. text, duration or DEFS.msg_duration)
end

function clear_display()
    local w, h = mp.get_osd_size()
    mp.set_osd_ass(w, h, '')
    mp.osd_message('', 0)
end

function display_current_loop()
    local msg = table.concat({
        'Loop: ',
        rounded(vi.start, 2, DEFS.empty),
        ' - ',
        rounded(vi.stop, 2, DEFS.empty),
        ' [',
        iff(vi.loop, 'on', 'off'),
        ']',
    })
    clear_display()
    display(msg)
end

function display_marks()
    local msg = table.concat({
        'Marks: ',
        rounded(vi.m1, 2, DEFS.empty),
        ' / ',
        rounded(vi.m2, 2, DEFS.empty),
    })
    clear_display()
    display(msg)
end

function display_mark(n)
    local m = 'm' .. n
    local msg = table.concat({
        'Mark ',
        n,
        ': ',
        rounded(vi[m], 2, DEFS.empty),
    })
    clear_display()
    display(msg)
end

--
-- Manage settings for current loop.
--

function set_loop_start()
    vi.start = get_current_pos()
    display_current_loop()
end

function set_loop_stop()
    vi.stop = get_current_pos()
    display_current_loop()
end

function toggle_looping()
    local observer = on_timepos_change
    if vi.loop then
        -- Turn off looping.
        vi.loop = false
        mp.unobserve_property(observer)
        display_current_loop()
    elseif vi.start and vi.stop then
        -- Turn on looping if start/stop are defined.
        vi.loop = true
        mp.observe_property(PROPS.time_pos, 'string', observer)
        display_current_loop()
    end
end

function on_timepos_change()
    local curr = get_current_pos()
    if curr and (curr < vi.start or vi.stop < curr) then
        seek_to(vi.start)
    end
end

function seek_to(pos)
    mp.set_property_native(PROPS.time_pos, pos)
end

--
-- Manage marks.
--

function manage_marks()
    get_reply('Enter mark N: ', manage_marks_handler, nil, get_current_pos())
end

function manage_marks_handler(reply, err, curr)
    if not err and (reply == '1' or reply == '2') then
        local m = 'm' .. reply
        vi[m] = curr
        display_marks()
    end
end

function jump_to_mark(n)
    local m = 'm' .. n
    if vi[m] then
        seek_to(vi[m])
        display_mark(n)
    end
end

function jump_to_mark_1() jump_to_mark(1) end
function jump_to_mark_2() jump_to_mark(2) end

--
-- Set or unset the application's key bindings.
--

function toggle_app_bindings()
    -- Key bindings.
    local bindings = {
        {key = '[', name = 'set-loop-start', func = set_loop_start},
        {key = ']', name = 'set-loop-stop', func = set_loop_stop},
        {key = 'l-l', name = 'toggle-looping', func = toggle_looping},
        {key = 'l-m', name = 'manage-marks', func = manage_marks},
        {key = 'KP1', name = 'jump-to-mark-1', func = jump_to_mark_1},
        {key = 'KP2', name = 'jump-to-mark-2', func = jump_to_mark_2},
        {key = 'ESC', name = 'clear-display', func = clear_display},
    }
    -- Set or unset the bindings.
    for _, b in ipairs(bindings) do
        if app.keys_bound then
            mp.remove_key_binding(b.name)
        else
            mp.add_forced_key_binding(b.key, b.name, b.func)
        end
    end
    -- Toggle state.
    app.keys_bound = not app.keys_bound
    display(CON.app .. iff(app.keys_bound, ' on', ' off'))
end

mp.add_forced_key_binding('L', 'toggle-app-bindings', toggle_app_bindings)

