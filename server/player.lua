RS.Players = {}
RS.Player = {}

-- On player login get their data or set defaults
-- Don't touch any of this unless you know what you are doing
-- Will cause major issues!

function RS.Player.Login(source, citizenid, newData)
    if source and source ~= "" then
        if citizenid then
            local license = RS.Functions.GetIdentifier(source, "license")
            local PlayerData = MySQL.prepare.await("SELECT * FROM players where citizenid = ?", { citizenid })
            if PlayerData and license == PlayerData.license then
                PlayerData.money = json.decode(PlayerData.money)
                PlayerData.job = json.decode(PlayerData.job)
                PlayerData.position = json.decode(PlayerData.position)
                PlayerData.metadata = json.decode(PlayerData.metadata)
                PlayerData.charinfo = json.decode(PlayerData.charinfo)
                if PlayerData.gang then
                    PlayerData.gang = json.decode(PlayerData.gang)
                else
                    PlayerData.gang = {}
                end
                RS.Player.CheckPlayerData(source, PlayerData)
            else
                DropPlayer(source, Lang:t("info.exploit_dropped"))
                TriggerEvent(
                    "redux-log:server:CreateLog",
                    "anticheat",
                    "Anti-Cheat",
                    "white",
                    GetPlayerName(source) .. " Has Been Dropped For Character Joining Exploit",
                    false
                )
            end
        else
            RS.Player.CheckPlayerData(source, newData)
        end
        return true
    else
        RS.ShowError(GetCurrentResourceName(), "ERROR RS.PLAYER.LOGIN - NO SOURCE GIVEN!")
        return false
    end
end

function RS.Player.GetOfflinePlayer(citizenid)
    if citizenid then
        local PlayerData = MySQL.Sync.prepare("SELECT * FROM players where citizenid = ?", { citizenid })
        if PlayerData then
            PlayerData.money = json.decode(PlayerData.money)
            PlayerData.job = json.decode(PlayerData.job)
            PlayerData.position = json.decode(PlayerData.position)
            PlayerData.metadata = json.decode(PlayerData.metadata)
            PlayerData.charinfo = json.decode(PlayerData.charinfo)
            if PlayerData.gang then
                PlayerData.gang = json.decode(PlayerData.gang)
            else
                PlayerData.gang = {}
            end
            return RS.Player.CheckPlayerData(nil, PlayerData)
        end
    end
    return nil
end

local function applyDefaults(playerData, defaults)
    for key, value in pairs(defaults) do
        if type(value) == 'function' then
            playerData[key] = playerData[key] or value()
        elseif type(value) == 'table' then
            playerData[key] = playerData[key] or {}
            applyDefaults(playerData[key], value)
        else
            playerData[key] = playerData[key] or value
        end
    end
end



