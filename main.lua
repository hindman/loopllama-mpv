
--[[


LL enable/disable LoopLlama


Category    | Lua | Shortcut  | Operation
-----------------------------------------------------------------------
Play video  | .   | .         | .
.           | .   | F         | Set or switch to a favorite video
Navigation  | .   | .         | .
.           | .   | 0 or UP   | Go to video start (or loop start, if looping)
Looping     | .   | .         | .
.           | .   | L         | Toggle looping on/off
.           | .   | [         | Set loop start to current time
.           | .   | SHIFT-[   | Set, nudge, or reset loop start (prompted)
.           | .   | ]         | Set loop end to current time
.           | .   | SHIFT-]   | Set, nudge, or reset loop end (prompted)
.           | .   | SHIFT-L   | Saved loops: load, save, or reset (prompted)
Marks       | .   | .         | .
.           | .   | 1         | Go to mark 1
.           | .   | SHIFT-1   | Set, nudge, or reset mark 1
Application | .   | .         | .
.           | .   | H         | Display/hide help text


Key bindings:

    - Except as noted, no modifier keys are used.

    - The user needs this in input.conf: `l ignore`.

    # Toggle the script's bindings.
    L    LoopLlama toggle              # SHIFT

    # Jump.
    0    to start
    1-9  to mark

    # Simple looping.
    [    set loop start
    ]    set loop end
    l-l  toggle looping

    # Manage settings.
    l-p  loop start/end points
    l-f  favorites
    l-m  marks
    l-s  saved loops

    # Information.
    l-h  help on key bindings
    l-i  info on current loop, favs, marks, saved loops

    # Manage settings: user prompt syntax:

        - Loop start/end points:

            Where X: s|start|e|end

            set-to-current-pos | X .
            set-to-value       | X M:SS
            nudge              | X N
            reset              | X -

        - Favorites:

            Where K: favorite key

            switch-to      | K
            set-to-current | K .
            set-to-path    | K PATH
            unset          | K -

        - Marks:

            Where M: mark number

            jump-to            | M
            set-to-current-pos | M .
            set-to-value       | M M:SS
            nudge              | M N
            unset              | M -

        - Saved loops:

            Where K: saved loop key

            load              | K
            save-current-loop | K .
            save-loop         | K M:SS M:SS
            nudge-saved       | K N N
            unset             | K -

--]]

local mp = require('mp')
local utils = require('mp.utils')
local assdraw = require('mp.assdraw')

local EMPTY = '_'

local options = {
    keybind = 'L',
    message_duration = 2
}

local ab = {start = nil, stop = nil}
looping = false

function message(text, duration)
    local ass = mp.get_property_osd('osd-ass-cc/0')
    ass = ass .. text
    return mp.osd_message(ass, duration or options.message_duration)
end

function drawMenu()
    local window_w, window_h = mp.get_osd_size()
    local ass = assdraw.ass_new()
    ass:new_event()
    ass:append(" \\N\\N")
    ass:append("{\\b1}Multiloop{\\b0}\\N")
    ass:append("{\\b1}1{\\b0} set start time\\N")
    ass:append("{\\b1}2{\\b0} set end time\\N")
    ass:append("{\\b1}l{\\b0} loop / end loop\\N")
    ass:append("{\\b1}ESC{\\b0} hide\\N")
    mp.set_osd_ass(window_w, window_h, ass.text)
end

function clearMenu()
    local window_w, window_h = mp.get_osd_size()
    mp.set_osd_ass(window_w, window_h, '')
    mp.osd_message('', 0)
end

function iif(predicate, a, b)
    if predicate then
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

function displayLoop()
    local msg = table.concat({
        'Loop: ',
        rounded(ab.start, 2, EMPTY),
        ' - ',
        rounded(ab.stop, 2, EMPTY),
        ' [',
        iif(looping, 'on', 'off'),
        ']',
    })
    clearMenu()
    message(msg)
end

function setStartTime()
    ab.start = mp.get_property_number('time-pos')
    displayLoop()
end

function setEndTime()
    ab.stop = mp.get_property_number('time-pos')
    displayLoop()
end

function on_timepos_change()
    local curr = mp.get_property_number('time-pos')
    if ab.stop and curr and curr >= ab.stop then
        mp.set_property_native('time-pos', ab.start)
    end
end

function loop()
    if looping == false then
        if ab.start and ab.stop then
            looping = true
            mp.observe_property('time-pos', 'string', on_timepos_change)
            displayLoop()
        end
    else
        looping = false
        mp.unobserve_property(on_timepos_change)
        displayLoop()
    end
end

function dolog(x)
    mp.msg.log('info', x)
end

function write_input_bindings()
    local x = mp.get_property_native('input-bindings')
    local j = utils.format_json(x)
    -- local path = 'file://~/down/input-bindings.json'
    local path = '/Users/mhindman/Downloads/input-bindings.json'
    local fh = io.open(path, 'w')
    fh:write(j)
    fh:close()
end

local keys_bound = false

function main()

    -- local r = mp.command_native({
    --     name = "subprocess",
    --     playback_only = false,
    --     capture_stdout = true,
    --     args = {"cat", "/proc/cpuinfo"},
    -- })
    -- if r.status == 0 then
    --     print("result: " .. r.stdout)
    -- end

    -- mp.comand_native({
    --     key = "l",
    --     section = "default",
    --     cmd = "ignore",
    --     priority = 11,
    --     is_weak = false,
    -- })

    if keys_bound then
        mp.remove_key_binding('set-start-time')
        mp.remove_key_binding('set-end-time')
        mp.remove_key_binding('toggle-loop')
        mp.remove_key_binding('clear-menu')
        keys_bound = false
        message('bindings cleared')
    else
        mp.add_forced_key_binding('[', 'set-start-time', setStartTime)
        mp.add_forced_key_binding(']', 'set-end-time', setEndTime)
        mp.add_forced_key_binding('l-l', 'toggle-loop', loop)
        mp.add_forced_key_binding('l-f', 'favorites', favorites)
        mp.add_forced_key_binding('ESC', 'clear-menu', clearMenu)
        keys_bound = true
        drawMenu()
    end
end

function blort(x, y, z)
    dolog(x)
    dolog(y)
    dolog(z)
    message('blort')
end

function favorites()
    message('favorites')
end

-- mp.add_key_binding(options.keybind, 'display-multiloop', main)
mp.add_forced_key_binding("L", 'display-multiloop', main)

