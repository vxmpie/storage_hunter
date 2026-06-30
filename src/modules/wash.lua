local WashModule = {}
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

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
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            if absSize.X > 0 and absSize.Y > 0 then
                local inset = GuiService:GetGuiInset()
                local x = absPos.X + (absSize.X / 2)
                local y = absPos.Y + (absSize.Y / 2) + inset.Y
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            end
        end)
    end

    local function autoClaimUI()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local uiC = pGui and pGui:FindFirstChild("UIControllerGui")
        if not uiC then return false end

        local isBusy = false
        local washShop = uiC:FindFirstChild("WashShopPanel")
        
        if washShop and washShop:FindFirstChild("SlotsContainer") then
            local wasVisible = washShop.Visible
            washShop.Visible = true 
            
            for i = 1, 3 do
                local slot = washShop.SlotsContainer:FindFirstChild("Slot" .. tostring(i))
                if slot and slot:FindFirstChild("Content") then
                    local content = slot.Content
                    local colBtn = content:FindFirstChild("CollectBtn")
                    local clmBtn = content:FindFirstChild("ClaimBtn")
                    local spdBtn = content:FindFirstChild("SpeedUpBtn")
                    local timer = content:FindFirstChild("TimerText")
                    
                    if spdBtn and spdBtn.Visible then
                        isBusy = true
                    end
                    if timer and timer.Visible and timer.Text ~= "" and timer.Text ~= "0s" and timer.Text ~= "00:00" then
                        isBusy = true
                    end
                    
                    if colBtn then clickUI(colBtn) end
                    task.wait(0.05)
                    if clmBtn then clickUI(clmBtn) end
                end
            end
            
            washShop.Visible = wasVisible
        end

        local washReveal = uiC:FindFirstChild("WashReveal")
        if washReveal and washReveal:FindFirstChild("Content") then
            local wasRevVisible = washReveal.Visible
            washReveal.Visible = true
            
            local clmBtn = washReveal.Content:FindFirstChild("ClaimBtn")
            if clmBtn then clickUI(clmBtn) end
            
            washReveal.Visible = wasRevVisible
        end
        
        return isBusy
    end

    function WashModule.washInventoryItems()
        warn("WASH_EXECUTE_START")
        local events = ReplicatedStorage:FindFirstChild("Events")
        local wash = events and events:FindFirstChild("Wash")
        if not wash then return end
        
        local getWashable = wash:FindFirstChild("GetWashableItems")
        local startWash = wash:FindFirstChild("StartWash")
        
        if getWashable and startWash then
            local success, data = pcall(function()
                if getWashable:IsA("RemoteFunction") then return getWashable:InvokeServer()
                elseif getWashable:IsA("RemoteEvent") then getWashable:FireServer() end
            end)
            
            if success and type(data) == "table" and data.items then
                local itemsToWash = {}
                
                for _, item in pairs(data.items) do
                    if item.guid then
                        table.insert(itemsToWash, item.guid)
                    end
                end
                
                if #itemsToWash > 0 then
                    warn("WASH_ITEMS_FOUND_" .. tostring(#itemsToWash))
                    local originalCFrame = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local originalPos = originalCFrame and originalCFrame.CFrame
                    local washCFrame = getWashStationCFrame()
                    
                    if washCFrame then 
                        Utils.warpTo(washCFrame) 
                        task.wait(1) 
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
                        
                        task.wait(1.5) 
                        
                        local speedUpWash = wash:FindFirstChild("SpeedUpWash")
                        local collectWash = wash:FindFirstChild("CollectWash")
                        local claimWashedItem = wash:FindFirstChild("ClaimWashedItem")
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
                        
                        local maxWait = 240
                        local currentWait = 0
                        while currentWait < maxWait do
                            task.wait(1)
                            local stillWashing = autoClaimUI()
                            if not stillWashing then break end
                            currentWait = currentWait + 1
                        end
                        
                        warn("WASH_SWEEP_START")
                        for finalSweep = 1, 8 do
                            task.wait(0.5)
                            autoClaimUI()
                        end
                    end
                    
                    if originalPos then 
                        task.wait(1) 
                        Utils.warpTo(originalPos) 
                    end
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