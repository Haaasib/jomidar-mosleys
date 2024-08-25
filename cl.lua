local QBCore = exports[Config.Core]:GetCoreObject()
local zoneCenter = Config.WorkZone
local zoneRadius = 4.0
local markerActive = false
local hasEnteredZone = false
local idforinteract = GetPlayerName(PlayerId())
local vehicleParts = {
    {bone = 'door_dside_f', label = 'Install Side Glass', offset = vec3(0.0, 0.0, 0.0)},
    {bone = 'door_pside_f', label = 'Install Livery', offset = vec3(0.0, 0.0, 0.0)},
    {bone = 'engine', label = 'Horn', offset = vec3(0.0, 0.0, 0.0)},
}

local currentPartIndex = 1
local currentInteractionId = nil

-- Function to get the closest vehicle or the vehicle the player is sitting in
function getClosestVehicle()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle and vehicle ~= 0 then
        return vehicle
    end
    
    -- Fallback to closest vehicle if not in a vehicle
    local closestVehicle = GetClosestVehicle(coords, 10.0, 0, 71)
    return closestVehicle
end

-- Function to add an interaction point to a vehicle part
function addVehicleInteraction(vehicleNetId, part)

    currentInteractionId = 'interaction_' .. part.label
    
    exports.interact:AddEntityInteraction({
        netId = vehicleNetId,
        name = 'vehicleInteraction',
        id = currentInteractionId,
        distance = 4.0,
        interactDst = 3.0,
        ignoreLos = false,
        offset = part.offset,
        bone = part.bone,
        options = {
            {
                label = part.label,
                action = function(entity, coords, args)
                    -- Execute the action based on the part label
                    if part.label == 'Install Side Glass' then
                        driver1(vehicleNetId, currentInteractionId)
                    
                    elseif part.label == 'Install Livery' then
                        driver2(vehicleNetId, currentInteractionId)

                    elseif part.label == 'Horn' then
                        engine(vehicleNetId, currentInteractionId)
                    end
                end,
            },
        }
    })
end

-- Function to start adding interactions for the closest vehicle
function startVehicleInteractions()
    local vehicle = getClosestVehicle()
    if vehicle and vehicle ~= 0 then
        local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
        currentPartIndex = 1
        addVehicleInteraction(vehicleNetId, vehicleParts[currentPartIndex])
    else
        print("No vehicle found.")
    end
end

function driver1(vehicleNetId, interactionId)
    QBCore.Functions.Progressbar("driver1", "Installing part to vehicle....", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
     }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 49,
     }, {}, {}, function()  -- Success
        if QBCore.Functions.HasItem('mosleyssideglass') then
        TriggerServerEvent('jomidar:mosleys:removeItem', 'mosleyssideglass', Config.Itemammountneed)
        QBCore.Functions.Notify("Sucessfully installed part to vehicle", "success")
        exports['jomidar-ui']:Show('Mosleys', 'Install Part 1/3')
        exports.interact:RemoveEntityInteraction(vehicleNetId, interactionId)
        currentPartIndex = 2
        addVehicleInteraction(vehicleNetId, vehicleParts[currentPartIndex])
        else 
            QBCore.Functions.Notify("You dont have the item", "error")
        end
    end, function()  -- Failure
        QBCore.Functions.Notify("Installation Failed", "error")
    end)
end 

function driver2(vehicleNetId, interactionId)
    QBCore.Functions.Progressbar("driver2", "Installing part to vehicle....", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
     }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 49,
     }, {}, {}, function()  -- Success
        if QBCore.Functions.HasItem('mosleysliv') then
        TriggerServerEvent('jomidar:mosleys:removeItem', 'mosleysliv', Config.Itemammountneed)
        QBCore.Functions.Notify("Sucessfully installed part to vehicle", "success")
        exports['jomidar-ui']:Show('Mosleys', 'Install Part 2/3')
        exports.interact:RemoveEntityInteraction(vehicleNetId, interactionId)
        currentPartIndex = 3
        addVehicleInteraction(vehicleNetId, vehicleParts[currentPartIndex])
    else 
        QBCore.Functions.Notify("You dont have the item", "error")
    end
    end, function()  -- Failure
        QBCore.Functions.Notify("Installation Failed", "error")
    end)
end 

