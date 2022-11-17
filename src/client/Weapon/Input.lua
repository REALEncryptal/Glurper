local Input = {} -- stolen from explore
Input.__index = Input

local UIS = game:GetService("UserInputService")

function Input.new()
	local self = setmetatable({},Input)
	
  self.Hooks = {}
  self.UiHooks = {}

  self.BeganConnection = UIS.InputBegan:Connect(function(input)
    if self.Hooks[input.UserInputType] then
      self:RunHooks(self.Hooks[input.UserInputType], true)
    end
    if self.Hooks[input.KeyCode] then
      self:RunHooks(self.Hooks[input.KeyCode], true)
    end
  end)

  self.EndConnection = UIS.InputEnded:Connect(function(input)
    if self.Hooks[input.UserInputType] then
      self:RunHooks(self.Hooks[input.UserInputType], false)
    end
    if self.Hooks[input.KeyCode] then
      self:RunHooks(self.Hooks[input.KeyCode], false)
    end
  end)

	return self
end

function Input:Bind(Key, Callback, UiButton:TextButton)
  UiButton = UiButton or nil

	if not self.Hooks[Key] then
    self.Hooks[Key] = {}
  end

  if UiButton then -- For mobile support
    table.insert(self.MobileHooks[Key], self.Hooks[Key])
  end

  table.insert(self.Hooks[Key], Callback)
end

function Input:RunHooks(Funcs, Began)
  for i,Func in pairs(Funcs) do
    if not Func(Began) then
      table.remove(Funcs, i)
    end
  end
end

function Input:Clear()
  self.Hooks = {}
end

return Input.new()
