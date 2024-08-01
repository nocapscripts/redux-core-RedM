-- Initialize RS.Util if it doesn't exist
RS.Util = RS.Util or {}

-- Convert a hex ID to a Steam ID
function RS.Util.HexIdToSteamId(self, hexid)
    local cid = self:HexIdToComId(hexid)
    local steam64 = math.floor(tonumber(string.sub(cid, 2)))
    local a = steam64 % 2 == 0 and 0 or 1
    local b = math.floor(math.abs(6561197960265728 - steam64 - a) / 2)
    local sid = "STEAM_0:" .. a .. ":" .. (a == 1 and b - 1 or b)
    return sid
end

-- Convert a hex ID to a community ID
function RS.Util.HexIdToComId(self, hexid)
    return math.floor(tonumber(string.sub(hexid, 7), 16))
end

-- Get the Steam ID from the player identifiers
function RS.Util.GetHexId(self, src)
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, 5) == "steam" then
            return v
        end
    end
    return false
end

-- Get the license from the player identifiers
function RS.Util.GetLicense(self, src)
    local sid = tonumber(src)
    local licenses = {}

    licenses = GetPlayerIdentifiers(sid)

    
    for k,v in ipairs(licenses) do
        if string.sub(v, 1, 7) == "license" then
            return v
        end
    end
   -- return false
end

-- Get an identifier of a specific type from the player identifiers
function RS.Util.GetIdType(self, src, type)
    local len = string.len(type)
    local sid = tonumber(src)
    for _, v in ipairs(GetPlayerIdentifiers(sid)) do
        if string.sub(v, 1, len) == type then
            return v
        end
    end
    return false
end

-- Split a string by a separator
function RS.Util.Stringsplit(self, inputstr, sep)
    sep = sep or "%s"
    local t = {}
    local i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- Check if a string is a valid Steam ID
function RS.Util.IsSteamId(self, id)
    id = tostring(id)
    return id and string.match(id, "^STEAM_[01]:[01]:%d+$") ~= nil
end

-- Format a number with commas
function RS.Util.CommaValue(self, n)
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end