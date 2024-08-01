-- Event Handler

AddEventHandler('chatMessage', function(_, _, message)
    if string.sub(message, 1, 1) == '/' then
        CancelEvent()
        return
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if not RS.Players[src] then return end
    local Player = RS.Players[src]
    TriggerClientEvent('redux-horses:client:FleeHorse', src)
    TriggerEvent('redux-log:server:CreateLog', 'joinleave', 'Player Left Server', 'red', '**' .. GetPlayerName(src) .. '** left the server..' ..'\n **Reason:** ' .. reason)
    Player.Functions.Save()
    RS.Player_Buckets[Player.PlayerData.license] = nil
    RS.Players[src] = nil
end)


local function checkWhitelist(identifier)
    -- Use a COUNT query to directly get the number of matching rows
    print("Whitelisti kontroll: ", identifier)
    local rowCount = MySQL.scalar.await('SELECT COUNT(1) FROM whitelisted WHERE steam = ?', {
        identifier
    })

    -- Check if rowCount is not nil and greater than 0
    --if not rowCount then print("Whitelist error") end
    return rowCount > 0
end


-- Player Connecting
local function onPlayerConnecting(name, _, deferrals)
    local src = source
    local self = {}
    local whitelist = nil
    self.source = src
    self.name = GetPlayerName(src)
    self.hexid = RS.Util:GetHexId(src)

    if src then 
        RS.Player.CreateUser()
    end
    local license
    local steam
    local identifiers = GetPlayerIdentifiers(src)
    deferrals.defer()

    -- Mandatory wait
    Wait(0)

    if RS.Config.Server.Closed then
        if not IsPlayerAceAllowed(src, 'RSGadmin.join') then
            deferrals.done(RS.Config.Server.ClosedReason)
            return -- Ensure to exit here after handling the closure
        end
    end

    if RSConfig.Join.Whitelist then 
        for i = 1, 5 do
            deferrals.update('Laeb serverisse: '..i..'/5.')
            Wait(3000) -- Reduced wait time to avoid excessive waiting
        end

        local identifier = self.hexid
        local kickReason
        local kick = false

        if not identifier then
            kick = true

            kickReason = 'Sul peab olema steamiga ühendus!'
        elseif not checkWhitelist(identifier) then
            kick = true
            kickReason = 'Sinu steami konto on keelustatud siit serveris! Palun võtke ühendus tiiminga.'
        end

        if kick then
            deferrals.done(kickReason)
            return
        end
    end

    Wait(2500)

    if RSConfig.JoinChecks.Name then
		deferrals.update("📝 Nime kontroll..")
		Wait(1000)
		local PlayerName = GetPlayerName(src)
		if PlayerName == nil then 
			RS.Functions.Kick(src, '❌ Ära kasuta tühju nimesi.', setKickReason, deferrals)
			CancelEvent()
			return false
		end
		if(string.match(PlayerName, "[*%%'=`\"]")) then
			RS.Functions.Kick(src, ' ❌ Sa pead looma kasutajanime ('..string.match(PlayerName, "[*%%'=`\"]")..') which is not allowed.\nPlease remove this from your name.', setKickReason, deferrals)
			CancelEvent()
			return false
		end
		if (string.match(PlayerName, "drop") or string.match(PlayerName, "table") or string.match(PlayerName, "database")) then
			RS.Functions.Kick(src, '❌ Sul on sõna nimes mis pole serveris lubatud!.', setKickReason, deferrals)
			CancelEvent()
			return false
		end
	end

    Wait(2500)

    if RSConfig.JoinChecks.Identifier then
		Wait(750)
		if RSConfig.Join.IdentifierType == "steam" then
            Wait(750)
			deferrals.update("💻 Steami kontroll..")
			Wait(1000)
            print(self.hexid)
			if self.hexid == nil then 
				RS.Functions.Kick(src, '❌ Viga steami leidmisel.', setKickReason, deferrals)
				CancelEvent()
				return false
			end
			if ((self.hexid:sub(1,6) == "steam:") == false) then
				RS.Functions.Kick(src, '❌ Sul peab olema steami kasutaja.', setKickReason, deferrals)
				CancelEvent()
				return false
			end
		elseif RSConfig.Join.PermissionList == "license" then
            Wait(750)
			deferrals.update("💻 Litsentsi kontroll..")
			Wait(1000)
			--local License = RS.Functions.GetIdentifier(src, "license")
			if self.license == nil then 
				RS.Functions.Kick(src, '❌ Viga Rockstari keskkonnas.', setKickReason, deferrals)
				CancelEvent()
				return false
			end
			if ((self.license:sub(1,8) == "license:") == false) then
				RS.Functions.Kick(src, '❌ Sul peab olema Rockstari kasutaja ühenduses olema!!!.', setKickReason, deferrals)
				CancelEvent()
				return false
			end
		end
	end

    Wait(2500)
    deferrals.update(string.format(Lang:t('info.checking_ban'), name))

    -- Find both steam and rockstar licenses in a single loop
    for _, v in pairs(identifiers) do
        if not steam and v:find('steam') then
            steam = v
        elseif not license and v:find('license') then
            license = v
        end
        
        -- Exit loop early if both values are found
        if steam and license then
            break
        end
    end

    print("Steam: ", steam)
    print("Rockstar: ", license)

    -- Mandatory wait
    Wait(2500)

    deferrals.update(string.format(Lang:t('info.checking_whitelisted'), name))

    local isBanned, reason = RS.Functions.IsPlayerBanned(src)
    local isLicenseAlreadyInUse = RS.Functions.IsLicenseInUse(license)
    

    Wait(2500)

    deferrals.update(string.format(Lang:t('info.join_server'), name))

    -- Check the results and respond accordingly
    if not license and not steam then
        deferrals.done(Lang:t('error.no_valid_license'))
    elseif isBanned then
        deferrals.done(reason)
    elseif isLicenseAlreadyInUse and RS.Config.Server.CheckDuplicateLicense then
        deferrals.done(Lang:t('error.duplicate_license'))
    else
        deferrals.done()
    end

    -- Add any additional deferrals you may need here if required
