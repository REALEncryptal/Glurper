local animation = {} -- stolen from exploire
animation.__index = animation

function animation.new(model, animationsList)
	local self = setmetatable({},animation)

	self.model = model
	self.animator = model:FindFirstChild("Animator", true)

  self.cache = {}
  for name, id in pairs(animationsList) do
    if id:IsA("Animation") then
      self.cache[id.Name] = self.animator:LoadAnimation(id)
    else
      local anim = Instance.new("Animation")
      anim.AnimationId = "rbxassetid://"..tostring(id)
      self.cache[name] = self.animator:LoadAnimation(anim)
    end
  end 

	return self
end

function animation:LoadAnimation(name, id)
  if id:IsA("Animation") then
    self.cache[name] = self.animator:LoadAnimation(id)
  else
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..tostring(id)
    self.cache[name] = self.animator:LoadAnimation(anim)
  end
end

function animation:Play(name, speed)
  speed = speed or 1
	self.cache[name]:AdjustSpeed(speed)
  self.cache[name]:Play()
  self.cache[name]:AdjustSpeed(1)
  return self.cache[name].Length
end

function animation:LengthPlay(name, length)
	self.cache[name]:AdjustSpeed(self.cache[name].Length/length)
  self.cache[name]:Play()
  self.cache[name]:AdjustSpeed(1)
end

function animation:FreezeAtFrame(name, time)
  self.cache[name]:AdjustSpeed(0)
  self.cache[name]:Play()
  self.cache[name].TimePosition = time or 0
end

function animation:Stop(name)
  self.cache[name]:Stop()
end

function animation:StopAll()
  for _,anim in pairs(self.cache) do
    anim:Stop()
  end
end

function animation:GetAnimation(name)
  return self.cache[name]
end

return animation