function RS.Player.CheckPlayerData(source, PlayerData)
    PlayerData = PlayerData or {}
    local Offline = not source

    if source then
        PlayerData.source = source
        
        PlayerData.fullname = PlayerData.charinfo.firstname.. ' '..PlayerData.charinfo.lastname
        PlayerData.charinfo.fullname = PlayerData.charinfo.firstname.. ' ' ..PlayerData.charinfo.lastname
        PlayerData.license = PlayerData.license or RS.Util:GetHexId(source)
        PlayerData.name = GetPlayerName(source)
    end

    local validatedJob = false
    if PlayerData.job and PlayerData.job.name ~= nil and PlayerData.job.grade and PlayerData.job.grade.level ~= nil then
        local jobInfo = RS.Shared.Jobs[PlayerData.job.name]

        if jobInfo then
            local jobGradeInfo = jobInfo.grades[tostring(PlayerData.job.grade.level)]
            if jobGradeInfo then
                PlayerData.job.label = jobInfo.label
                PlayerData.job.grade.name = jobGradeInfo.name
                PlayerData.job.payment = jobGradeInfo.payment
                PlayerData.job.grade.isboss = jobGradeInfo.isboss or false
                PlayerData.job.isboss = jobGradeInfo.isboss or false
                validatedJob = true
            end
        end
    end

    if validatedJob == false then
        -- set to nil, as the default job (unemployed) will be added by `applyDefaults`
        PlayerData.job = nil
    end

    local validatedGang = false
    if PlayerData.gang and PlayerData.gang.name ~= nil and PlayerData.gang.grade and PlayerData.gang.grade.level ~= nil then
        local gangInfo = RS.Shared.Gangs[PlayerData.gang.name]

        if gangInfo then
            local gangGradeInfo = gangInfo.grades[tostring(PlayerData.gang.grade.level)]
            if gangGradeInfo then
                PlayerData.gang.label = gangInfo.label
                PlayerData.gang.grade.name = gangGradeInfo.name
                PlayerData.gang.payment = gangGradeInfo.payment
                PlayerData.gang.grade.isboss = gangGradeInfo.isboss or false
                PlayerData.gang.isboss = gangGradeInfo.isboss or false
                validatedGang = true
            end
        end
    end

    if validatedGang == false then
        -- set to nil, as the default gang (unemployed) will be added by `applyDefaults`
        PlayerData.gang = nil
    end

    applyDefaults(PlayerData, RS.Config.Player.PlayerDefaults)

    if GetResourceState('qb-inventory') ~= 'missing' then
        PlayerData.items = exports['qb-inventory']:LoadInventory(PlayerData.source, PlayerData.citizenid)
    end

    return RS.Player.CreatePlayer(PlayerData, Offline)
end


-- On player logout

function RS.Player.Logout(source)
    TriggerClientEvent("RS:Client:OnPlayerUnload", source)
    TriggerEvent("RS:Server:OnPlayerUnload", source)
    TriggerClientEvent("RS:Player:UpdatePlayerData", source)
    Wait(200)
    RS.Players[source] = nil
end

-- Create a new character
-- Don't touch any of this unless you know what you are doing
-- Will cause major issues!

