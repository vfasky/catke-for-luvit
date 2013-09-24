local tokenizer = require('../kernel').tokenizer

-- Basic code coverage to exercise all conditionals in tokenizer
local tests = {
  ["{world}"] = {{start=1,stop=7,name="world"}},
  ["{world}."] = {{start=1,stop=7,name="world"},"."},
  ["Hello {world}."] = {'Hello ',{start=7,stop=13,name='world'},'.'},
  ["Hello {world(1,2)}."] = {'Hello ',{start=7,stop=18,name='world',args="1,2"},'.'},
  ["Hello {/world}."] = {'Hello ',{start=7,stop=14,name='world',close=true},'.'},
  ["Hello {#world}."] = {'Hello ',{start=7,stop=14,name='world',open=true},'.'},
  ["Hello {#world(1,2)}."] = {'Hello ',{start=7,stop=19,name='world',args="1,2",open=true},'.'},
  ["{fun(Math.sin(Math.PI))}"] = {{start=1,stop=24,name="fun",args="Math.sin(Math.PI)"}},
  [".{test.with}."] = { ".", { stop = 12, start = 2, name = "test.with" }, "." },
  [".{test.with.more}."] = { ".", { stop = 17, start = 2, name = "test.with.more" }, "." },
  [".{{this is arbitrary()}}."] = { ".", { stop = 24, start = 2, name = "this is arbitrary()" }, "." },
}

function deep_equal(expected, actual)
  if not (#expected == #actual) then return end
  for i, token in ipairs(expected) do
    if type(token) == "string" then
      if not (token == actual[i]) then return end
    else
      for name, value in pairs(token) do
        if not (value == actual[i][name]) then return end
      end
      for name in pairs(actual[i]) do
        if not token[name] then return end
      end
    end
  end
  return true
end

for input,output in pairs(tests) do
  local tokens = tokenizer(input)
  if not deep_equal(output,tokens) then
    p("Expected", output)
    p("But got", tokens)
    error("Test failed " .. input)
  end
end
