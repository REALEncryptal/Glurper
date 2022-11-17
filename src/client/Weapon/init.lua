local Weapon = {}
Weapon.__index = Weapon

local TweenService = game:GetService("TweenService")

Weapon.Spring = require(script.Parent.Spring)
Weapon.Input = require(script.Parent.Input)
Weapon.Animator = require(script.Parent.Animator)
Weapon.SpringEffects = require(script.Parent.SpringEffects)
Weapon.CharacterUtils = require(script.Parent.CharacterUtils)

function Weapon.new(WeaponModel)
	local self = setmetatable({},Weapon)

	self.Model = WeaponModel:Clone()
	self.Model.Parent = workspace.CurrentCamera

	self.Animator = Weapon.Animator.new(self.Model, self.Model.Animations:GetChildren())
	self.Springs = {
		["Idle"] = Weapon.Spring.new(),
		["Swaying"] = Weapon.Spring.new(),
		["Bobbing"] = Weapon.Spring.new(),
		["Movement"] = Weapon.Spring.new(),
		["Recoil"] = Weapon.Spring.new()
	}
	self.Data = self.Model:FindFirstChild("WeaponData"):GetAtrributes()
	
	self.Equipping = false
	self.Equipped = false
	self.CanReload = true
	self.Reloading = false
	self.CanFire = true
	self.Ads = self.Data.CanADS
	self.CanAds = true
	self.Offsets = {
		["_Idle"] = self.Data.Offset,
		["_Equip"] = CFrame.new(0,1000,0)
	}
	
	self.TotalBullets = (self.Data.BulletsPerMag * self.Data.Bullets.Mags) - self.Data.BulletsPerMag -- this way it comes preloaded with bullets
	self.Bullets = self.Data.BulletsPerMag

	-- Input
	self.MouseDown = false

	Weapon.Input:Bind(Enum.UserInputType.MouseButton1, function(began) -- Left Click shooting
		self.MouseDown = began
	end)

	Weapon.Input:Bind(Enum.UserInputType.MouseButton2, function(began) -- right click aiming
		self:Aim(began)
	end)

	Weapon.Input:Bind(Enum.KeyCode.R, function(began) -- R for reloading
		if began then
			self:Reload()
		end
	end)

	return self
end

function Weapon:Reload()
	if
		self.Equipped
		and not self.Equipping
		and not self.Reloading
		and not self.Bullets == self.Data.BulletsPerMag
		and not self.TotalBullets == 0
	then
		self.Reloading = true
		self.CanFire = false

		self.Animator:LengthPlay("Reload", self.Data.ReloadTime)
		task.wait(self.Data.ReloadTime)

		if not self.Equipped then return end
		if self.Equipping then return end
		if not self.Reloading then return end

		self.TotalBullets -= self.Data.BulletsPerMag - self.Bullets
		self.Bullets = self.Data.BulletsPerMag

		self.Reloading = false
		self.CanFire = true
	end
end

function Weapon:Aim(IsAiming)
	
end

function Weapon:Fire()
	
end

function Weapon:Equip(IsEquipping)
	IsEquipping = IsEquipping or true
	if IsEquipping then
		if not self.Equipped then
			self.Equipped = true
			self.Equipping = true

			-- Tween weapon up in thread
			task.spawn(function()
				local OffsetObject = Instance.new("CFrameValue")
				OffsetObject.Value = CFrame.new(0,-10,0)
				self.Offsets["_Equip"] = CFrame.new()
				self.Offsets["EquipOffset"] = OffsetObject

				TweenService:Create(
					OffsetObject,
					TweenInfo.new(
						self.Data.EquipTime,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.Out
					),
					{Value = CFrame.new(0,0,0)}
				)

				task.wait(self.Data.EquipTime)

				table.remove(self.Offsets, table.find(self.Offsets, OffsetObject))
				OffsetObject:Destroy()
			end)

			-- Play Animation
			self.Animator:Play("Idle")
			self.Animator:LengthPlay("Equip", self.Data.EquipTime)
			task.wait(self.Data.EquipTime)
			self.Animator:Stop("Equip")

			self.Equipping = false
		end
	else -- Unequip
		self.Equipping = false
		self.Equipped = false

		self.Offsets["_Equip"] = CFrame.new(0, 1000, 0)
	end
end

function Weapon:Update(DeltaTime)
	if self.Equipped then
		-- Inputs

		task.spawn(function() -- Shooting
			if self.MouseDown then
				if self.CanFire and not self.Equipping and not self.Reloading then
					self.CanFire = false
					if not self.Data.Automatic then
						self.MouseDown = false
					end
	
					print("Shoot")
				end
			end
		end)

		-- Visuals
		if Weapon.CharacterUtils.IsGrounded() and Weapon.CharacterUtils.IsMoving() then -- Moving Bob
			self.Springs.Bobbing:Shove(Weapon.SpringEffects.Bobbing(1, 1, 1, Weapon.CharacterUtils.MoveSpeed()))
		end

		if Weapon.CharacterUtils.IsGrounded() and not Weapon.CharacterUtils.IsMoving() then -- not moving breathing bob
			self.Springs.Idle:Shove(Weapon.SpringEffects.Bobbing(.5, .5, .4, 1))
		end

		self.Springs.Swaying:Shove(Weapon.SpringEffects.Sway(1,-1))

		-- Update Springs
		self.Offsets["BobbingSpring"] = CFrame.new(self.Springs.Bobbing:Update(DeltaTime))
		self.Offsets["IdleSpring"] = CFrame.new(self.Springs.Idle:Update(DeltaTime))
		self.Offsets["SwayingSpring"] = CFrame.new(self.Springs.Swaying:Update(DeltaTime))

	end

	-- Loop through offset list and check if the offset is a Camera offset. Apply offset accordingly
	local CameraOffset = CFrame.new()
	local ViewmodelOffset = CFrame.new

	for Name,Offset in pairs(self.Offsets) do
		Name = tostring(Name)

		if Offset:IsA("CFrameValue") then
			if #Name >= 4 and string.sub(Name,1,4) == "Camera" then
				CameraOffset *= Offset.Value
			else
				ViewmodelOffset *= Offset.Value
			end
		else
			if #Name >= 4 and string.sub(Name,1,4) == "Camera" then
				CameraOffset *= Offset
			else
				ViewmodelOffset *= Offset
			end
		end
	end

	workspace.CurrentCamera.CFrame *= CameraOffset
	self.Model.PrimaryPart.CFrame *= workspace.CurrentCamera.CFrame * ViewmodelOffset
end

return Weapon