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
        if not btn then return end
        pcall(function()
            if type(firesignal) == "function" then
                pcall(function() firesignal(btn.MouseButton1Click) end)
            end
            
            if type(getconnections) == "function" then
                local conns = getconnections(btn.MouseButton1Click)
                if type(conns) == "table" then
                    for _, conn in pairs(conns) do
                        if type(conn) == "table" then
                            if type(conn.Fire) == "function" then
                                pcall(function() conn:Fire() end)
                            elseif type(conn.Function) == "function" then
                                pcall(function() conn.Function() end)
                            end
                        end
                    end
                end
            end
        end)
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

    local function autoClaimUI()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local uiC = pGui and pGui:FindFirstChild("UIControllerGui")
        if not uiC then return end

        local washShop = uiC:FindFirstChild("WashShopPanel")
        if washShop and washShop.Visible and washShop:FindFirstChild("SlotsContainer") then
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
        if washReveal and washReveal.Visible and washReveal:FindFirstChild("Content") then
            clickUI(washReveal.Content:FindFirstChild("ClaimBtn"))
        end
    end

    local function getRarity(itemId)
        if not itemDB then return "Unknown" end
        local info = itemDB[itemId] or itemDB[tonumber(itemId)] or itemDB[tostring(itemId)]
        if type(info) == "table" then
            return tostring(info.Rarity or info.rarity or info.Tier or info.tier or "Unknown")
        end
        
        for _, v in pairs(itemDB) do
            if type(v) == "table" then
                local id = v.id or v.Id or v.ID or v.ItemId or v.itemId or v.Name
                if tostring(id) == tostring(itemId) then
                    return tostring(v.Rarity or v.rarity or v.Tier or v.tier or "Unknown")
                end
            end
        end
        return "Unknown"
    end

    function WashModule.washInventoryItems()
        warn("[WASH_DIAGNOSTIC] ตรวจสอบกระเป๋าค้นหาไอเทม...")
        local events = ReplicatedStorage:FindFirstChild("Events")
        local wash = events and events:FindFirstChild("Wash")
        if not wash then return end
        
        local getWashable = wash:FindFirstChild("GetWashableItems")
        local startWash = wash:FindFirstChild("StartWash")
        local speedUpWash = wash:FindFirstChild("SpeedUpWash")
        local collectWash = wash:FindFirstChild("CollectWash")
        local claimWashedItem = wash:FindFirstChild("ClaimWashedItem")
        
        if getWashable and startWash then
            local success, data = pcall(function()
                if getWashable:IsA("RemoteFunction") then return getWashable:InvokeServer()
                elseif getWashable:IsA("RemoteEvent") then getWashable:FireServer() end
            end)
            
            if success and type(data) == "table" and data.items then
                local itemsToWash = {}
                
                for _, item in pairs(data.items) do
                    local guid = item.guid
                    local itemId = item.ItemId or item.itemId or item.id
                    local rarity = getRarity(itemId)
                    
                    warn("[WASH_DIAGNOSTIC] ตรวจพบไอเทม ID: " .. tostring(itemId) .. " | Rarity ที่ค้นเจอ: " .. rarity)
                    
                    local isAllowed = false
                    local rLower = string.lower(rarity)
                    
                    for rName, state in pairs(Config.WashRarities) do
                        if state and string.find(rLower, string.lower(rName)) then
                            isAllowed = true; break
                        end
                    end
                    if Config.WashRarities.Unknown and not isAllowed and (rarity == "Unknown" or rarity == "nil") then
                        isAllowed = true
                    end
                    if guid and isAllowed then table.insert(itemsToWash, guid) end
                end
                
                if #itemsToWash > 0 then
                    local originalCFrame = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
                    local washCFrame = getWashStationCFrame()
                    
                    if washCFrame then Utils.warpTo(washCFrame) task.wait(0.5) end
                    
                    for _, guid in ipairs(itemsToWash) do
                        pcall(function()
                            if startWash:IsA("RemoteFunction") then
                                for slot = 1, 3 do startWash:InvokeServer(slot, guid) startWash:InvokeServer(guid, slot) end
                                startWash:InvokeServer(guid)
                            elseif startWash:IsA("RemoteEvent") then
                                for slot = 1, 3 do startWash:FireServer(slot, guid) startWash:FireServer(guid, slot) end
                                startWash:FireServer(guid)
                            end
                        end)
                        
                        task.wait(1.5) 
                        
                        local postWashRemotes = {speedUpWash, collectWash, claimWashedItem}
                        for _, rem in ipairs(postWashRemotes) do
                            if rem then
                                pcall(function()
                                    for slot = 1, 3 do
                                        if rem:IsA("RemoteFunction") then pcall(function() rem:InvokeServer(slot, guid) end) pcall(function() rem:InvokeServer(guid, slot) end) pcall(function() rem:InvokeServer(slot) end) pcall(function() rem:InvokeServer(guid) end)
                                        elseif rem:IsA("RemoteEvent") then pcall(function() rem:FireServer(slot, guid) end) pcall(function() rem:FireServer(guid, slot) end) pcall(function() rem:FireServer(slot) end) pcall(function() rem:FireServer(guid) end) end
                                    end
                                end)
                            end
                        end
                        
                        for waitLoop = 1, 8 do
                            task.wait(0.5)
                            autoClaimUI()
                        end
                    end
                    
                    if originalCFrame then task.wait(0.5) Utils.warpTo(originalCFrame) end
                    warn("[WASH_DIAGNOSTIC] ซักและเก็บของเสร็จสิ้น (เข้ากระเป๋าแน่นอน)")
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