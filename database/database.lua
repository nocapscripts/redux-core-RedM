RS.DB = {}



function RS.DB.PlayerExistsDB(self, src, callback)
    local hexId = RS.Util:GetHexId(src)
    callback = callback or function() end

    if not hexId or hexId == "" then
        callback(false, "Invalid hexId")
        return
    end

    local query = [[SELECT hex_id FROM users WHERE hex_id = @id LIMIT 1;]]
    local params = {["id"] = hexId}

    exports.oxmysql:execute(query, params, function(results)
        if not results then
            callback(false, "Database query failed")
            return
        end

        local exists = #results > 0
        callback(exists)
    end)
end


function RS.DB.CreateNewUser(self, src, callback)
    local hexid = RS.Util:GetHexId(src)
    callback = callback or function() end

    local data = {
        hexid = hexid,
        communityid = RS.Util:HexIdToComId(hexid),
        steamid = RS.Util:HexIdToSteamId(hexid),
        license = RS.Util:GetLicense(src),
        name = GetPlayerName(src),
        ip = GetPlayerEndpoint(src),
        rank = "user"
    }

    -- Validate data fields
    for k, v in pairs(data) do
        if not v or v == "" then
            callback(false, "Invalid data for field: " .. k)
            return
        end
    end

    local query = [[
        INSERT INTO users (hex_id, steam_id, community_id, license, ip, name, rank)
        VALUES (@hexid, @steamid, @comid, @license, @ip, @name, @rank);
    ]]
    local params = {
        ["hexid"] = data.hexid,
        ["steamid"] = data.steamid,
        ["comid"] = data.communityid,
        ["license"] = data.license,
        ["ip"] = data.ip,
        ["name"] = data.name,
        ["rank"] = data.rank
    }

    exports.oxmysql:execute(query, params, function(result)
        if not result or result.affectedRows == 0 then
            callback(false, "Database insertion failed or no rows affected")
            return
        end

        callback(true)
    end)
end