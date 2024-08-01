-- Add or change (a) method(s) in the RS.Functions table
local function SetMethod(methodName, handler)
    if type(methodName) ~= "string" then
        return false, "invalid_method_name"
    end

    RS.Functions[methodName] = handler

    TriggerEvent('RS:Server:UpdateObject')

    return true, "success"
end

RS.Functions.SetMethod = SetMethod
exports("SetMethod", SetMethod)

-- Add or change (a) field(s) in the RS table
local function SetField(fieldName, data)
    if type(fieldName) ~= "string" then
        return false, "invalid_field_name"
    end

    RS[fieldName] = data

    TriggerEvent('RS:Server:UpdateObject')

    return true, "success"
end

RS.Functions.SetField = SetField
exports("SetField", SetField)

-- Single add job function which should only be used if you planning on adding a single job
local function AddJob(jobName, job)
    if type(jobName) ~= "string" then
        return false, "invalid_job_name"
    end

    if RS.Shared.Jobs[jobName] then
        return false, "job_exists"
    end

    RS.Shared.Jobs[jobName] = job

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.AddJob = AddJob
exports('AddJob', AddJob)

-- Multiple Add Jobs
local function AddJobs(jobs)
    local shouldContinue = true
    local message = "success"
    local errorItem = nil

    for key, value in pairs(jobs) do
        if type(key) ~= "string" then
            message = 'invalid_job_name'
            shouldContinue = false
            errorItem = jobs[key]
            break
        end

        if RS.Shared.Jobs[key] then
            message = 'job_exists'
            shouldContinue = false
            errorItem = jobs[key]
            break
        end

        RS.Shared.Jobs[key] = value
    end

    if not shouldContinue then return false, message, errorItem end
    TriggerClientEvent('RS:Client:OnSharedUpdateMultiple', -1, 'Jobs', jobs)
    TriggerEvent('RS:Server:UpdateObject')
    return true, message, nil
end

RS.Functions.AddJobs = AddJobs
exports('AddJobs', AddJobs)

-- Single Remove Job
local function RemoveJob(jobName)
    if type(jobName) ~= "string" then
        return false, "invalid_job_name"
    end

    if not RS.Shared.Jobs[jobName] then
        return false, "job_not_exists"
    end

    RS.Shared.Jobs[jobName] = nil

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Jobs', jobName, nil)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.RemoveJob = RemoveJob
exports('RemoveJob', RemoveJob)

-- Single Update Job
local function UpdateJob(jobName, job)
    if type(jobName) ~= "string" then
        return false, "invalid_job_name"
    end

    if not RS.Shared.Jobs[jobName] then
        return false, "job_not_exists"
    end

    RS.Shared.Jobs[jobName] = job

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.UpdateJob = UpdateJob
exports('UpdateJob', UpdateJob)

-- Single add item
local function AddItem(itemName, item)
    if type(itemName) ~= "string" then
        return false, "invalid_item_name"
    end

    if RS.Shared.Items[itemName] then
        return false, "item_exists"
    end

    RS.Shared.Items[itemName] = item

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Items', itemName, item)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.AddItem = AddItem
exports('AddItem', AddItem)

-- Single update item
local function UpdateItem(itemName, item)
    if type(itemName) ~= "string" then
        return false, "invalid_item_name"
    end
    if not RS.Shared.Items[itemName] then
        return false, "item_not_exists"
    end
    RS.Shared.Items[itemName] = item
    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Items', itemName, item)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.UpdateItem = UpdateItem
exports('UpdateItem', UpdateItem)

-- Multiple Add Items
local function AddItems(items)
    local shouldContinue = true
    local message = "success"
    local errorItem = nil

    for key, value in pairs(items) do
        if type(key) ~= "string" then
            message = "invalid_item_name"
            shouldContinue = false
            errorItem = items[key]
            break
        end

        if RS.Shared.Items[key] then
            message = "item_exists"
            shouldContinue = false
            errorItem = items[key]
            break
        end

        RS.Shared.Items[key] = value
    end

    if not shouldContinue then return false, message, errorItem end
    TriggerClientEvent('RS:Client:OnSharedUpdateMultiple', -1, 'Items', items)
    TriggerEvent('RS:Server:UpdateObject')
    return true, message, nil