function engine(vehicleNetId, interactionId)
    QBCore.Functions.Progressbar("engine", "Installing horn to vehicle....", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
     }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 49,
     }, {}, {}, function()  -- Success
        if QBCore.Functions.HasItem('mosleyshorn') then

        TriggerServerEvent('jomidar:mosleys:removeItem', 'mosleyshorn' , Config.Itemammountneed)
        QBCore.Functions.Notify("Sucessfully installed part to vehicle", "success")
        exports['jomidar-ui']:Show('Mosleys', 'Install Part 3/3')
        exports.interact:RemoveEntityInteraction(vehicleNetId, interactionId)
        SpawnMosleyPedsDelivery(vehicleNetId)
        Citizen.Wait(2000)
        exports['jomidar-ui']:Show('Mosleys', 'Deliver Vehicle To Customer')
    else 
        QBCore.Functions.Notify("You dont have the item", "error")
    end
    end, function()  -- Failure
        QBCore.Functions.Notify("Installation Failed", "error")
    end)
end



-- Function to check if the player is in the zone
function MakeZone()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local distance = #(playerCoords - zoneCenter)

    if distance <= zoneRadius then
        -- Player is in the zone, hide the marker and set the entered flag
        if markerActive then
            markerActive = false
        end
        hasEnteredZone = true
        exports['jomidar-ui']:Show('Mosleys', 'Install Part 0/3')
        startVehicleInteractions()
    else
        -- Player is not in the zone
        if hasEnteredZone then
            -- Reset the zone flag if the player leaves
            hasEnteredZone = false
        end
    end
end

