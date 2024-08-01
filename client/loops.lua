CreateThread(function()
    while true do
        local sleep = 0
        if LocalPlayer.state.isLoggedIn then
            sleep = (1000 * 60) * RSConfig.Config.UpdateInterval
            TriggerServerEvent('RS:UpdatePlayer')
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            if (RS.PlayerData.metadata['hunger'] <= 0 or RS.PlayerData.metadata['thirst'] <= 0) and not RS.PlayerData.metadata['isdead'] then
                local currentHealth = GetEntityHealth(cache.ped)
                local decreaseThreshold = math.random(5, 10)
                SetEntityHealth(cache.ped, currentHealth - decreaseThreshold)
            end
        end
        Wait(RSConfig.Config.StatusInterval)
    end
end)