end

AddEventHandler('playerConnecting', onPlayerConnecting)


-- Open & Close Server (prevents players from joining)

RegisterNetEvent('RS:Server:CloseServer', function(reason)
    local src = source
    if RS.Functions.HasPermission(src, 'admin') then
        reason = reason or 'No reason specified'
        RS.Config.Server.Closed = true
        RS.Config.Server.ClosedReason = reason
        for k in pairs(RS.Players) do
            if not RS.Functions.HasPermission(k, RS.Config.Server.WhitelistPermission) then
                RS.Functions.Kick(k, reason, nil, nil)
            end
        end
    else
        RS.Functions.Kick(src, Lang:t("error.no_permission"), nil, nil)
    end
end)

RegisterNetEvent('RS:Server:OpenServer', function()
    local src = source
    if RS.Functions.HasPermission(src, 'admin') then
        RS.Config.Server.Closed = false
    else
        RS.Functions.Kick(src, Lang:t("error.no_permission"), nil, nil)
    end
end)

-- Callback Events --

-- Client Callback
RegisterNetEvent('RS:Server:TriggerClientCallback', function(name, ...)
    if RS.ClientCallbacks[name] then
        RS.ClientCallbacks[name](...)
        RS.ClientCallbacks[name] = nil
    end
end)

-- Server Callback
RegisterNetEvent('RS:Server:TriggerCallback', function(name, ...)
    local src = source
    RS.Functions.TriggerCallback(name, src, function(...)
        TriggerClientEvent('RS:Client:TriggerCallback', src, name, ...)
    end, ...)
end)

-- Player

RegisterNetEvent('RS:UpdatePlayer', function()
    local src = source
    local Player = RS.Functions.GetPlayer(src)
    if not Player then return end
    local newHunger = Player.PlayerData.metadata['hunger'] - RS.Config.Player.HungerRate
    local newThirst = Player.PlayerData.metadata['thirst'] - RS.Config.Player.ThirstRate
    local newCleanliness = Player.PlayerData.metadata['cleanliness'] - RS.Config.Player.CleanlinessRate
    if newHunger <= 0 then
        newHunger = 0
    end
    if newThirst <= 0 then
        newThirst = 0
    end
    if newCleanliness <= 0 then
        newCleanliness = 0
    end
    Player.Functions.SetMetaData('thirst', newThirst)
    Player.Functions.SetMetaData('hunger', newHunger)
    Player.Functions.SetMetaData('cleanliness', newCleanliness)
    TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, newThirst, newCleanliness)
    Player.Functions.Save()
end)

RegisterNetEvent('RS:Server:SetMetaData', function(meta, data)
    local src = source
    local Player = RS.Functions.GetPlayer(src)
    if not Player then return end
    if meta == 'hunger' or meta == 'thirst' or meta == 'cleanliness' then
        if data > 100 then
            data = 100
        end
    end
    Player.Functions.SetMetaData(meta, data)
    TriggerClientEvent('hud:client:UpdateNeeds', src, Player.PlayerData.metadata['hunger'], Player.PlayerData.metadata['thirst'], Player.PlayerData.metadata['cleanliness'])
end)