function RS.Player.CreatePlayer(PlayerData, Offline)
    local self = {}
    self.Functions = {}
    self.PlayerData = PlayerData
    self.Offline = Offline

    function self.Functions.UpdatePlayerData()
        if self.Offline then
            return
        end -- Unsupported for Offline Players
        TriggerEvent("RS:Player:SetPlayerData", self.PlayerData)
        TriggerClientEvent("RS:Player:SetPlayerData", self.PlayerData.source, self.PlayerData)
    end

    function self.Functions.SetJob(job, grade)
        job = job:lower()
        grade = tostring(grade) or "0"
        if not RS.Shared.Jobs[job] then
            return false
        end
        self.PlayerData.job.name = job
        self.PlayerData.job.label = RS.Shared.Jobs[job].label
        self.PlayerData.job.onduty = RS.Shared.Jobs[job].defaultDuty
        self.PlayerData.job.type = RS.Shared.Jobs[job].type or "none"
        if RS.Shared.Jobs[job].grades[grade] then
            local jobgrade = RS.Shared.Jobs[job].grades[grade]
            self.PlayerData.job.grade = {}
            self.PlayerData.job.grade.name = jobgrade.name
            self.PlayerData.job.grade.level = tonumber(grade)
            self.PlayerData.job.payment = jobgrade.payment or 30
            self.PlayerData.job.isboss = jobgrade.isboss or false
        else
            self.PlayerData.job.grade = {}
            self.PlayerData.job.grade.name = "No Grades"
            self.PlayerData.job.grade.level = 0
            self.PlayerData.job.payment = 30
            self.PlayerData.job.isboss = false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerEvent("RS:Server:OnJobUpdate", self.PlayerData.source, self.PlayerData.job)
            TriggerClientEvent("RS:Client:OnJobUpdate", self.PlayerData.source, self.PlayerData.job)
        end

        return true
    end

    function self.Functions.SetGang(gang, grade)
        gang = gang:lower()
        grade = tostring(grade) or "0"
        if not RS.Shared.Gangs[gang] then
            return false
        end
        self.PlayerData.gang.name = gang
        self.PlayerData.gang.label = RS.Shared.Gangs[gang].label
        if RS.Shared.Gangs[gang].grades[grade] then
            local ganggrade = RS.Shared.Gangs[gang].grades[grade]
            self.PlayerData.gang.grade = {}
            self.PlayerData.gang.grade.name = ganggrade.name
            self.PlayerData.gang.grade.level = tonumber(grade)
            self.PlayerData.gang.isboss = ganggrade.isboss or false
        else
            self.PlayerData.gang.grade = {}
            self.PlayerData.gang.grade.name = "No Grades"
            self.PlayerData.gang.grade.level = 0
            self.PlayerData.gang.isboss = false
        end

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerEvent("RS:Server:OnGangUpdate", self.PlayerData.source, self.PlayerData.gang)
            TriggerClientEvent("RS:Client:OnGangUpdate", self.PlayerData.source, self.PlayerData.gang)
        end

        return true
    end

    function self.Functions.SetJobDuty(onDuty)
        self.PlayerData.job.onduty = not not onDuty -- Make sure the value is a boolean if nil is sent
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.SetPlayerData(key, val)
        if not key or type(key) ~= "string" then
            return
        end
        self.PlayerData[key] = val
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.SetMetaData(meta, val)
        if not meta or type(meta) ~= "string" then
            return
        end
        if meta == "hunger" or meta == "thirst" then
            val = val > 100 and 100 or val
        end
        self.PlayerData.metadata[meta] = val
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.GetMetaData(meta)
        if not meta or type(meta) ~= "string" then
            return
        end
        return self.PlayerData.metadata[meta]
    end

    function self.Functions.AddJobReputation(amount)
        if not amount then
            return
        end
        amount = tonumber(amount)
        self.PlayerData.metadata["jobrep"][self.PlayerData.job.name] = self.PlayerData.metadata["jobrep"][self.PlayerData.job.name]
            + amount
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.AddMoney(moneytype, amount, reason, showhud)
        reason = reason or "unknown"
        if showhud == nil then showhud = true end
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then
            return
        end
        if not self.PlayerData.money[moneytype] then
            return false
        end
        self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] + amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            if amount > 100000 then
                TriggerEvent(
                    "redux-log:server:CreateLog",
                    "playermoney",
                    "AddMoney",
                    "lightgreen",
                    "**"
                        .. GetPlayerName(self.PlayerData.source)
                        .. " (citizenid: "
                        .. self.PlayerData.citizenid
                        .. " | id: "
                        .. self.PlayerData.source
                        .. ")** $"
                        .. amount
                        .. " ("
                        .. moneytype
                        .. ") added, new "
                        .. moneytype
                        .. " balance: "
                        .. self.PlayerData.money[moneytype]
                        .. " reason: "
                        .. reason,
                    true
                )
            else
                TriggerEvent(
                    "redux-log:server:CreateLog",
                    "playermoney",
                    "AddMoney",
                    "lightgreen",
                    "**"
                        .. GetPlayerName(self.PlayerData.source)
                        .. " (citizenid: "
                        .. self.PlayerData.citizenid
                        .. " | id: "
                        .. self.PlayerData.source
                        .. ")** $"
                        .. amount
                        .. " ("
                        .. moneytype
                        .. ") added, new "
                        .. moneytype
                        .. " balance: "
                        .. self.PlayerData.money[moneytype]
                        .. " reason: "
                        .. reason
                )
            end
            if showhud then TriggerClientEvent("hud:client:OnMoneyChange", self.PlayerData.source, moneytype, amount, false) end
            TriggerClientEvent("RS:Client:OnMoneyChange", self.PlayerData.source, moneytype, amount, "add", reason)
            TriggerEvent("RS:Server:OnMoneyChange", self.PlayerData.source, moneytype, amount, "add", reason)
        end

        return true
    end

    function self.Functions.RemoveMoney(moneytype, amount, reason, showhud)
        reason = reason or "unknown"
        if showhud == nil then showhud = true end
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then
            return
        end
        if not self.PlayerData.money[moneytype] then
            return false
        end
        for _, mtype in pairs(RS.Config.Money.DontAllowMinus) do
            if mtype == moneytype then
                if (self.PlayerData.money[moneytype] - amount) < 0 then
                    return false
                end
            end
        end
        self.PlayerData.money[moneytype] = self.PlayerData.money[moneytype] - amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            if amount > 100000 then
                TriggerEvent(
                    "redux-log:server:CreateLog",
                    "playermoney",
                    "RemoveMoney",
                    "red",
                    "**"
                        .. GetPlayerName(self.PlayerData.source)
                        .. " (citizenid: "
                        .. self.PlayerData.citizenid
                        .. " | id: "
                        .. self.PlayerData.source
                        .. ")** $"
                        .. amount
                        .. " ("
                        .. moneytype
                        .. ") removed, new "
                        .. moneytype
                        .. " balance: "
                        .. self.PlayerData.money[moneytype]
                        .. " reason: "
                        .. reason,
                    true
                )
            else
                TriggerEvent(
                    "redux-log:server:CreateLog",
                    "playermoney",
                    "RemoveMoney",
                    "red",
                    "**"
                        .. GetPlayerName(self.PlayerData.source)
                        .. " (citizenid: "
                        .. self.PlayerData.citizenid
                        .. " | id: "
                        .. self.PlayerData.source
                        .. ")** $"
                        .. amount
                        .. " ("
                        .. moneytype
                        .. ") removed, new "
                        .. moneytype
                        .. " balance: "
                        .. self.PlayerData.money[moneytype]
                        .. " reason: "
                        .. reason
                )
            end
            if showhud then TriggerClientEvent("hud:client:OnMoneyChange", self.PlayerData.source, moneytype, amount, true) end
            TriggerClientEvent("RS:Client:OnMoneyChange", self.PlayerData.source, moneytype, amount, "remove", reason)
            TriggerEvent("RS:Server:OnMoneyChange", self.PlayerData.source, moneytype, amount, "remove", reason)
        end

        return true
    end

    function self.Functions.SetMoney(moneytype, amount, reason)
        reason = reason or "unknown"
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        if amount < 0 then
            return false
        end
        if not self.PlayerData.money[moneytype] then
            return false
        end
        local difference = amount - self.PlayerData.money[moneytype]
        self.PlayerData.money[moneytype] = amount

        if not self.Offline then
            self.Functions.UpdatePlayerData()
            TriggerEvent(
                "redux-log:server:CreateLog",
                "playermoney",
                "SetMoney",
                "green",
                "**"
                    .. GetPlayerName(self.PlayerData.source)
                    .. " (citizenid: "
                    .. self.PlayerData.citizenid
                    .. " | id: "
                    .. self.PlayerData.source
                    .. ")** $"
                    .. amount
                    .. " ("
                    .. moneytype
                    .. ") set, new "
                    .. moneytype
                    .. " balance: "
                    .. self.PlayerData.money[moneytype]
                    .. " reason: "
                    .. reason
            )
            TriggerClientEvent(
                "hud:client:OnMoneyChange",
                self.PlayerData.source,
                moneytype,
                math.abs(difference),
                difference < 0
            )
            TriggerClientEvent("RS:Client:OnMoneyChange", self.PlayerData.source, moneytype, amount, "set", reason)
            TriggerEvent("RS:Server:OnMoneyChange", self.PlayerData.source, moneytype, amount, "set", reason)
        end

        return true
    end

    function self.Functions.GetMoney(moneytype)
        if not moneytype then
            return false
        end
        moneytype = moneytype:lower()
        return self.PlayerData.money[moneytype]
    end

    function self.Functions.Save()
        if self.Offline then
            RS.Player.SaveOffline(self.PlayerData)
        else
            RS.Player.Save(self.PlayerData.source)
        end
    end

    function self.Functions.Logout()
        if self.Offline then
            return
        end -- Unsupported for Offline Players
        RS.Player.Logout(self.PlayerData.source)
    end

    function self.Functions.AddMethod(methodName, handler)
        self.Functions[methodName] = handler
    end

    function self.Functions.AddField(fieldName, data)
        self[fieldName] = data
    end

    if self.Offline then
        return self
    else
        RS.Players[self.PlayerData.source] = self
        RS.Player.Save(self.PlayerData.source)

        -- At this point we are safe to emit new instance to third party resource for load handling
        TriggerEvent("RS:Server:PlayerLoaded", self)
        self.Functions.UpdatePlayerData()
    end
