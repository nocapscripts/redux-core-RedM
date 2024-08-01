RSConfig = {}

RSConfig.Server = {}
RSConfig.Player = {}
RSConfig.Money = {}
RSConfig.Notify = {}

RSConfig.Join = {
    Debug = true,
    IdentifierType = "steam",
    Whitelist = true,
    PermissionList = {}
}

RSConfig.JoinChecks = {
    Name = true,
    Discord = false,
    Identifier = true,
    Ban = true,
}

RSConfig.MaxPlayers = GetConvarInt('sv_maxclients', 48) -- Gets max players from config file, default 48
RSConfig.DefaultSpawn = vector4(-1035.71, -2731.87, 12.86, 0.0)
RSConfig.UpdateInterval = 1 -- how often to update player data in minutes
RSConfig.StatusInterval = 5000 -- how often to check hunger/thirst status in milliseconds
RSConfig.EnablePVP = true   --- PvP always enabled.  You can use the command /pvp to temporarily disable and re-enable it.
RSConfig.HidePlayerNames = true

RSConfig.Money.MoneyTypes = { cash = 50, bank = 0, valbank = 0, rhobank = 0, blkbank = 0, armbank = 0, bloodmoney = 0 } -- type = startamount - Add or remove money types for your server (for ex. blackmoney = 0), remember once added it will not be removed from the database!
RSConfig.Money.DontAllowMinus = { 'cash', 'bloodmoney' } -- Money that is not allowed going in minus
RSConfig.Money.PayCheckTimeOut = 30 -- The time in minutes that it will give the paycheck
RSConfig.Money.PayCheckSociety = false -- If true paycheck will come from the society account that the player is employed at, requires qb-management
RSConfig.Money.PayCheckEnabled = true -- If false payments will be disabled.

RSConfig.Player.RevealMap = true
RSConfig.Player.HungerRate = 1.0 -- Rate at which hunger goes down.
RSConfig.Player.ThirstRate = 1.0 -- Rate at which thirst goes down.
RSConfig.Player.CleanlinessRate = 0.0 -- Rate at which cleanliness goes down.
RSConfig.Player.Bloodtypes = {
    "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-",
}

RSConfig.Server.Closed = false -- Set server closed (no one can join except people with ace permission 'qbadmin.join')
RSConfig.Server.ClosedReason = "Server Closed" -- Reason message to display when people can't join the server
RSConfig.Server.Uptime = 0 -- Time the server has been up.
RSConfig.Server.Whitelist = false -- Enable or disable whitelist on the server
RSConfig.Server.WhitelistPermission = 'admin' -- Permission that's able to enter the server when the whitelist is on
RSConfig.Server.Discord = "" -- Discord invite link
RSConfig.Server.CheckDuplicateLicense = true -- Check for duplicate rockstar license on join
RSConfig.Server.Permissions = { 'god', 'admin', 'mod' } -- Add as many groups as you want here after creating them in your server.cfg



RSConfig.Notify.NotificationStyling = {
    group = false, -- Allow notifications to stack with a badge instead of repeating
    position = "right", -- top-left | top-right | bottom-left | bottom-right | top | bottom | left | right | center
    progress = true -- Display Progress Bar
}

-- These are how you define different notification variants
-- The "color" key is background of the notification
-- The "icon" key is the css-icon code, this project uses `Material Icons` & `Font Awesome`
RSConfig.NotifyPosition = 'top-left' -- 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left'

-- other settings
RSConfig.PromptDistance = 1.5 -- distance for prompt to trigger (default = 1.5)












RSConfig.Player.PlayerDefaults = {
    citizenid = function() return RS.Player.CreateCitizenId() end,
    cid = 1,
    money = function()
        local moneyDefaults = {}
        for moneytype, startamount in pairs(RSConfig.Money.MoneyTypes) do
            moneyDefaults[moneytype] = startamount
        end
        return moneyDefaults
    end,
    optin = true,

    charinfo = {
        firstname = 'Firstname',
        lastname = 'Lastname',
        birthdate = '00-00-0000',
        gender = 0,
        nationality = 'USA',
        phone = function() return "Pole telefone" end,
        account = function() return RS.Functions.CreateAccountNumber() end
    },
    job = {
        name = 'unemployed',
        label = 'Civilian',
        payment = 10,
        type = 'none',
        onduty = false,
        isboss = false,
        grade = {
            name = 'Freelancer',
            level = 0
        }
    },
    gang = {
        name = 'none',
        label = 'No Gang Affiliation',
        isboss = false,
        grade = {
            name = 'none',
            level = 0
        }
    },
    metadata = {
        hunger = 100,
        thirst = 100,
        stress = 0,
        isdead = false,
        inlaststand = false,
        armor = 0,
        ishandcuffed = false,
        tracker = false,
        injail = 0,
        jailitems = {},
        status = {},
        phone = {},
        rep = {},
        currentapartment = nil,
        callsign = 'NO CALLSIGN',
        bloodtype = function() return RSConfig.Player.Bloodtypes[math.random(1, #RSConfig.Player.Bloodtypes)] end,
        fingerprint = function() return RS.Player.CreateFingerId() end,
        walletid = function() return RS.Player.CreateWalletId() end,
        criminalrecord = {
            hasRecord = false,
            date = nil
        },
        licences = {
            driver = true,
            business = false,
            weapon = false
        },
        inside = {
            house = nil,
            apartment = {
                apartmentType = nil,
                apartmentId = nil,
            }
        },
        phonedata = {
            SerialNumber = function() return RS.Player.CreateSerialNumber() end,
            InstalledApps = {}
        }
    },
    position = RSConfig.DefaultSpawn,
    items = {},
}