end

RS.Functions.AddItems = AddItems
exports('AddItems', AddItems)

-- Single Remove Item
local function RemoveItem(itemName)
    if type(itemName) ~= "string" then
        return false, "invalid_item_name"
    end

    if not RS.Shared.Items[itemName] then
        return false, "item_not_exists"
    end

    RS.Shared.Items[itemName] = nil

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Items', itemName, nil)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.RemoveItem = RemoveItem
exports('RemoveItem', RemoveItem)

-- Single Add Gang
local function AddGang(gangName, gang)
    if type(gangName) ~= "string" then
        return false, "invalid_gang_name"
    end

    if RS.Shared.Gangs[gangName] then
        return false, "gang_exists"
    end

    RS.Shared.Gangs[gangName] = gang

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.AddGang = AddGang
exports('AddGang', AddGang)

-- Multiple Add Gangs
local function AddGangs(gangs)
    local shouldContinue = true
    local message = "success"
    local errorItem = nil

    for key, value in pairs(gangs) do
        if type(key) ~= "string" then
            message = "invalid_gang_name"
            shouldContinue = false
            errorItem = gangs[key]
            break
        end

        if RS.Shared.Gangs[key] then
            message = "gang_exists"
            shouldContinue = false
            errorItem = gangs[key]
            break
        end

        RS.Shared.Gangs[key] = value
    end

    if not shouldContinue then return false, message, errorItem end
    TriggerClientEvent('RS:Client:OnSharedUpdateMultiple', -1, 'Gangs', gangs)
    TriggerEvent('RS:Server:UpdateObject')
    return true, message, nil
end

RS.Functions.AddGangs = AddGangs
exports('AddGangs', AddGangs)

-- Single Remove Gang
local function RemoveGang(gangName)
    if type(gangName) ~= "string" then
        return false, "invalid_gang_name"
    end

    if not RS.Shared.Gangs[gangName] then
        return false, "gang_not_exists"
    end

    RS.Shared.Gangs[gangName] = nil

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Gangs', gangName, nil)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.RemoveGang = RemoveGang
exports('RemoveGang', RemoveGang)

-- Single Update Gang
local function UpdateGang(gangName, gang)
    if type(gangName) ~= "string" then
        return false, "invalid_gang_name"
    end

    if not RS.Shared.Gangs[gangName] then
        return false, "gang_not_exists"
    end

    RS.Shared.Gangs[gangName] = gang

    TriggerClientEvent('RS:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('RS:Server:UpdateObject')
    return true, "success"
end

RS.Functions.UpdateGang = UpdateGang
exports('UpdateGang', UpdateGang)

local function GetCoreVersion(InvokingResource)
    local resourceVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
    if InvokingResource and InvokingResource ~= '' then
        print(("%s called RS version check: %s"):format(InvokingResource or 'Unknown Resource', resourceVersion))
    end
    return resourceVersion
end

RS.Functions.GetCoreVersion = GetCoreVersion
exports('GetCoreVersion', GetCoreVersion)

local function ExploitBan(playerId, origin)
    local name = GetPlayerName(playerId)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        name,
        RS.Functions.GetIdentifier(playerId, 'license'),
        RS.Functions.GetIdentifier(playerId, 'discord'),
        RS.Functions.GetIdentifier(playerId, 'ip'),
        origin,
        2147483647,
        'Anti Cheat'
    })
    DropPlayer(playerId, Lang:t('info.exploit_banned', {discord = RS.Config.Server.Discord}))
    TriggerEvent("redux-log:server:CreateLog", "anticheat", "Anti-Cheat", "red", name .. " has been banned for exploiting " .. origin, true)
end

exports('ExploitBan', ExploitBan)