end

-- Add a new function to the Functions table of the player class
-- Use-case:
--[[
    AddEventHandler('RS:Server:PlayerLoaded', function(Player)
        RS.Functions.AddPlayerMethod(Player.PlayerData.source, "functionName", function(oneArg, orMore)
            -- do something here
        end)
    end)
]]

function RS.Functions.AddPlayerMethod(ids, methodName, handler)
    local idType = type(ids)
    if idType == "number" then
        if ids == -1 then
            for _, v in pairs(RS.Players) do
                v.Functions.AddMethod(methodName, handler)
            end
        else
            if not RS.Players[ids] then
                return
            end

            RS.Players[ids].Functions.AddMethod(methodName, handler)
        end
    elseif idType == "table" and table.type(ids) == "array" then
        for i = 1, #ids do
            RS.Functions.AddPlayerMethod(ids[i], methodName, handler)
        end
    end
end

-- Add a new field table of the player class
-- Use-case:
--[[
    AddEventHandler('RS:Server:PlayerLoaded', function(Player)
        RS.Functions.AddPlayerField(Player.PlayerData.source, "fieldName", "fieldData")
    end)
]]

function RS.Functions.AddPlayerField(ids, fieldName, data)
    local idType = type(ids)
    if idType == "number" then
        if ids == -1 then
            for _, v in pairs(RS.Players) do
                v.Functions.AddField(fieldName, data)
            end
        else
            if not RS.Players[ids] then
                return
            end

            RS.Players[ids].Functions.AddField(fieldName, data)
        end
    elseif idType == "table" and table.type(ids) == "array" then
        for i = 1, #ids do
            RS.Functions.AddPlayerField(ids[i], fieldName, data)
        end
    end
