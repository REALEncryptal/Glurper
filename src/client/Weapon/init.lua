local Weapon = {}
Weapon.__index = Weapon

local TweenService = game:GetService("TweenService")

Weapon.Spring = require(script.Spring)
Weapon.Input = require(script.Input)
Weapon.Animator = require(script.Animator)
Weapon.SpringEffects = require(script.SpringEffects)
Weapon.CharacterUtils = require(script.CharacterUtils)
Weapon.Debug = require(script.Parent.Debug)
Weapon.Audio = require(game:GetService("ReplicatedStorage").Common.Modules.Audio)

function Weapon.new(WeaponModel)
	local self = setmetatable({},Weapon)

	self.Model = WeaponModel:Clone()
	--self.Model.Shirt.ShirtTemplate = game.Players.LocalPlayer.Character:WaitForChild("Shirt").ShirtTemplate
	self.Model.Parent = workspace.CurrentCamera

	self.Animator = Weapon.Animator.new(self.Model, self.Model:FindFirstChild("Animations"):GetAttributes())
	
	self.Springs = {
		["Idle"] = Weapon.Spring.new(),
		["Swaying"] = Weapon.Spring.new(),
		["Bobbing"] = Weapon.Spring.new(),
		["Movement"] = Weapon.Spring.new(),
		["Recoil"] = Weapon.Spring.new()
	}
	self.Data = self.Model:FindFirstChild("WeaponData"):GetAttributes()
	self.Sounds = self.Model:WaitForChild("Sounds")	
	
	self.Equipping = false
	self.Equipped = false
	self.CanReload = true
	self.Reloading = false
	self.CanFire = true
	self.Ads = self.Data.CanADS
	self.Rpm = self.Data.Rpm
	self.Automatic = self.Data.Automatic
	self.CanAds = true
	self.Offsets = {
		["_Idle"] = self.Data.Offset,
		["_Equip"] = CFrame.new(0,1000,0)
	}
	
	self.TotalBullets = (self.Data.BulletsPerMag * self.Data.Mags) - self.Data.BulletsPerMag -- this way it comes preloaded with bullets
	self.Bullets = self.Data.BulletsPerMag

	-- Input
	self.MouseDown = false

	Weapon.Input:Bind(Enum.UserInputType.MouseButton1, function(began) -- Left Click shooting
		self.MouseDown = began
		return true	
	end)

	Weapon.Input:Bind(Enum.UserInputType.MouseButton2, function(began) -- right click aiming
		self:Aim(began)
		return true		
	end)

	Weapon.Input:Bind(Enum.KeyCode.R, function(began) -- R for reloading
		if began then
			self:Reload()
		end

		return true	
	end)

	return self
end

function Weapon:Reload()
	if
		self.Equipped
		and not self.Equipping
		and not self.Reloading
		and not (self.Bullets == self.Data.BulletsPerMag)
		and not (self.TotalBullets == 0)
	then
		task.spawn(function()
			print("Reloading")
			self.Reloading = true
			self.CanFire = false

			Weapon.Audio.Play(self.Sounds.Reload, workspace.CurrentCamera)
			self.Animator:LengthPlay("Equip", self.Data.ReloadTime)
			task.wait(self.Data.ReloadTime)

			if not self.Equipped then return end
			if self.Equipping then return end
			if not self.Reloading then return end

			self.TotalBullets -= self.Data.BulletsPerMag - self.Bullets
			self.Bullets = self.Data.BulletsPerMag

			self.Reloading = false
			self.CanFire = true
		end)
	end
end

function Weapon:Aim(IsAiming)
	
end

function Weapon:Fire()
	if 
		self.Equipped
		and self.CanFire
		and not self.Reloading
		and not self.Equipping
		and self.Bullets > 0
		and self.MouseDown
	then
		task.spawn(function()
			if not self.Automatic then 
				self.MouseDown = false
			end
	
			self.CanFire = false
			self.Bullets -= 1
			self.TotalBullets -= 1
			self.Animator:Play("Fire")
			Weapon.Audio.Play(self.Sounds.Fire, workspace.CurrentCamera)

			self.Springs.Recoil:Shove(Weapon.SpringEffects.Recoil(self.Data.RecoilX, self.Data.RecoilY) + Vector3.new(0,0,2))

			task.wait(60/self.Rpm)

			self.CanFire = true
			print(self.Bullets)
		end)
	end
