-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Modules
local WeaponClass = require(script.Weapon)
local CameraUtil = require(script.Camera)

-- Varibles
local Weapons = {
    [1] = false,
    [2] = false,
    [3] = false
}
local CurrentSlot = 0
local CurrentWeapon = nil

-- Functions

function Equip(Slot)
    if CurrentSlot == Slot then return true end
    pcall(function()
        CurrentWeapon:Equip(false)
    end)
    

    CurrentWeapon = Weapons[Slot]
    CurrentSlot = Slot
    CurrentWeapon:Equip(true)
end

function AddGun(Slot, Name)
    if Weapons[Slot] then
        Weapons[Slot]:Equip(false)
    end

    Weapons[Slot] = WeaponClass.new(ReplicatedStorage.Weapons:FindFirstChild(Name))
end

-- Client

AddGun(1, "M4A1")
AddGun(2, "M4A1")
AddGun(3, "M4A1")

-- main loop
WeaponClass.Input:Bind(Enum.KeyCode.One, function(began)
    if not began then return true end
    Equip(1)
    return true
end)

WeaponClass.Input:Bind(Enum.KeyCode.Two, function(began)
    if not began then return true end
    Equip(2)
    return true
end)

WeaponClass.Input:Bind(Enum.KeyCode.Three, function(began)
    if not began then return true end
    Equip(3)
    return true
end)


RunService.RenderStepped:Connect(function(deltaTime)
    for _,Weapon in pairs(Weapons) do
        if Weapon then
        Weapon:Update(deltaTime)
        end
    end
end)