function ZoneHandler()
    if markerActive then
        DrawMarker(1, zoneCenter.x, zoneCenter.y, zoneCenter.z - 1.0, 0, 0, 0, 0, 0, 0, zoneRadius * 2, zoneRadius * 2, 0.5, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
    end
end

Citizen.CreateThread(function()
   
    local pedData = Config.Mosleys.StartPed[1]
    local pedModel1 = GetHashKey(pedData.ped)

    -- Load the model for the ped
    RequestModel(pedModel1)
    while not HasModelLoaded(pedModel1) do
        Wait(1)
    end

    -- Spawn the ped at the specified location
    local ped = CreatePed(4, pedModel1, pedData.coords.x, pedData.coords.y, pedData.coords.z, 123.89, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true) -- Freeze the ped in place
    SetEntityInvincible(ped, true) -- Make the ped invincible

    exports.interact:AddLocalEntityInteraction({
        entity = ped,
        id = 'mosleysPedId1',
        distance = 4.0,
        options = {
            {
                label = 'Start The Job',
                action = function(entity, coords, args)
                    TriggerEvent("jomidar-mosleys:cl:start")
                end,
            }
        }
    })

    exports.interact:AddInteraction({
        coords = vector3(2332.82, 3043.02, 48.15),
        distance = 4.0, -- optional
        interactDst = 2.0, -- optional
        id = 'ac', -- needed for removing interactions
        name = 'chopac', -- optional
        options = {
             {
                label = 'Chop Broken AC',
                action = function(entity, coords, args)
                    local hasItem = QBCore.Functions.HasItem('ac_broken', 2)
                    if hasItem then
                        local propCoords = vector4(2332.76, 3043.02, 47.15, 150)
                        local propModel = 'prop_aircon_s_04a'
                    
                        RequestModel(propModel)
                        while not HasModelLoaded(propModel) do
                            Wait(0)
                        end
                    
                        local prop = CreateObject(propModel, propCoords.x, propCoords.y, propCoords.z, true, true, false)
                        SetEntityHeading(prop, propCoords.w)
                        FreezeEntityPosition(prop, true)
                    
                        -- Load welding torch model
                        local torchModel = `prop_weld_torch`
                        RequestModel(torchModel)
                        while not HasModelLoaded(torchModel) do
                            Wait(0)
                        end
                    
                        -- Create welding torch prop and attach it to the player's hand
                        local playerPed = PlayerPedId()
                        local weldingTorch = CreateObject(torchModel, 0.0, 0.0, 0.0, true, true, true)
                        AttachEntityToEntity(weldingTorch, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, 0.0, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
                    
                        -- Start progress bar with welding animation
                        QBCore.Functions.Progressbar("acchop1", "Chopping The AC Parts.....", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = false,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "amb@world_human_welding@male@base",
                            anim = "base",
                            flags = 49
                        }, {}, {}, function() -- Success
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop after the task is done
                            TriggerServerEvent('jomidar:mosleys:removeItem', 'ac_broken', 2)
                            TriggerServerEvent('jomidar:mosleys:addItem', 'mosleyssideglass', 1)

                        end, function() -- Cancel
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop if the task is canceled
                            QBCore.Functions.Notify("You Stopped Chopping AC", "error")
                        end)
                    else
                        QBCore.Functions.Notify("You don't have enough items on you", "error")
                    end
                    
                end,
            },
            {
                label = 'Chop AC Compressor',
                action = function(entity, coords, args)
                    local hasItem = QBCore.Functions.HasItem('ac_compressor', 2)
                    if hasItem then
                        local propCoords = vector4(2332.76, 3043.02, 47.15, 150)
                        local propModel = 'prop_aircon_s_04a'
                    
                        RequestModel(propModel)
                        while not HasModelLoaded(propModel) do
                            Wait(0)
                        end
                    
                        local prop = CreateObject(propModel, propCoords.x, propCoords.y, propCoords.z, true, true, false)
                        SetEntityHeading(prop, propCoords.w)
                        FreezeEntityPosition(prop, true)
                    
                        -- Load welding torch model
                        local torchModel = `prop_weld_torch`
                        RequestModel(torchModel)
                        while not HasModelLoaded(torchModel) do
                            Wait(0)
                        end
                    
                        -- Create welding torch prop and attach it to the player's hand
                        local playerPed = PlayerPedId()
                        local weldingTorch = CreateObject(torchModel, 0.0, 0.0, 0.0, true, true, true)
                        AttachEntityToEntity(weldingTorch, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, 0.0, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
                    
                        -- Start progress bar with welding animation
                        QBCore.Functions.Progressbar("acchop2", "Chopping The AC Parts.....", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = false,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "amb@world_human_welding@male@base",
                            anim = "base",
                            flags = 49
                        }, {}, {}, function() -- Success
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop after the task is done
                            TriggerServerEvent('jomidar:mosleys:removeItem', 'ac_compressor', 2)
                            TriggerServerEvent('jomidar:mosleys:addItem', 'mosleyshorn', 1)
                        end, function() -- Cancel
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop if the task is canceled
                            

                            QBCore.Functions.Notify("You Stopped Chopping AC", "error")
                        end)
                    else
                        QBCore.Functions.Notify("You don't have enough items on you", "error")
                    end                end,
            },
            {
                label = 'Chop AC',
                action = function(entity, coords, args)
                    local hasItem = QBCore.Functions.HasItem('ac', 2)
                    if hasItem then
                        local propCoords = vector4(2332.76, 3043.02, 47.15, 150)
                        local propModel = 'prop_aircon_s_04a'
                    
                        RequestModel(propModel)
                        while not HasModelLoaded(propModel) do
                            Wait(0)
                        end
                    
                        local prop = CreateObject(propModel, propCoords.x, propCoords.y, propCoords.z, true, true, false)
                        SetEntityHeading(prop, propCoords.w)
                        FreezeEntityPosition(prop, true)
                    
                        -- Load welding torch model
                        local torchModel = `prop_weld_torch`
                        RequestModel(torchModel)
                        while not HasModelLoaded(torchModel) do
                            Wait(0)
                        end
                    
                        -- Create welding torch prop and attach it to the player's hand
                        local playerPed = PlayerPedId()
                        local weldingTorch = CreateObject(torchModel, 0.0, 0.0, 0.0, true, true, true)
                        AttachEntityToEntity(weldingTorch, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, 0.0, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
                    
                        -- Start progress bar with welding animation
                        QBCore.Functions.Progressbar("acchop3", "Chopping The AC Parts.....", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = false,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "amb@world_human_welding@male@base",
                            anim = "base",
                            flags = 49
                        }, {}, {}, function() -- Success
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop after the task is done
                            TriggerServerEvent('jomidar:mosleys:removeItem', 'ac', 2)
                            TriggerServerEvent('jomidar:mosleys:addItem', 'mosleyshorn', 1)
                        end, function() -- Cancel
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop if the task is canceled
                          

                            QBCore.Functions.Notify("You Stopped Chopping AC", "error")
                        end)
                    else
                        QBCore.Functions.Notify("You don't have enough items on you", "error")
                    end                end,
            },
            {
                label = 'Chop Ac Vent',
                action = function(entity, coords, args)
                    local hasItem = QBCore.Functions.HasItem('ac_vent', 2)
                    if hasItem then
                        local propCoords = vector4(2332.76, 3043.02, 47.15, 150)
                        local propModel = 'prop_aircon_s_04a'
                    
                        RequestModel(propModel)
                        while not HasModelLoaded(propModel) do
                            Wait(0)
                        end
                    
                        local prop = CreateObject(propModel, propCoords.x, propCoords.y, propCoords.z, true, true, false)
                        SetEntityHeading(prop, propCoords.w)
                        FreezeEntityPosition(prop, true)
                    
                        -- Load welding torch model
                        local torchModel = `prop_weld_torch`
                        RequestModel(torchModel)
                        while not HasModelLoaded(torchModel) do
                            Wait(0)
                        end
                    
                        -- Create welding torch prop and attach it to the player's hand
                        local playerPed = PlayerPedId()
                        local weldingTorch = CreateObject(torchModel, 0.0, 0.0, 0.0, true, true, true)
                        AttachEntityToEntity(weldingTorch, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, 0.0, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 1, true)
                    
                        -- Start progress bar with welding animation
                        QBCore.Functions.Progressbar("acchop4", "Chopping The AC Parts.....", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = false,
                            disableMouse = false,
                            disableCombat = true,
                        }, {
                            animDict = "amb@world_human_welding@male@base",
                            anim = "base",
                            flags = 49
                        }, {}, {}, function() -- Success
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop after the task is done
                            TriggerServerEvent('jomidar:mosleys:removeItem', 'ac_vent', 2)
                            TriggerServerEvent('jomidar:mosleys:addItem', 'mosleysliv', 1)
                        end, function() -- Cancel
                            DeleteObject(prop)
                            DeleteObject(weldingTorch) -- Delete the torch prop if the task is canceled
                        
                            QBCore.Functions.Notify("You Stopped Chopping AC", "error")
                        end)
                    else
                        QBCore.Functions.Notify("You don't have enough items on you", "error")
                    end                  
                    end,
            },
        }
    })

end)

