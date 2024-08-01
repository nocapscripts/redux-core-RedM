RS.Commands = {}
RS.Commands.List = {}
RS.Commands.IgnoreList = { -- Ignore old perm levels while keeping backwards compatibility
    ['god'] = true, -- We don't need to create an ace because god is allowed all commands
    ['user'] = true -- We don't need to create an ace because builtin.everyone
}

CreateThread(function() -- Add ace to node for perm checking
    local permissions = RSConfig.Server.Permissions
    for i=1, #permissions do
        local permission = permissions[i]
        ExecuteCommand(('add_ace RS.%s %s allow'):format(permission, permission))
    end
end)

-- Register & Refresh Commands

function RS.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    local restricted = true -- Default to restricted for all commands
    if not permission then permission = 'user' end -- some commands don't pass permission level
    if permission == 'user' then restricted = false end -- allow all users to use command

    RegisterCommand(name, function(source, args, rawCommand) -- Register command within fivem
        if argsrequired and #args < #arguments then
            return TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"System", Lang:t("error.missing_args2")}
            })
        end
        callback(source, args, rawCommand)
    end, restricted)

    local extraPerms = ... and table.pack(...) or nil
    if extraPerms then
        extraPerms[extraPerms.n + 1] = permission -- The `n` field is the number of arguments in the packed table
        extraPerms.n += 1
        permission = extraPerms
        for i = 1, permission.n do
            if not RS.Commands.IgnoreList[permission[i]] then -- only create aces for extra perm levels
                ExecuteCommand(('add_ace RS.%s command.%s allow'):format(permission[i], name))
            end
        end
        permission.n = nil
    else
        permission = tostring(permission:lower())
        if not RS.Commands.IgnoreList[permission] then -- only create aces for extra perm levels
            ExecuteCommand(('add_ace RS.%s command.%s allow'):format(permission, name))
        end
    end

    RS.Commands.List[name:lower()] = {
        name = name:lower(),
        permission = permission,
        help = help,
        arguments = arguments,
        argsrequired = argsrequired,
        callback = callback
    }
end

function RS.Commands.Refresh(source)
    local src = source
    local Player = RS.Functions.GetPlayer(src)
    local suggestions = {}
    if Player then
        for command, info in pairs(RS.Commands.List) do
            local hasPerm = IsPlayerAceAllowed(tostring(src), 'command.'..command)
            if hasPerm then
                suggestions[#suggestions + 1] = {
                    name = '/' .. command,
                    help = info.help,
                    params = info.arguments
                }
            else
                TriggerClientEvent('chat:removeSuggestion', src, '/'..command)
            end
        end
        TriggerClientEvent('chat:addSuggestions', src, suggestions)
    end
end


---------- pvp on or off
RS.Commands.Add("pvp", Lang:t('command.pvp.help'), {}, false, function(source)
    local src = source
    TriggerClientEvent('redux-core:client:pvpToggle', src)
end)

-- Teleport
RS.Commands.Add('tp', Lang:t("command.tp.help"), { { name = Lang:t("command.tp.params.x.name"), help = Lang:t("command.tp.params.x.help") }, { name = Lang:t("command.tp.params.y.name"), help = Lang:t("command.tp.params.y.help") }, { name = Lang:t("command.tp.params.z.name"), help = Lang:t("command.tp.params.z.help") } }, false, function(source, args)
    if args[1] and not args[2] and not args[3] then
        if tonumber(args[1]) then
        local target = GetPlayerPed(tonumber(args[1]))
        if target ~= 0 then
            local coords = GetEntityCoords(target)
            TriggerClientEvent('RS:Command:TeleportToPlayer', source, coords)
        else
            TriggerClientEvent('RS:Notify', source, Lang:t('error.not_online'), 'error')
        end
    else
            local location = RSShared.Locations[args[1]]
            if location then
                TriggerClientEvent('RS:Command:TeleportToCoords', source, location.x, location.y, location.z, location.w)
            else
                TriggerClientEvent('RS:Notify', source, Lang:t('error.location_not_exist'), 'error')
            end
        end
    else
        if args[1] and args[2] and args[3] then
            local x = tonumber((args[1]:gsub(",",""))) + .0
            local y = tonumber((args[2]:gsub(",",""))) + .0
            local z = tonumber((args[3]:gsub(",",""))) + .0
            if x ~= 0 and y ~= 0 and z ~= 0 then
                TriggerClientEvent('RS:Command:TeleportToCoords', source, x, y, z)
            else
                TriggerClientEvent('RS:Notify', source, Lang:t('error.wrong_format'), 'error')
            end
        else
            TriggerClientEvent('RS:Notify', source, Lang:t('error.missing_args'), 'error')
        end
    end
end, 'admin')