end

-- Save player info to database (make sure citizenid is the primary key in your database)

function RS.Player.Save(source)
    local ped = GetPlayerPed(source)
    local pcoords = GetEntityCoords(ped)
    local PlayerData = RS.Players[source].PlayerData
    if PlayerData then
        MySQL.Async.insert(
            "INSERT INTO players (citizenid, cid, license, name, fullname, money, charinfo, job, gang, position, metadata) VALUES (:citizenid, :cid, :license, :name, :fullname, :money, :charinfo, :job, :gang, :position, :metadata) ON DUPLICATE KEY UPDATE cid = :cid, name = :name, fullname = :fullname, money = :money, charinfo = :charinfo, job = :job, gang = :gang, position = :position, metadata = :metadata",
            {
                citizenid = PlayerData.citizenid,
                cid = tonumber(PlayerData.cid),
                license = PlayerData.license,
                name = PlayerData.name,
                fullname = PlayerData.charinfo.fullname,
                money = json.encode(PlayerData.money),
                charinfo = json.encode(PlayerData.charinfo),
                job = json.encode(PlayerData.job),
                gang = json.encode(PlayerData.gang),
                position = json.encode(pcoords),
                metadata = json.encode(PlayerData.metadata),
            }
        )
        if GetResourceState("redux-inventory") ~= "missing" then
            exports["redux-inventory"]:SaveInventory(source)
        end
        RS.ShowSuccess(GetCurrentResourceName(), PlayerData.name .. " PLAYER SAVED!")
    else
        RS.ShowError(GetCurrentResourceName(), "ERROR RS.PLAYER.SAVE - PLAYERDATA IS EMPTY!")
    end