function SpawnMosleyPedsDelivery()
    local carCoordsNped = Config.Mosleys.CarCoordsNped
    local numEntries = #carCoordsNped

    -- Randomly select an index from the available entries
    local randomIndex = math.random(1, numEntries)
    local data = carCoordsNped[randomIndex]
    local pedModel3 = GetHashKey(data.ped)
    
    -- Load the ped model
    RequestModel(pedModel3)
    while not HasModelLoaded(pedModel3) do
        Wait(1)
    end

    -- Spawn the ped at the specified coordinates
    local ped3 = CreatePed(4, pedModel3, data.pedCoords.x, data.pedCoords.y, data.pedCoords.z, data.pedCoords.w, false, true)
    SetEntityAsMissionEntity(ped3, true, true)
    SetPedFleeAttributes(ped3, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped3, true)
    FreezeEntityPosition(ped3, false)
    SetEntityInvincible(ped3, true)

    -- Create a blip for the ped
    local PedBlip = AddBlipForEntity(ped3)
    SetBlipSprite(PedBlip, 380)
    SetBlipColour(PedBlip, 1)
    SetBlipScale(PedBlip, 0.7)
    SetBlipRoute(PedBlip, true)
    SetBlipRouteColour(PedBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Delivery')
    EndTextCommandSetBlipName(PedBlip)

    -- Get the closest vehicle
    local vehicle = getClosestVehicle()
    local vehicleHealth = GetEntityHealth(vehicle)
    local vehicleQuality = math.floor(vehicleHealth)
  
    exports.interact:AddLocalEntityInteraction({
        entity = ped3,
        id = idforinteract,
        distance = 4.0,
        options = {
            {
                label = 'Deliver Vehicle',
                action = function(entity, coords, args)
                    QBCore.Functions.Progressbar("engine", "Giving Keys To Owner....", 5000, false, true, {
                        disableMovement = true,
                        disableCarMovement = false,
                        disableMouse = false,
                        disableCombat = true,
                     }, {
                        animDict = "mp_common",
                        anim = "givetake1_a",
                        flags = 49,
                     }, {}, {}, function()  -- Success
                      
                    TaskWarpPedIntoVehicle(ped3, vehicle, -1)
                    TaskVehicleDriveWander(ped3, vehicle, 30.0, 786603) -- Drive away in a car
                    exports['jomidar-ui']:Close()
                    TriggerEvent('jomidar-mosleys:vehiclequality', vehicleQuality)
                    print(vehicleQuality)
                    Citizen.CreateThread(function()
                        Citizen.Wait(30000) -- Wait for 30 seconds (adjust as needed)
                        DeleteEntity(vehicle)
                        DeleteEntity(ped3)
                    end)
                    end, function()  -- Failure
                        QBCore.Functions.Notify("Installation Failed", "error")
                    end)
                    exports.interact:RemoveLocalEntityInteraction(ped3, idforinteract)
                   
                end,
            }
        }
    })
end

RegisterNetEvent('jomidar-mosleys:vehiclequality')
AddEventHandler('jomidar-mosleys:vehiclequality', function(vehicleQuality)

TriggerServerEvent('jomidar-mosleys:addmoney', vehicleQuality)

end)

function SpawnMosleyPeds()
    local carCoordsNped = Config.Mosleys.CarCoordsNped
    local numEntries = #carCoordsNped

    -- Randomly select an index from the available entries
    local randomIndex = math.random(1, numEntries)
    local data = carCoordsNped[randomIndex]
    local pedModel = GetHashKey(data.ped)
    local vehicleModel = GetHashKey(data.vehicleModel)

    -- Load the ped model
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(1)
    end

    -- Spawn the ped at the specified coordinates
    local ped2 = CreatePed(4, pedModel, data.pedCoords.x, data.pedCoords.y, data.pedCoords.z, data.pedCoords.w, false, true)
    SetEntityAsMissionEntity(ped2, true, true)
    SetPedFleeAttributes(ped2, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped2, true)
    FreezeEntityPosition(ped2, true)
    SetEntityInvincible(ped2, true)

    -- Create a blip for the ped
    local PedBlip = AddBlipForEntity(ped2)
    SetBlipSprite(PedBlip, 380)
    SetBlipColour(PedBlip, 1)
    SetBlipScale(PedBlip, 0.7)
    SetBlipRoute(PedBlip, true)
    SetBlipRouteColour(PedBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Customer')
    EndTextCommandSetBlipName(PedBlip)

    -- Interaction for the ped
    exports.interact:AddLocalEntityInteraction({
        entity = ped2,
        id = idforinteract,
        distance = 4.0,
        options = {
            {
                label = 'Take Vehicle',
                action = function(entity, coords, args)
                    SpawnVehicleForCustomer(data, PedBlip)
                    RemovePedInteraction(ped2)
                end,
            }
        }
    })
end

function RemovePedInteraction(ped2)
    if DoesEntityExist(ped2) then
        -- Remove interaction with the ped
        exports.interact:RemoveLocalEntityInteraction(ped2, idforinteract)
        SetEntityVisible(ped2, false)
        SetEntityAlpha(ped2, 0, false)
    end
end

function SpawnVehicleForCustomer(data, PedBlip)
    local vehicleModel = GetHashKey(data.vehicleModel)

    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(1)
    end

    local vehicle = CreateVehicle(vehicleModel, data.vehicleCoords.x, data.vehicleCoords.y, data.vehicleCoords.z, data.vehicleCoords.w, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)

    local playerPed = PlayerPedId()
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(vehicle))
    exports['jomidar-ui']:Show('Mosleys', 'Go back to Mosleys')
    RemoveBlip(PedBlip)

    -- Reset the flags
    markerActive = true
    hasEnteredZone = false

    -- Start checking zone status
    Citizen.CreateThread(function()
        while not hasEnteredZone do
            Citizen.Wait(0)
            MakeZone()
            ZoneHandler()
        end
        -- Deactivate the marker after player enters the zone
        markerActive = false
    end)
end


RegisterNetEvent('jomidar-mosleys:cl:start')
AddEventHandler('jomidar-mosleys:cl:start', function()

        local waittime = math.random(Config.MinTime, Config.MaxTime)
        exports['jomidar-ui']:Show('Waiting for job offer')
        Citizen.Wait(waittime)
        exports['jomidar-ui']:Show('Mosleys', 'Go to the customer')
        SpawnMosleyPeds()

end)
