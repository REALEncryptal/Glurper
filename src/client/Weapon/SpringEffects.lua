local SpringEffects = {}
local UserInputService = game:GetService("UserInputService")

function SpringEffects.Bobbing(XSize:number, YSize:number, Frequency:number, Magnifier:number) : Vector3
    local Freq = 10
    local Mag = .1

    return Vector3.new(
        math.cos(
            tick() * Frequency * Freq
        ) * XSize * Magnifier * Mag,
        math.sin(
            tick() * Frequency * Freq
        ) * YSize * Magnifier * Mag,
        0
    )
end

function SpringEffects.Sway(XSize:number, YSize:number) : Vector3
    local Delta = UserInputService:GetMouseDelta()
    local Mag = .1

    return Vector3.new(
        Delta.X * XSize * Mag,
        Delta.Y * YSize * Mag,
        0
    )
end

return SpringEffects