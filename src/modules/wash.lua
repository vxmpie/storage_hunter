local WashModule = {}
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function WashModule.init(Config, Utils)
    local function getWashStationCFrame()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local name = string.lower(obj.Name)
                local action = string.lower(obj.ActionText)
                if string.find(name, "wash") or string.find(action, "wash") or string.find(name, "clean") or string.find(action, "clean") then
                    if obj.Parent and obj.Parent:IsA("BasePart") then
                        return obj.Parent.CFrame
                    end
                end
            end
        end
        return nil
    end

    function WashModule.washInventoryItems()
        warn("WASH_EXECUTE_START")
        local events = ReplicatedStorage:FindFirstChild("Events")
        local wash = events and events:FindFirstChild("Wash")
        if not wash then return end
        
        local getWashable = wash:FindFirstChild("GetWashableItems")
        local startWash = wash:FindFirstChild("StartWash")
        local claimWash = wash:FindFirstChild("ClaimWashedItem")
        local collectWash = wash:FindFirstChild("CollectWash")
        local speedUpWash = wash:FindFirstChild("SpeedUpWash")
        
        if getWashable and startWash then
            local success, data = pcall(function()
                if getWashable:IsA("RemoteFunction") then return getWashable:InvokeServer()
                elseif getWashable:IsA("RemoteEvent") then getWashable:FireServer() end
            end)
            
            if success and type(data) == "table" and data.items then
                local itemsToWash = {}
                for _, item in pairs(data.items) do
                    if item.guid then table.insert(itemsToWash, item.guid) end
                end
                
                if #itemsToWash > 0 then
                    warn("WASH_ITEMS_FOUND_" .. tostring(#itemsToWash))
                    local originalCFrame = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
                    local washCFrame = getWashStationCFrame()
                    
                    if washCFrame then Utils.warpTo(washCFrame); task.wait(0.5) end
                    
                    local guid = itemsToWash[1]
                    
                    pcall(function()
                        for slot = 1, 3 do
                            if startWash:IsA("RemoteFunction") then 
                                pcall(function() startWash:InvokeServer(slot, guid) end)
                                pcall(function() startWash:InvokeServer(guid, slot) end)
                            elseif startWash:IsA("RemoteEvent") then 
                                pcall(function() startWash:FireServer(slot, guid) end)
                                pcall(function() startWash:FireServer(guid, slot) end)
                            end
                        end
                        if startWash:IsA("RemoteFunction") then pcall(function() startWash:InvokeServer(guid) end)
                        elseif startWash:IsA("RemoteEvent") then pcall(function() startWash:FireServer(guid) end) end
                    end)
                    
                    task.wait(1.5)
                    
                    for attempt = 1, 10 do
                        local successDetected = false
                        
                        if speedUpWash then
                            pcall(function()
                                for slot = 1, 3 do
                                    if speedUpWash:IsA("RemoteFunction") then 
                                        pcall(function() speedUpWash:InvokeServer(slot, guid) end)
                                        pcall(function() speedUpWash:InvokeServer(guid, slot) end)
                                    elseif speedUpWash:IsA("RemoteEvent") then 
                                        pcall(function() speedUpWash:FireServer(slot, guid) end)
                                        pcall(function() speedUpWash:FireServer(guid, slot) end)
                                    end
                                end
                            end)
                        end
                        
                        pcall(function()
                            local rems = {claimWash, collectWash}
                            for _, rem in ipairs(rems) do
                                if rem then
                                    for slot = 1, 3 do
                                        if rem:IsA("RemoteFunction") then 
                                            local ok, res = pcall(function() return rem:InvokeServer(slot, guid) end)
                                            if not ok or res == nil then ok, res = pcall(function() return rem:InvokeServer(guid, slot) end) end
                                            
                                            if ok and res ~= nil then
                                                if type(res) == "string" then
                                                    local str = string.lower(res)
                                                    if not string.find(str, "fail") and not string.find(str, "empty") and not string.find(str, "fast") then
                                                        successDetected = true
                                                    end
                                                else
                                                    successDetected = true
                                                end
                                            end
                                        elseif rem:IsA("RemoteEvent") then 
                                            pcall(function() rem:FireServer(slot, guid) end)
                                            pcall(function() rem:FireServer(guid, slot) end)
                                        end
                                    end
                                end
                            end
                        end)
                        
                        if successDetected then break end
                        task.wait(1)
                    end
                    
                    if originalCFrame then task.wait(0.3); Utils.warpTo(originalCFrame) end
                    warn("WASH_FINISHED")
                end
            end
        end
    end

    function WashModule.warpToUnpack()
        local uz = Workspace:FindFirstChild("UnpackZone")
        if not uz then return end
        
        local pad = uz:FindFirstChild("Pad")
        if not pad then return end

        local targetCFrame = pad.CFrame + Vector3.new(0, 4, 0)
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")

        if humanoid and humanoid.SeatPart then
            local vehicle = humanoid.SeatPart:FindFirstAncestorWhichIsA("Model")
            if vehicle then 
                vehicle:PivotTo(targetCFrame) 
            else 
                humanoid.SeatPart.CFrame = targetCFrame 
            end
        else
            Utils.warpTo(pad.CFrame)
        end
        
        task.wait(1)
        
        local vehiclesEvents = ReplicatedStorage:FindFirstChild("Events")
        if not vehiclesEvents then return end
        
        local vehicleFolder = vehiclesEvents:FindFirstChild("Vehicles")
        if not vehicleFolder then return end
        
        local getOwnedVehicles = vehicleFolder:FindFirstChild("GetOwnedVehicles")
        local getVehicleItems = vehicleFolder:FindFirstChild("GetVehicleItems")
        local transferItems = vehicleFolder:FindFirstChild("TransferVehicleItemsToInventory")
        
        if getOwnedVehicles and getVehicleItems and transferItems then
            local successV, resultV = pcall(function() return getOwnedVehicles:InvokeServer() end)
            if successV and type(resultV) == "table" and resultV.equippedGuid then
                local vehicleId = tostring(resultV.equippedGuid)
                local successI, resultI = pcall(function() return getVehicleItems:InvokeServer(vehicleId) end)
                
                if successI and type(resultI) == "table" then
                    local itemsToUnload = {}
                    for itemGuid, _ in pairs(resultI) do 
                        table.insert(itemsToUnload, itemGuid) 
                    end
                    
                    if #itemsToUnload > 0 then
                        transferItems:FireServer(itemsToUnload)
                        task.wait(0.5)
                        
                        if humanoid and humanoid.Sit then 
                            humanoid.Sit = false 
                        end
                    end
                end
            end
        end
    end

    task.spawn(function()
        while task.wait(5) do
            if Config.AutoWash then
                WashModule.washInventoryItems()
            end
        end
    end)
end

return WashModule