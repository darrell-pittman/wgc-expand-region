-- @module A stack that has a maximum capacity. If an item is
-- pushed on stack that puts it over-capacity then the deepest
-- item in the stack will be removed.
local M = {}
M.__index = M

--- @class Stack
--- @field push function: Adds item to stack
--- @field pop function: Removes item from top of stack and returns it
--- @field peek function: Returns item at top of stack but does not remove it

--- Constructs a new stack
--- @param capacity integer: Capacity of stack
--- @return Stack
M.new = function(capacity)
  local o = {
    capacity = capacity,
    first = 1,
    last = 0,
  }
  setmetatable(o, M)
  return o
end

--- Adds item to top of stack
--- @param v any: Value to be added to top of stack
--- @return nil
function M:push(v)
  self.last = self.last + 1
  self[self.last] = v
  if (self.last - self.first + 1) > self.capacity then
    self[self.first] = nil
    self.first = self.first + 1
  end
end

--- Removes item from top of stack and returns it
--- @return any?: Item that was returned from top of stack or nil if stack
--- is empty
function M:pop()
  if self.last < self.first then
    return nil
  end
  local v = self[self.last]
  self[self.last] = nil
  self.last = self.last - 1
  return v
end

--- Returns item at top of stack but leaves item on stack
--- @return any?: Item at top of stack or nil if stack is empty
function M:peek()
  return self[self.last]
end

--- Clears the stack
--- @return nil
function M:clear()
  for i = 1, #self do
    self[i] = nil
  end
  self.first = 1
  self.last = 0
end

return M
