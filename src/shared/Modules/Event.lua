--[[
    event dispatcher
 
    this service schedules processes to run at intervals, or in response to events on either machine.
 
    made by YesMan
]]
 
--service
local service = {}
 
--services
local dictUtil = _G.import "dictUtil"
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
 
--private state
local networkEvents = {}
local machineEvents = {}
local scheduledProcesses = {}
local temporaryProcesses = {}
--2
 
-- encryptal functions ( real )
local function count(t)
    local c = 0
    for _,_ in pairs(t) do c = c + 1 end
    return c
 end
 
--private functions
local function connect(eventList, eventName, func, params)
    params = params or {}
    local blocking = params.Blocking
    local returning = params.Returning
 
    local connectedEvent = eventList[eventName] or {Blocking=blocking,Returning=returning,Connections={}}
    if connectedEvent.Blocking ~= blocking then error('Attempted to connect non-blocking func to blocking event ' .. eventName) end
    if connectedEvent.Returning ~= returning then error('Attempted to connect non-returning func to returning event ' .. eventName) end
    eventList[eventName] = connectedEvent
 
    local connection = {EventName=eventName, ConnectionId=httpService:GenerateGUID(), func = func}
    eventList[eventName].Connections[connection.ConnectionId] = connection
 
    return connection
end
 
local function disconnect(eventList, connection)
    local eventName = connection.EventName
    local event = eventList[eventName]
    local connections = event.Connections
 
    temporaryProcesses[connection] = nil
    connections[connection.ConnectionId] = nil
 
    if count(connections) == 0 then eventList[eventName] = nil end
end
 
local function tempConnect(eventList, eventName, func, blocking)
    local connection = connect(eventList, eventName, func, blocking)
    temporaryProcesses[connection] = eventList
 
    return connection
end
 
local function tempDisconnect(connection)
    local temporaryProcessMachine = temporaryProcesses[connection]
 
    if temporaryProcessMachine then
        disconnect(temporaryProcessMachine, connection)
    end
end
 
local function fire(eventList, eventName, ...)
    local event = eventList[eventName]
    if not event then return end
 
    local args = {...}
 
    if event.Returning then
        for _, connection in pairs(event.Connections) do
            tempDisconnect(connection)
            return connection.func(...)
        end
    end
 
    if event.Blocking then
        for _,connection in pairs(event.Connections) do
            tempDisconnect(connection)
            connection.func(unpack(args))
        end
    else
        for _,connection in pairs(event.Connections) do
            tempDisconnect(connection)
            task.spawn(function() connection.func(unpack(args)) end)
        end
    end
end
 
--public functions
function service.connect(eventName, func, blocking)
    return connect(machineEvents, eventName, func, blocking)
end
 
function service.remoteConnect(eventName, func, blocking)
    return connect(networkEvents, eventName, func, blocking)
end
 
function service.wait(eventName, func)
    return tempConnect(machineEvents, eventName, func)
end
 
function service.remoteWait(eventName, func)
    return tempConnect(networkEvents, eventName, func)
end
 
function service.disconnect(connection)
    disconnect(machineEvents, connection)
end
 
function service.remoteDisconnect(connection)
    disconnect(networkEvents, connection)
end
 
function service.fire(eventName, ...)
    local ret = fire(machineEvents, eventName, ...)
    return ret
end
 
function service.fireNetwork(eventName, ...)
    return fire(networkEvents, eventName, ...)
end
 
function service.wrap(eventName)
    return function(...)
        return fire(machineEvents, eventName, ...)
    end
end
 
function service.remoteWrap(eventName)
    return function(...)
        local args = {...}
        table.insert(args,2,eventName)
 
        return service.remoteFire(unpack(args))
    end
end
 
function service.schedule(interval, func)
    local processId = httpService:GenerateGUID()
    local framesPassed = 0
 
    scheduledProcesses[processId] = interval == 0 and func or function(timePassed)
        framesPassed = framesPassed + timePassed
        if framesPassed < interval then return end
 
        framesPassed = 0
        --romodel preview doesn't know about task...
        task.spawn(func)
    end
 
    return processId
end
 
function service.deschedule(processId)
    scheduledProcesses[processId] = nil
end
 
--scheduled processes
runService.Heartbeat:Connect(function(timePassed)
    for _,process in pairs(scheduledProcesses) do
        process(timePassed)
    end
end)
 
--setup network
if runService:IsServer() then
    --remotes
    for _, remote in pairs(script:GetChildren()) do
        remote:Destroy()
    end
 
    local serverRf = Instance.new('RemoteFunction', script)
    local clientRf = Instance.new('RemoteFunction', script)
    serverRf.Name = 'serverRf'
    clientRf.Name = 'clientRf'
 
    --public functions
    function service.remoteFire(player, eventName, ...)
        return clientRf:InvokeClient(player, eventName, ...)
    end
 
    function service.firePlayers(players, eventName, ...)
        for _,player in pairs(players) do
            coroutine.wrap(function(...) clientRf:InvokeClient(player, eventName, ...) end)(...)
        end
    end
 
    function service.replicate(excludedPlayer, eventName, ...)
        local players  = {}
 
        for i, player in pairs(game.Players:GetPlayers()) do
            if player ~= excludedPlayer then
                players[i] = player
            end
        end
 
        service.firePlayers(players, eventName, ...)
    end
 
    local replicationRange = 600
 
    function service.replicateRange(excludedPlayer, eventName, ...)
        local excludedCharacterHrp = excludedPlayer.Character and excludedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not excludedCharacterHrp then return end
 
        local players  = {}
 
        for i, player in pairs(game.Players:GetPlayers()) do
            if player ~= excludedPlayer then
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if (excludedCharacterHrp.Position - hrp.Position).magnitude <= replicationRange then
                        players[i] = player
                    end
                end
            end
        end
 
        service.firePlayers(players, eventName, ...)
    end
 
 
    function service.ping(player)
        local startTime = tick()
        service.remoteFire(player,'ping')
        return tick()-startTime
    end
 
    function serverRf.OnServerInvoke(player, eventName, ...)
        return fire(networkEvents, eventName, player, ...)
    end
 
else
    --remotes
    local serverRf = script:WaitForChild('serverRf')
    local clientRf = script:WaitForChild('clientRf')
 
    --public functions
    function service.remoteFire(eventName, ...)
        local a = serverRf:InvokeServer(eventName, ...)
        return a
    end
 
    function clientRf.OnClientInvoke(eventName, ...)
        return fire(networkEvents, eventName, ...)
    end
 
end
 
return service