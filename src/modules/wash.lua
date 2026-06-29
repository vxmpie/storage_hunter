local WashModule = {}
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function WashModule.init(Config, Utils)
    function WashModule.washInventoryItems()
        local washEvents = ReplicatedStorage:FindFirstChild("Events")
        if not washEvents then return end
        
        local washFolder = washEvents:FindFirstChild("Wash")
        if not washFolder then return end
        
        local getWashable = washFolder:FindFirstChild("GetWashableItems")
        local startWash = washFolder:FindFirstChild("StartWash")
        
        if getWashable and startWash then
            local success, data = pcall(function() return getWashable:InvokeServer() end)
            if success and type(data) == "table" and data.items then
                for _, item in pairs(data.items) do
                    local guid = item.guid
                    local isAllowed = false
                    
                    if Config.WashRarities.Unknown then
                        isAllowed = true
                    end
                    
                    if guid and isAllowed then
                        for slot = 1, 3 do
                            pcall(function() startWash:InvokeServer(slot, guid) end)
                            pcall(function() startWash:InvokeServer(guid, slot) end)
                        end
                        task.wait(0.05)
                    end
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
                        
                        if Config.AutoWash then
                            WashModule.washInventoryItems()
                        end
                        
                        if humanoid and humanoid.Sit then 
                            humanoid.Sit = false 
                        end
                        task.wait(0.5)
                        
                        if Config.AutoSell then
                            Utils.warpToMyPlot()
                            task.wait(1)
                        end
                    end
                end
            end
        end
    end
end

return WashModule