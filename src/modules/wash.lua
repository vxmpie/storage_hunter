local WashModule = {}
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function WashModule.init(Config, Utils)
    function WashModule.washInventoryItems()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if not events then return end
        
        local wash = events:FindFirstChild("Wash")
        if not wash then return end
        
        local getWashable = wash:FindFirstChild("GetWashableItems")
        local startWash = wash:FindFirstChild("StartWash")
        
        if getWashable and startWash then
            local success, data = pcall(function()
                if getWashable:IsA("RemoteFunction") then
                    return getWashable:InvokeServer()
                elseif getWashable:IsA("RemoteEvent") then
                    getWashable:FireServer()
                end
            end)
            
            if success and type(data) == "table" and data.items then
                for _, item in pairs(data.items) do
                    local guid = item.guid
                    if guid and Config.WashRarities.Unknown then
                        pcall(function()
                            if startWash:IsA("RemoteFunction") then
                                for slot = 1, 3 do
                                    startWash:InvokeServer(slot, guid)
                                    startWash:InvokeServer(guid, slot)
                                end
                                startWash:InvokeServer(guid)
                            elseif startWash:IsA("RemoteEvent") then
                                for slot = 1, 3 do
                                    startWash:FireServer(slot, guid)
                                    startWash:FireServer(guid, slot)
                                end
                                startWash:FireServer(guid)
                            end
                        end)
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