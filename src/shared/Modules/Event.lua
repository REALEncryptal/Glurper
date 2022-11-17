--[[

Event module made by encryptal
Original from Yessman: https://pastebin.com/YkAL4Lms

does the event

ok

--]]

local Event = {}

--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Varibles
Event.RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
Event.Connections = {}

-- Functions
function Event.Connect(EventName, Callback)
    Event.Connections[EventName] = Callback
end

function Event.ServerFire(Player, EventName, ...)
    Event.RemoteEvent:FireClient(Player, EventName, ...)
end

function Event.ClientFire(EventName, ...)
    Event.RemoteEvent:FireServer(EventName, ...)
end

function Event.Run(Player)

end

return Event