local Audio = {}
Audio.Debris = game:GetService("Debris")

function Audio.Play(Sound, Parent)
    local SoundClone = Sound:Clone()
    SoundClone.Parent = Parent or Sound.Parent
    Audio.Debris:AddItem(SoundClone, SoundClone.TimeLength)
    SoundClone:Play()
    return SoundClone
end

return Audio