-- admin noclip
RS.Commands.Add('noclip', Lang:t("command.noclip.help"), {}, false, function(source)
    TriggerClientEvent('RS:Command:ToggleNoClip', source)
end, 'admin')

-- teleport to marker
RS.Commands.Add('tpm', Lang:t("command.tpm.help"), {}, false, function(source)
    TriggerClientEvent('RS:Command:GoToMarker', source)
end, 'admin')

-- Permissions

RS.Commands.Add('addpermission', Lang:t("command.addpermission.help"), { { name = Lang:t("command.addpermission.params.id.name"), help = Lang:t("command.addpermission.params.id.help") }, { name = Lang:t("command.addpermission.params.permission.name"), help = Lang:t("command.addpermission.params.permission.help") } }, true, function(source, args)
    local Player = RS.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        RS.Functions.AddPermission(Player.PlayerData.source, permission)
    else
        TriggerClientEvent('RS:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'god')

RS.Commands.Add('removepermission', Lang:t("command.removepermission.help"), { { name = Lang:t("command.removepermission.params.id.name"), help = Lang:t("command.removepermission.params.id.help") }, { name = Lang:t("command.removepermission.params.permission.name"), help = Lang:t("command.removepermission.params.permission.help") } }, true, function(source, args)
    local Player = RS.Functions.GetPlayer(tonumber(args[1]))
    local permission = tostring(args[2]):lower()
    if Player then
        RS.Functions.RemovePermission(Player.PlayerData.source, permission)
    else
        TriggerClientEvent('RS:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'god')

-- Open & Close Server

RS.Commands.Add('openserver', Lang:t("command.openserver.help"), {}, false, function(source)
    if not RS.Config.Server.Closed then
        TriggerClientEvent('RS:Notify', source, Lang:t('error.server_already_open'), 'error')
        return
    end
    if RS.Functions.HasPermission(source, 'admin') then
        RS.Config.Server.Closed = false
        TriggerClientEvent('RS:Notify', source, Lang:t('success.server_opened'), 'success')
    else
        RS.Functions.Kick(source, Lang:t("error.no_permission"), nil, nil)
    end
end, 'admin')

RS.Commands.Add('closeserver', Lang:t("command.closeserver.help"), {{ name = Lang:t("command.closeserver.params.reason.name"), help = Lang:t("command.closeserver.params.reason.help")}}, false, function(source, args)
    if RS.Config.Server.Closed then
        TriggerClientEvent('RS:Notify', source, Lang:t('error.server_already_closed'), 'error')
        return
    end
    if RS.Functions.HasPermission(source, 'admin') then
        local reason = args[1] or 'No reason specified'
        RS.Config.Server.Closed = true
        RS.Config.Server.ClosedReason = reason
        for k in pairs(RS.Players) do
            if not RS.Functions.HasPermission(k, RS.Config.Server.WhitelistPermission) then
                RS.Functions.Kick(k, reason, nil, nil)
            end
        end
        TriggerClientEvent('RS:Notify', source, Lang:t('success.server_closed'), 'success')
    else
        RS.Functions.Kick(source, Lang:t("error.no_permission"), nil, nil)
    end
end, 'admin')

-- HORSES / WAGONS
RS.Commands.Add('dv', Lang:t("command.dv.help"), {}, false, function(source)
    TriggerClientEvent('RS:Command:DeleteVehicle', source)
end, 'admin')

RS.Commands.Add('wagon', Lang:t("command.spawnwagon.help"), { { name = 'model', help = 'Model name of the wagon' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('RS:Command:SpawnVehicle', src, args[1])
end, 'admin')

RS.Commands.Add('horse', Lang:t("command.spawnhorse.help"), { { name = 'model', help = 'Model name of the horse' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('RS:Command:SpawnHorse', src, args[1])
end, 'admin')

-- Money

RS.Commands.Add('givemoney', Lang:t("command.givemoney.help"), { { name = Lang:t("command.givemoney.params.id.name"), help = Lang:t("command.givemoney.params.id.help") }, { name = Lang:t("command.givemoney.params.moneytype.name"), help = Lang:t("command.givemoney.params.moneytype.help") }, { name = Lang:t("command.givemoney.params.amount.name"), help = Lang:t("command.givemoney.params.amount.help") } }, true, function(source, args)
    local Player = RS.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.AddMoney(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RS:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

RS.Commands.Add('setmoney', Lang:t("command.setmoney.help"), { { name = Lang:t("command.setmoney.params.id.name"), help = Lang:t("command.setmoney.params.id.help") }, { name = Lang:t("command.setmoney.params.moneytype.name"), help = Lang:t("command.setmoney.params.moneytype.help") }, { name = Lang:t("command.setmoney.params.amount.name"), help = Lang:t("command.setmoney.params.amount.help") } }, true, function(source, args)
    local Player = RS.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetMoney(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RS:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Job

RS.Commands.Add('job', Lang:t("command.job.help"), {}, false, function(source)
    local PlayerJob = RS.Functions.GetPlayer(source).PlayerData.job
    TriggerClientEvent('RS:Notify', source, Lang:t('info.job_info', {value = PlayerJob.label, value2 = PlayerJob.grade.name, value3 = PlayerJob.onduty}))
end, 'user')

RS.Commands.Add('setjob', Lang:t("command.setjob.help"), { { name = Lang:t("command.setjob.params.id.name"), help = Lang:t("command.setjob.params.id.help") }, { name = Lang:t("command.setjob.params.job.name"), help = Lang:t("command.setjob.params.job.help") }, { name = Lang:t("command.setjob.params.grade.name"), help = Lang:t("command.setjob.params.grade.help") } }, true, function(source, args)
    local Player = RS.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetJob(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RS:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Gang

RS.Commands.Add('gang', Lang:t("command.gang.help"), {}, false, function(source)
    local PlayerGang = RS.Functions.GetPlayer(source).PlayerData.gang
    TriggerClientEvent('RS:Notify', source, Lang:t('info.gang_info', {value = PlayerGang.label, value2 = PlayerGang.grade.name}))
end, 'user')

RS.Commands.Add('setgang', Lang:t("command.setgang.help"), { { name = Lang:t("command.setgang.params.id.name"), help = Lang:t("command.setgang.params.id.help") }, { name = Lang:t("command.setgang.params.gang.name"), help = Lang:t("command.setgang.params.gang.help") }, { name = Lang:t("command.setgang.params.grade.name"), help = Lang:t("command.setgang.params.grade.help") } }, true, function(source, args)
    local Player = RS.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetGang(tostring(args[2]), tonumber(args[3]))
    else
        TriggerClientEvent('RS:Notify', source, Lang:t('error.not_online'), 'error')
    end
end, 'admin')

-- Me command
RS.Commands.Add('me', Lang:t("command.me.help"), {{name = Lang:t("command.me.params.message.name"), help = Lang:t("command.me.params.message.help")}}, false, function(source, args)
    local text = ''
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ' '
   TriggerClientEvent('RS:triggerDisplay', -1, text, source , "me")
   TriggerClientEvent("sendProximityMessage", -1, source, "Citizen [" .. source .. "]", text, { 255, 255, 255 })
end, 'user')

RS.Commands.Add('do', Lang:t("command.me.help"), {{name = Lang:t("command.me.params.message.name"), help = Lang:t("command.me.params.message.help")}}, false, function(source, args)
    local text = ''
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ' '
   TriggerClientEvent('RS:triggerDisplay', -1, text, source , "do")
   TriggerClientEvent("sendProximityMessage", -1, source, "Citizen [" .. source .. "]", text, { 145, 209, 144 })
end, 'user')

RS.Commands.Add('try', Lang:t("command.me.help"), {{name = Lang:t("command.me.params.message.name"), help = Lang:t("command.me.params.message.help")}}, false, function(source, args)
    local text = ''
    local random = math.random(1,2)
    for i = 1,#args do
        text = text .. ' ' .. args[i]
    end
    text = text .. ' '
    if random == 1 then
        text = 'He succeeded in trying'..text
    else
        text = 'He has failed trying '..text
    end
   TriggerClientEvent('RS:triggerDisplay', -1, text, source , "try")
   TriggerClientEvent("sendProximityMessage", -1, source, "Citizen [" .. source .. "]", text, { 32, 151, 247 })
end, 'user')

-- IDs
RS.Commands.Add("id", "Check Your ID #", {}, false, function(source)
    local src = source
    local Player = RS.Functions.GetPlayer(src)
    TriggerClientEvent('RS:Notify', source, "ID: "..source, 'primary')
end, 'user')

RS.Commands.Add("cid", "Check Your Citizen ID #", {}, false, function(source)
    local src = source
    local Player = RS.Functions.GetPlayer(src)
    local Playercid = Player.PlayerData.citizenid
    TriggerClientEvent('RS:Notify', source, "Citizen ID: "..Playercid, 'primary')
end, 'user')