end

function RS.Player.SaveOffline(PlayerData)
    if PlayerData then
        MySQL.Async.insert(
            "INSERT INTO players (citizenid, cid, license, name, fullname, money, charinfo, job, gang, position, metadata) VALUES (:citizenid, :cid, :license, :name, :fullname, :money, :charinfo, :job, :gang, :position, :metadata) ON DUPLICATE KEY UPDATE cid = :cid, name = :name, fullname = :fullname, money = :money, charinfo = :charinfo, job = :job, gang = :gang, position = :position, metadata = :metadata",
            {
                citizenid = PlayerData.citizenid,
                cid = tonumber(PlayerData.cid),
                license = PlayerData.license,
                name = PlayerData.name,
                fullname = PlayerData.fullname,
                money = json.encode(PlayerData.money),
                charinfo = json.encode(PlayerData.charinfo),
                job = json.encode(PlayerData.job),
                gang = json.encode(PlayerData.gang),
                position = json.encode(pcoords),
                metadata = json.encode(PlayerData.metadata),
            }
        )
        if GetResourceState("redux-inventory") ~= "missing" then
            exports["redux-inventory"]:SaveInventory(PlayerData, true)
        end
        RS.ShowSuccess(GetCurrentResourceName(), PlayerData.name .. " OFFLINE PLAYER SAVED!")
    else
        RS.ShowError(GetCurrentResourceName(), "ERROR RS.PLAYER.SAVEOFFLINE - PLAYERDATA IS EMPTY!")
    end
end

-- Delete character

local playertables = { -- Add tables as needed
    { table = "players"},
    { table = "playeroutfit"},
    { table = "playerskins"},
    { table = "player_horses"},
    { table = "player_weapons"},
    { table = "address_book"},
    { table = "telegrams"},
}

function RS.Player.DeleteCharacter(source, citizenid)
    local license = RS.Functions.GetIdentifier(source, "license")
    local result = MySQL.scalar.await("SELECT license FROM players where citizenid = ?", { citizenid })
    if license == result then
        local query = "DELETE FROM %s WHERE citizenid = ?"
        local tableCount = #playertables
        local queries = table.create(tableCount, 0)
        
        for i = 1, tableCount do
            local v = playertables[i]
            queries[i] = { query = query:format(v.table), values = { citizenid } }
        end
        
        MySQL.transaction(queries, function(result2)
            if result2 then
                TriggerEvent(
                    "redux-log:server:CreateLog",
                    "joinleave",
                    "Character Deleted",
                    "red",
                    "**" .. GetPlayerName(source) .. "** " .. license .. " deleted **" .. citizenid .. "**.."
                )
            end
        end)
    else
        DropPlayer(source, Lang:t("info.exploit_dropped"))
        TriggerEvent(
            "redux-log:server:CreateLog",
            "anticheat",
            "Anti-Cheat",
            "white",
            GetPlayerName(source) .. " Has Been Dropped For Character Deletion Exploit",
            true
        )
    end
end

function RS.Player.ForceDeleteCharacter(citizenid)
    local result = MySQL.scalar.await("SELECT license FROM players where citizenid = ?", { citizenid })
    if result then
        local query = "DELETE FROM %s WHERE citizenid = ?"
        local tableCount = #playertables
        local queries = table.create(tableCount, 0)
        local Player = RS.Functions.GetPlayerByCitizenId(citizenid)

        if Player then
            DropPlayer(Player.PlayerData.source, "An admin deleted the character which you are currently using")
        end
        for i = 1, tableCount do
            local v = playertables[i]
            queries[i] = { query = query:format(v.table), values = { citizenid } }
        end

        MySQL.transaction(queries, function(result2)
            if result2 then
                TriggerEvent(
                    "redux-log:server:CreateLog",
                    "joinleave",
                    "Character Force Deleted",
                    "red",
                    "Character **" .. citizenid .. "** got deleted"
                )
            end
        end)
    end
