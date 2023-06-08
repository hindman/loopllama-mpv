
function main()
end

--
-- How-to stuff. Add to lua notes.
--

function command_line_args()
    print(dump(arg))
end

function string_joining()
    local xs = {'hello', 'world'}
    local txt = table.concat(xs, ' - ')
end

function io_examples()
    io.write('Enter x: ')
    local x = io.stdin:read()
    local msg = "'" .. x .. "'"
    io.stdout:write(msg)
    print(msg)
end

function parsing_cli()
    local txt = table.concat(arg, ' ')
    local xs, n = parse_words(txt)
    xs.n = n
    print(dump(xs))
end

--
-- How-to create and use a class.
--

Account = {}

function Account:new(v)
    local o = {balance = v or 0}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Account:deposit(v)
    self.balance = self.balance + v
end

function Account:withdraw(v)
  if v > self.balance then
      error('Account:withdraw(): insufficient funds')
  else
      self.balance = self.balance - v
  end
end

function account_demo()
    local a1 = Account:new(100)
    local a2 = Account:new()
    a1:withdraw(37)
    a2:deposit(42)
    print(dump(a1))
    print(dump(a2))
    local ok, err = pcall(Account.withdraw, a2, 999)
    if not ok then
        print(err)
    end
end

--
-- Misc.
--

function flintstones()
    return {
       {
          name = "Fred",
          address = "16 Long Street",
          phone = 123456,
          cool = false,
          fact = nil,
       },
       {
          name = "Wilma",
          address = "16 Long Street",
          phone = 123456,
          cool = false,
       },
       {
          name = "Barney",
          address = "17 Long Street",
          phone = 123457,
          cool = true,
       }
    }
end

--
-- Useful utility functions.
--

function trim(txt)
    -- Takes some text.
    -- Returns it trimmed of whitespace.
   return txt:match('^%s*(.-)%s*$')
end

function parse_words(txt)
    -- Takes some text.
    -- Returns table of words and N of them.
    local xs = {}
    for x in txt:gmatch('%S+') do
        table.insert(xs, x)
    end
    return xs, #xs
end

function dump(x, level)
    -- Handle non-table.
    if type(x) ~= 'table' then
        return repr(x)
    end
    -- Set up indentation.
    level = level or 0
    local ind0 = string.rep(' ', 4 * level)
    local ind1 = ind0 .. string.rep(' ', 4)
    -- Table start; indented key-value lines; table end.
    local txt = '{\n'
    for k, v in pairs(x) do
        local kv = '[' .. repr(k) .. '] = ' .. dump(v, level + 1)
        txt = txt .. ind1 .. kv .. ',\n'
    end
    return txt .. ind0 .. '}'
end

function repr(x)
    -- Mimics Python repr(), at least for strings.
    if type(x) == 'string' then
        return '"' .. x .. '"'
    else
        return tostring(x)
    end
end

main()