end

function Weapon:Equip(IsEquipping)
	print(IsEquipping)
	if IsEquipping then
		if not self.Equipped then
			self.Equipped = true
			self.Equipping = true
			-- Tween weapon up in thread
			task.spawn(function()
				local OffsetObject = Instance.new("CFrameValue")
				OffsetObject.Value = CFrame.new(0,-2,0)
				self.Offsets["_Equip"] = CFrame.new()
				self.Offsets["EquipOffset"] = OffsetObject

				self.Animator:Play("Idle")
				self.Animator:LengthPlay("Equip", self.Data.EquipTime)
				Weapon.Audio.Play(self.Sounds.Equip, workspace.CurrentCamera)
				TweenService:Create(
					OffsetObject,
					TweenInfo.new(
						self.Data.EquipTime,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.Out
					),
					{Value = CFrame.new(0,0,0)}
				):Play()

				task.wait(self.Data.EquipTime)
				self.Equipping = false
				table.remove(self.Offsets, table.find(self.Offsets, OffsetObject))
				OffsetObject:Destroy()
			end)
		end
	else -- Unequip
		self.Equipping = false
		print("Nien")
		self.Equipped = false

		self.Offsets["_Equip"] = CFrame.new(0, 1000, 0)
		
	end
end

function Weapon:Update(DeltaTime)
	Weapon.Debug.DestroyAll()
	if self.Equipped then
		self:Fire()

		-- Visuals
		if Weapon.CharacterUtils.IsGrounded() and Weapon.CharacterUtils.IsMoving() then -- Moving Bob
			self.Springs.Bobbing:Shove(Weapon.SpringEffects.Bobbing(.5, .5, 1.5, 1))--Weapon.CharacterUtils.MoveSpeed()))
		end

		if Weapon.CharacterUtils.IsGrounded() and not Weapon.CharacterUtils.IsMoving() then -- not moving breathing bob
			self.Springs.Idle:Shove(Weapon.SpringEffects.Bobbing(.2, .4, .2, 1))
		end

		self.Springs.Swaying:Shove(Weapon.SpringEffects.Sway(1,-1))

		-- Update Springs
		self.Offsets["BobbingSpring"] = CFrame.new(self.Springs.Bobbing:Update(DeltaTime))
		self.Offsets["IdleSpring"] = CFrame.new(self.Springs.Idle:Update(DeltaTime))
		self.Offsets["SwayingSpring"] = CFrame.new(self.Springs.Swaying:Update(DeltaTime))

		local Recoil = self.Springs.Recoil:Update(DeltaTime)
		self.Offsets["CameraRecoilSpring"] = CFrame.Angles(math.rad(Recoil.Y),math.rad(Recoil.X),math.rad(Recoil.Z))
		-- Debug List

		Weapon.Debug.Insert("Equipped",self.Equipped)
		Weapon.Debug.Insert("Equipping",self.Equipping)
		Weapon.Debug.Insert("CanFire",self.CanFire)
		Weapon.Debug.Insert("CanAds",self.CanADS)
		Weapon.Debug.Insert("CanReload",self.CanReload)
		Weapon.Debug.Insert("Ammo",self.Bullets)
		Weapon.Debug.Insert("TotalAmmo",self.TotalAmmo)
		Weapon.Debug.Insert("Equipped",self.Equipped)
		Weapon.Debug.Insert("MouseDown",self.MouseDown)
	end
	-- Loop through offset list and check if the offset is a Camera offset. Apply offset accordingly
	local CameraOffset = CFrame.new()
	local ViewmodelOffset = CFrame.new()

	for Name,Offset in pairs(self.Offsets) do
		Name = tostring(Name)
		
		if typeof(Offset) == "CFrame" then
			if #Name >= 4 and string.sub(Name,1,6) == "Camera" then
				CameraOffset *= Offset
			else
				ViewmodelOffset *= Offset
			end
		else
			if #Name >= 4 and string.sub(Name,1,6) == "Camera" then
				CameraOffset *= Offset.Value
			else
				ViewmodelOffset *= Offset.Value
			end
		end
	end
	
	-- Apply Offsets
	workspace.CurrentCamera.CFrame *= CameraOffset
	self.Model.PrimaryPart.CFrame = workspace.CurrentCamera.CFrame * ViewmodelOffset
end

return Weapon