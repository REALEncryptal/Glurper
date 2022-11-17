--[[

    General functions for the character that i find myself repeating
     - Encryptal

]]

local CharacterUtils = {}
CharacterUtils.Character = nil

function Vector3RemoveY(Vector) : Vector3
    return Vector3.new(
        Vector.X,
        0,
        Vector.Z
    )
end

function CharacterUtils.IsMoving() : boolean
    return 
        CharacterUtils.Character.Humanoid.MoveDirection.Magnitude > 0 
        and Vector3RemoveY(CharacterUtils.Character.PrimaryPart.AssemblyLinearVelocity).Magnitude > 0
end

function CharacterUtils.MoveSpeed() : number
    return 
        Vector3RemoveY(CharacterUtils.Character.PrimaryPart.AssemblyLinearVelocity)
        * CharacterUtils.Character.Humanoid.MoveDirection.Magnitude
end

function CharacterUtils.IsGrounded() : boolean
    return CharacterUtils.Character.Humanoid.FloorMaterial ~= Enum.Material.Air
end

function CharacterUtils.IsFalling() : boolean
    return
        CharacterUtils.Character.Humanoid.FloorMaterial == Enum.Material.Air
        and CharacterUtils.Character.PrimaryPart.AssemblyLinearVelocity.Y < 0
end

function CharacterUtils.YVelocity() : number
    return
        CharacterUtils.Character.PrimaryPart.AssemblyLinearVelocity.Y
end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(Character)
    CharacterUtils.Character = Character
end)

return CharacterUtils