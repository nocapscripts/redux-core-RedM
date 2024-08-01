RS.Database = {}





RS.Database = {
    Execute = function(Query, Data, cb, Wait)
        local RtnData = {}
        local Waiting = true
        local Wait = Wait ~= nil and Wait or false
        MySQL.query(Query, Data, function(ReturnData)
			if cb ~= nil and not Wait then
                cb(ReturnData)
            end
            RtnData = ReturnData
			Waiting = false
        end)
        if Wait then
            while Waiting do
                Citizen.Wait(5)
            end
            if cb ~= nil and Wait then
                cb(RtnData)
            end
        end
        return RtnData
    end,
    Insert = function(Query, Data, cb, Wait)
        local RtnData = {}
        local Waiting = true
        localWait = Wait ~= nil and Wait or false
        MySQL.insert(Query, Data, function(ReturnData)
			if cb ~= nil and not Wait then
                cb(ReturnData)
            end
            RtnData = ReturnData
			Waiting = false
        end)
        if Wait then
            while Waiting do
                Citizen.Wait(5)
            end
            if cb ~= nil and Wait then
                cb(RtnData)
            end
        end
        return RtnData
    end,  
    Update = function(Query, Data, cb, Wait)
        local RtnData = {}
        local Waiting = true
        local Wait = Wait ~= nil and Wait or false
        MySQL.update(Query, Data, function(ReturnData)
			if cb ~= nil and not Wait then
                cb(ReturnData)
            end
            RtnData = ReturnData
			Waiting = false
        end)
        if Wait then
            while Waiting do
                Citizen.Wait(5)
            end
            if cb ~= nil and Wait then
                cb(RtnData)
            end
        end
        return RtnData
    end

    

}