local Camera = {}

function Camera.Lock(CF:CFrame)
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
    workspace.CurrentCamera.CFrame = CF

    return workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable
end

function Camera.Unlock() 
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

return Camera