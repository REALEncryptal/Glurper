local Debug = {}
Debug.SlotFrame = game:GetService("ReplicatedStorage").SlotFrame
Debug.List = {}

function Debug.Insert(Index, Value)
    local Frame = Debug.SlotFrame:Clone()

    Frame.Index.Text = tostring(Index)
    Frame.Value.Text = tostring(Value)

    if typeof(Value) == "boolean" then
        if Value then
            Frame.Value.BackgroundColor3 = Color3.new(0.192156, 0.627450, 0.192156)
        else
            Frame.Value.BackgroundColor3 = Color3.new(0.682352, 0.243137, 0.243137)
        end
    else
        Frame.Value.BackgroundColor3 = Color3.new(0.215686, 0.376470, 0.490196)
    end

    Frame.Parent = game.Players.LocalPlayer.PlayerGui.Debug.Container
end

function Debug.DestroyAll()
    for _,Item in ipairs(game.Players.LocalPlayer.PlayerGui.Debug.Container:GetChildren()) do
        if Item.Name == "SlotFrame" then
            Item:Destroy()
        end
    end
end

return Debug