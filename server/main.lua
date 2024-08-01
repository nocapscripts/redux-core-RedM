RS = RS or {}
RS.Config = RSConfig
RS.Shared = RSShared
RS.ClientCallbacks = {}
RS.ServerCallbacks = {}



RS.Util = RS.Util
RS.Database = RS.Database
RS.DB = RS.DB




exports('GetCoreObject', function()
    return RS
end)

-----------------------------------------------------------------------

-- To use this export in a script instead of manifest method
-- Just put this line of code below at the very top of the script
-- local RS = exports['redux-core']:GetCoreObject()
