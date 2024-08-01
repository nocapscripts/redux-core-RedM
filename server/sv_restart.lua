--[[

    Functions

]]

function kickAllPlayers()
    local players = GetPlayers()
    for i, v in ipairs(players) do
        DropPlayer(v, "Server Restarting...")
    end
end

function restartServer()
    TriggerClientEvent("DoLongHudText", -1, "SÜSTEEM: Server taaskäivitub 10 minuti pärast!", "warning")
    Citizen.Wait(300000)
    TriggerClientEvent("DoLongHudText", -1, "SÜSTEEM: Server taaskäivitub 5 minuti pärast!", "warning")
    Citizen.Wait(60000)
    TriggerClientEvent("DoLongHudText", -1, "SÜSTEEM: Server taaskäivitub 4 minuti pärast!", "warning")
    Citizen.Wait(60000)
    TriggerClientEvent("DoLongHudText", -1, "SÜSTEEM: Server taaskäivitub 3 minuti pärast!", "warning")
    Citizen.Wait(60000)
    TriggerClientEvent("DoLongHudText", -1, "SÜSTEEM: Server taaskäivitub 2 minuti pärast!", "warning")
    Citizen.Wait(60000)
    TriggerClientEvent("DoLongHudText", -1, "SÜSTEEM: Server taaskäivitub 1 minuti pärast!", "warning")
    Citizen.Wait(60000)

    kickAllPlayers()
    Citizen.Wait(1000)
    io.popen("start start.bat")
    Citizen.Wait(300)
    os.exit()
end

function gitPull()
    io.popen("start gitpull.bat")
end

--[[

    Threads

]]

Citizen.CreateThread(function()
    Citizen.Wait(90000)

    -- 03:00
 --   TriggerEvent("cron:runAt", 02, 50, gitPull)
    TriggerEvent("cron:runAt", 02, 50, restartServer)

    -- 11:00
   -- TriggerEvent("cron:runAt", 10, 50, gitPull)
    TriggerEvent("cron:runAt", 10, 50, restartServer)

    -- 19:00
    --TriggerEvent("cron:runAt", 18, 50, gitPull)
   TriggerEvent("cron:runAt", 18, 50, restartServer)

   -- 03:00

   TriggerEvent("cron:runAt", 03, 00, restartServer)

   
   -- 06:00
   TriggerEvent("cron:runAt", 06, 00, restartServer)
end)