RegisterNetEvent('RS:ToggleDuty', function()
    local src = source
    local Player = RS.Functions.GetPlayer(src)
    if not Player then return end
    if Player.PlayerData.job.onduty then
        Player.Functions.SetJobDuty(false)
        TriggerClientEvent('RS:Notify', src, Lang:t('info.off_duty'))
    else
        Player.Functions.SetJobDuty(true)
        TriggerClientEvent('RS:Notify', src, Lang:t('info.on_duty'))
    end
    TriggerClientEvent('RS:Client:SetDuty', src, Player.PlayerData.job.onduty)
end)

-- Items

-- This event is exploitable and should not be used. It has been deprecated, and will be removed soon.
RegisterNetEvent('RS:Server:UseItem', function(item)
    print(string.format("%s triggered RS:Server:UseItem by ID %s with the following data. This event is deprecated due to exploitation, and will be removed soon. Check qb-inventory for the right use on this event.", GetInvokingResource(), source))
    RS.Debug(item)
end)

-- This event is exploitable and should not be used. It has been deprecated, and will be removed soon. function(itemName, amount, slot)
RegisterNetEvent('RS:Server:RemoveItem', function(itemName, amount)
    local src = source
    print(string.format("%s triggered RS:Server:RemoveItem by ID %s for %s %s. This event is deprecated due to exploitation, and will be removed soon. Adjust your events accordingly to do this server side with player functions.", GetInvokingResource(), src, amount, itemName))
end)

-- This event is exploitable and should not be used. It has been deprecated, and will be removed soon. function(itemName, amount, slot, info)
RegisterNetEvent('RS:Server:AddItem', function(itemName, amount)
    local src = source
    print(string.format("%s triggered RS:Server:AddItem by ID %s for %s %s. This event is deprecated due to exploitation, and will be removed soon. Adjust your events accordingly to do this server side with player functions.", GetInvokingResource(), src, amount, itemName))
end)

-- Non-Chat Command Calling (ex: redux-adminmenu)

RegisterNetEvent('RS:CallCommand', function(command, args)
    local src = source
    if not RS.Commands.List[command] then return end
    local Player = RS.Functions.GetPlayer(src)
    if not Player then return end
    local hasPerm = RS.Functions.HasPermission(src, "command."..RS.Commands.List[command].name)
    if hasPerm then
        if RS.Commands.List[command].argsrequired and #RS.Commands.List[command].arguments ~= 0 and not args[#RS.Commands.List[command].arguments] then
            TriggerClientEvent('RS:Notify', src, Lang:t('error.missing_args2'), 'error')
        else
            RS.Commands.List[command].callback(src, args)
        end
    else
        TriggerClientEvent('RS:Notify', src, Lang:t('error.no_access'), 'error')
    end
end)

-- Use this for player vehicle spawning
-- Vehicle server-side spawning callback (netId)
-- use the netid on the client with the NetworkGetEntityFromNetworkId native
-- convert it to a vehicle via the NetToVeh native
RS.Functions.CreateCallback('RS:Server:SpawnVehicle', function(source, cb, model, coords, warp)
    local ped = GetPlayerPed(source)
    model = type(model) == 'string' and joaat(model) or model
    if not coords then coords = GetEntityCoords(ped) end
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then
        while GetVehiclePedIsIn(ped) ~= veh do
            Wait(0)
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end
    while NetworkGetEntityOwner(veh) ~= source do Wait(0) end
    cb(NetworkGetNetworkIdFromEntity(veh))
end)

-- Use this for long distance vehicle spawning
-- vehicle server-side spawning callback (netId)
-- use the netid on the client with the NetworkGetEntityFromNetworkId native
-- convert it to a vehicle via the NetToVeh native
RS.Functions.CreateCallback('RS:Server:CreateVehicle', function(source, cb, model, coords, warp)
    model = type(model) == 'string' and GetHashKey(model) or model
    if not coords then coords = GetEntityCoords(GetPlayerPed(source)) end
    local CreateAutomobile = GetHashKey("CREATE_AUTOMOBILE")
    local veh = Citizen.InvokeNative(CreateAutomobile, model, coords, coords.w, true, true)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then TaskWarpPedIntoVehicle(GetPlayerPed(source), veh, -1) end
    cb(NetworkGetNetworkIdFromEntity(veh))
end)
