RS = {}
RS.PlayerData = {}
RS.Config = RS
RS.Shared = RSShared
RS.ClientCallbacks = {}
RS.ServerCallbacks = {}


RS.Util = RS.Util

exports('GetCoreObject', function()
    return RS
end)

-- To use this export in a script instead of manifest method
-- Just put this line of code below at the very top of the script
-- local RS = exports['redux-core']:GetCoreObject()
