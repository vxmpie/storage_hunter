local WashModule = {}
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local itemDB
pcall(function()
    itemDB = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Items"))
end)

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

    local function clickUI(btn)
        if btn then
            pcall(function()
                if getconnections then
                    for _, conn in ipairs(getconnections(btn.MouseButton1Click) or {}) do
                        conn:Fire()
                    end
                    for _, conn in ipairs(getconnections(btn.MouseButton1Down) or {}) do
                        conn:Fire()
                    end
                end
            end)
        end
    end

    local function autoClaimUI()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local uiC = pGui and pGui:FindFirstChild("UIControllerGui")
        if not uiC then return end

        local washShop = uiC:FindFirstChild("WashShopPanel")
        if washShop and washShop:FindFirstChild("SlotsContainer") then
            for i = 1, 3 do
                local slot = washShop.SlotsContainer:FindFirstChild("Slot" .. tostring(i))
                if slot and slot:FindFirstChild("Content") then
                    clickUI(slot.Content:FindFirstChild("CollectBtn"))
                    task.wait(0.1)
                    clickUI(slot.Content:FindFirstChild("ClaimBtn"))
                end
            end
        end

        local washReveal = uiC:FindFirstChild("WashReveal")
        if washReveal and washReveal:FindFirstChild("Content") then
            clickUI(washReveal.Content:FindFirstChild("ClaimBtn"))
        end
    end

    function WashModule.washInventoryItems()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if not events then return end
        
        local wash = events:FindFirstChild("Wash")
        if not wash then return end
        
        local getWashable = wash:FindFirstChild("GetWashableItems")
        local startWash = wash:FindFirstChild("StartWash")
        local speedUpWash = wash:FindFirstChild("SpeedUpWash")
        local collectWash = wash:FindFirstChild("CollectWash")
        local claimWashedItem = wash:FindFirstChild("ClaimWashedItem")
        
        if getWashable and startWash then
            local success, data = pcall(function()
                if getWashable:IsA("RemoteFunction") then
                    return getWashable:InvokeServer()
                elseif getWashable:IsA("RemoteEvent") then
                    getWashable:FireServer()
                end
            end)
            
            if success and type(data) == "table" and data.items then
                local itemsToWash = {}
                
                for _, item in pairs(data.items) do
                    local guid = item.guid
                    local itemId = item.ItemId or item.itemId or item.id
                    local rarity = "Unknown"
                    
                    if itemDB and itemId then
                        local successDB, itemInfo = pcall(function() return itemDB[itemId] end)
                        if successDB and type(itemInfo) == "table" then
                            rarity = itemInfo.Rarity or itemInfo.rarity or itemInfo.Tier or itemInfo.tier or "Unknown"
                        end
                    end
                    
                    local isAllowed = false
                    if type(rarity) == "string" then
                        for rName, state in pairs(Config.WashRarities) do
                            if state and string.match(string.lower(rarity), string.lower(rName)) then
                                isAllowed = true
                                break
                            end
                        end
                    end
                    
                    if Config.WashRarities.Unknown and not isAllowed and rarity == "Unknown" then
                        isAllowed = true
                    end
                    
                    if guid and isAllowed then
                        table.insert(itemsToWash, guid)
                    end
                end
                
                if #itemsToWash > 0 then
                    local originalCFrame
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        originalCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    end

                    local washCFrame = getWashStationCFrame()
                    if washCFrame then
                        Utils.warpTo(washCFrame)
                        task.wait(0.5)
                    end
                    
                    for _, guid in ipairs(itemsToWash) do
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
                        
                        task.wait(0.2)
                        
                        local postWashRemotes = {speedUpWash, collectWash, claimWashedItem}
                        for _, rem in ipairs(postWashRemotes) do
                            if rem then
                                pcall(function()
                                    for slot = 1, 3 do
                                        if rem:IsA("RemoteFunction") then
                                            pcall(function() rem:InvokeServer(slot, guid) end)
                                            pcall(function() rem:InvokeServer(guid, slot) end)
                                            pcall(function() rem:InvokeServer(slot) end)
                                            pcall(function() rem:InvokeServer(guid) end)
                                        elseif rem:IsA("RemoteEvent") then
                                            pcall(function() rem:FireServer(slot, guid) end)
                                            pcall(function() rem:FireServer(guid, slot) end)
                                            pcall(function() rem:FireServer(slot) end)
                                            pcall(function() rem:FireServer(guid) end)
                                        end
                                    end
                                end)
                            end
                        end
                        
                        task.wait(0.2)
                        autoClaimUI()
                    end
                    
                    if originalCFrame then
                        task.wait(0.5)
                        Utils.warpTo(originalCFrame)
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
                        
                        if humanoid and humanoid.Sit then 
                            humanoid.Sit = false 
                        end
                        task.wait(0.5)
                        
                        if Config.AutoWash then
                            WashModule.washInventoryItems()
                        end
                        
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