local FarmModule = {}
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function FarmModule.init(Config, Utils, WashModule)
    function FarmModule.startAuctionAndCollect(zoneName)
        local debris = Workspace:FindFirstChild("_Debris")
        local garages = debris and debris:FindFirstChild("Garages")
        local carryables = Workspace:FindFirstChild("_Carryables")
        if not garages or not carryables then return end

        if Config.AutoUnload then
            local currentVehicle = Utils.getCurrentVehicle()
            if currentVehicle then
                local cargoWeight = currentVehicle:GetAttribute("CargoWeight") or 0
                local cargoLimit = currentVehicle:GetAttribute("CargoWeightLimit") or math.huge
                if cargoWeight >= (cargoLimit * 0.95) then
                    WashModule.warpToUnpack()
                    task.wait(1)
                end
            end
        end

        local targetPrompt, targetGarage = nil, nil
        local nw = Utils.getNetWorth()

        for _, g in pairs(garages:GetChildren()) do
            local sq = g:FindFirstChild("EntrySquare")
            if sq and sq:FindFirstChild("PromptPart") and sq.PromptPart:FindFirstChild("EnterAuction") then
                local prompt = sq.PromptPart.EnterAuction
                if zoneName == "Back Alley" then
                    if g.Name:match("Camo") and nw >= 10000 then targetPrompt = prompt; targetGarage = g; break end
                    if g.Name:match("Shop Front") then targetPrompt = prompt; targetGarage = g; end
                elseif zoneName == "Farmyard" then
                    if g.Name:match("Barn") and nw >= 50000 then targetPrompt = prompt; targetGarage = g; break end
                    if g.Name:match("Stable") then targetPrompt = prompt; targetGarage = g; end
                elseif zoneName == "Shipyard" then
                    if g.Name:match("Large") and nw >= 400000 then targetPrompt = prompt; targetGarage = g; break end
                    if g.Name:match("Small") then targetPrompt = prompt; targetGarage = g; end
                elseif zoneName == "Junk Yard" then
                    if g.Name:match("Scrap") or g.Name == "Garage" then targetPrompt = prompt; targetGarage = g; break end
                end
            end
        end

        if targetPrompt and targetGarage then
            local savedGarageCFrame = targetPrompt.Parent.CFrame
            Utils.warpTo(savedGarageCFrame)
            task.wait(0.5)
            if fireproximityprompt then fireproximityprompt(targetPrompt) end
            
            local pGui = LocalPlayer:FindFirstChild("PlayerGui")
            local uiController = pGui and pGui:FindFirstChild("UIControllerGui")
            local auctionUI = uiController and uiController:FindFirstChild("AuctionBiddingContainer")
            
            local uiWait = 0
            while auctionUI and not auctionUI.Visible and uiWait < 8 and Config.IsFarming do
                task.wait(0.5)
                uiWait = uiWait + 0.5
            end
            
            if auctionUI and auctionUI.Visible then
                local noneVisibleCount = 0
                while Config.IsFarming do
                    if auctionUI.Visible then 
                        noneVisibleCount = 0 
                    else 
                        noneVisibleCount = noneVisibleCount + 1 
                    end
                    if noneVisibleCount >= 3 then break end
                    task.wait(0.5)
                end
                task.wait(2)
            else
                task.wait(1)
                return
            end
            
            local garagePos = targetPrompt.Parent.Position
            local maxIdleChecks = 2 
            local idleChecks = 0
            
            while Config.IsFarming do
                if Config.AutoUnload then
                    local currentVehicle = Utils.getCurrentVehicle()
                    if currentVehicle then
                        local cargoWeight = currentVehicle:GetAttribute("CargoWeight") or 0
                        local cargoLimit = currentVehicle:GetAttribute("CargoWeightLimit") or math.huge
                        
                        if cargoWeight >= (cargoLimit * 0.95) then
                            WashModule.warpToUnpack()
                            task.wait(1)
                            if currentVehicle then 
                                currentVehicle:PivotTo(savedGarageCFrame) 
                            else 
                                Utils.warpTo(savedGarageCFrame) 
                            end
                            task.wait(0.5)
                        end
                    end
                end

                local itemsToCollect = {}
                for _, item in pairs(carryables:GetChildren()) do
                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local basePart = item:FindFirstChildWhichIsA("BasePart", true)
                    if prompt and prompt.Enabled and basePart then
                        local dist = (basePart.Position - garagePos).Magnitude
                        if dist <= 60 then
                            local weight = 0
                            local weightValue = item:FindFirstChild("Weight") or item:FindFirstChild("Mass")
                            if weightValue and (weightValue:IsA("NumberValue") or weightValue:IsA("IntValue")) then 
                                weight = weightValue.Value
                            else 
                                weight = tonumber(item:GetAttribute("Weight")) or tonumber(item:GetAttribute("Mass")) or 0 
                            end
                            table.insert(itemsToCollect, { prompt = prompt, basePart = basePart, weight = weight })
                        end
                    end
                end
                
                if #itemsToCollect > 0 then
                    idleChecks = 0
                    table.sort(itemsToCollect, function(a, b) return a.weight < b.weight end)
                    for _, data in ipairs(itemsToCollect) do
                        if not Config.IsFarming then break end
                        Utils.warpTo(data.basePart.CFrame)
                        task.wait(0.03) 
                        if fireproximityprompt then fireproximityprompt(data.prompt) end
                        task.wait(0.03) 
                    end
                else
                    idleChecks = idleChecks + 1
                    if idleChecks >= maxIdleChecks then break end
                    task.wait(0.1) 
                end
            end
        end
    end
end

return FarmModule