end

-- Inventory Backwards Compatibility

function RS.Player.SaveInventory(source)
    if GetResourceState("redux-inventory") == "missing" then
        return
    end
    exports["redux-inventory"]:SaveInventory(source, false)
end

function RS.Player.SaveOfflineInventory(PlayerData)
    if GetResourceState("redux-inventory") == "missing" then
        return
    end
    exports["redux-inventory"]:SaveInventory(PlayerData, true)
end

function RS.Player.GetTotalWeight(items)
    if GetResourceState("redux-inventory") == "missing" then
        return
    end
    return exports["redux-inventory"]:GetTotalWeight(items)
end

function RS.Player.GetSlotsByItem(items, itemName)
    if GetResourceState("redux-inventory") == "missing" then
        return
    end
    return exports["redux-inventory"]:GetSlotsByItem(items, itemName)
end

function RS.Player.GetFirstSlotByItem(items, itemName)
    if GetResourceState("redux-inventory") == "missing" then
        return
    end
    return exports["redux-inventory"]:GetFirstSlotByItem(items, itemName)
end

-- Util Functions

function RS.Player.CreateCitizenId()
    local UniqueFound = false
    local CitizenId = nil
    while not UniqueFound do
        CitizenId = tostring(RS.Shared.RandomStr(3) .. RS.Shared.RandomInt(5)):upper()
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM players WHERE citizenid = ?", { CitizenId })
        if result == 0 then
            UniqueFound = true
        end
    end
    return CitizenId
end

function RS.Functions.CreateAccountNumber()
    local UniqueFound = false
    local AccountNumber = nil
    while not UniqueFound do
        AccountNumber = "RSG"
            .. math.random(1, 9)
            .. math.random(1111, 9999)
            .. math.random(1111, 9999)
            .. math.random(11, 99)
        local query = "%" .. AccountNumber .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM players WHERE charinfo LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return AccountNumber
end

function RS.Player.CreateFingerId()
    local UniqueFound = false
    local FingerId = nil
    while not UniqueFound do
        FingerId = tostring(
            RS.Shared.RandomStr(2)
                .. RS.Shared.RandomInt(3)
                .. RS.Shared.RandomStr(1)
                .. RS.Shared.RandomInt(2)
                .. RS.Shared.RandomStr(3)
                .. RS.Shared.RandomInt(4)
        )
        local query = "%" .. FingerId .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM `players` WHERE `metadata` LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return FingerId
end

function RS.Player.CreateWalletId()
    local UniqueFound = false
    local WalletId = nil
    while not UniqueFound do
        WalletId = "redux-" .. math.random(11111111, 99999999)
        local query = "%" .. WalletId .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM players WHERE metadata LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return WalletId
end

function RS.Player.CreateSerialNumber()
    local UniqueFound = false
    local SerialNumber = nil
    while not UniqueFound do
        SerialNumber = math.random(11111111, 99999999)
        local query = "%" .. SerialNumber .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM players WHERE metadata LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return SerialNumber
end

function RS.Player.CreateUser()
    local src = source

    Wait(10)
    RS.DB:PlayerExistsDB(src, function(exists, err)
        if err then
            print("Error checking player existence: " .. err)
            return
        end

        if not exists then
            RS.DB:CreateNewUser(src, function(created, err)
                if err then
                    print("Error creating new user: " .. err)
                    return
                end

                if created then
                    print("User created successfully")
                else
                    print("Failed to create user")
                end
            end)
        else
            print("User already exists")
        end
    end)
end



if RSConfig.Money.PayCheckEnabled then
    PaycheckInterval() -- This starts the paycheck system end
end
