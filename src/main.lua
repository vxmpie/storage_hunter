local githubUser = "vxmpie"
local repoBase = "https://raw.githubusercontent.com/" .. githubUser .. "/storage_hunter/main/src/"

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local heartbeatConnection = nil

local function loadModule(fileName)
    local url = repoBase .. fileName .. "?t=" .. tostring(tick())
    local success, result = pcall(function() return game:HttpGet(url) end)
    if not success then return nil end
    local func, err = loadstring(result)
    if not func then return nil end
    return func()
end

local Config = loadModule("config.lua")
local Utils = loadModule("utils.lua")
local UI = loadModule("ui/tabs.lua")
local WashModule = loadModule("modules/wash.lua")
local FarmModule = loadModule("modules/farm.lua")

if not Config or not Utils or not UI or not WashModule or not FarmModule then
    warn("Genesis UI Execution Stopped due to module error.")
    return
end

WashModule.init(Config, Utils)
FarmModule.init(Config, Utils, WashModule)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GenesisUI_Pro"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
FloatingBtn.Position = UDim2.new(1, -70, 0.5, -25)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
FloatingBtn.TextColor3 = Color3.fromRGB(255, 60, 60)
FloatingBtn.Text = "G"
FloatingBtn.Font = Enum.Font.GothamBlack
FloatingBtn.TextSize = 30
FloatingBtn.Parent = ScreenGui
FloatingBtn.Draggable = true
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = Color3.fromRGB(255, 60, 60)
FloatStroke.Thickness = 2

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 580, 0, 440)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -220)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(35, 35, 40)
MainStroke.Thickness = 1

FloatingBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = not MainFrame.Visible 
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 10, 1, 0)
SidebarFix.Position = UDim2.new(1, -10, 0, 0)
SidebarFix.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 70)
Title.BackgroundTransparency = 1
Title.Text = "GENESIS"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 24
Title.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -160, 1, 0)
ContentArea.Position = UDim2.new(0, 160, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Tabs = {}
local Tab_Farming = UI.createTab(Sidebar, ContentArea, Tabs, "Farming", 0)
local Tab_Automation = UI.createTab(Sidebar, ContentArea, Tabs, "Automation", 1)
local Tab_Teleports = UI.createTab(Sidebar, ContentArea, Tabs, "Teleports", 2)
local Tab_Misc = UI.createTab(Sidebar, ContentArea, Tabs, "Misc", 3)
Tabs[1].scroll.Visible = true 
Tabs[1].btn.TextColor3 = Color3.fromRGB(255, 60, 60)
Tabs[1].btn.BackgroundColor3 = Color3.fromRGB(35, 25, 30)
Tabs[1].stroke.Color = Color3.fromRGB(255, 60, 60)

UI.createHeader(Tab_Farming, "Farm Config")
UI.createToggle(Tab_Farming, "Auto Bid (Bypass Minigame)", false, function(s) Config.AutoBid = s end)
UI.createToggle(Tab_Farming, "Auto Unload To Unpack Zone", false, function(s) Config.AutoUnload = s end)

UI.createInput(Tab_Farming, "Farm Loops (0 = Infinite)", "e.g. 5", function(val)
    local num = tonumber(val)
    if num then Config.FarmLoops = num else Config.FarmLoops = 0 end
end)

UI.createHeader(Tab_Farming, "Target Location")
local farmOptions = {"Junk Yard", "Back Alley", "Farm Yard", "Ship Yard"}
local farmButtons = {}
for _, place in ipairs(farmOptions) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = Tab_Farming

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 20, 0, 20)
    box.Position = UDim2.new(0, 5, 0.5, -10)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    box.Text = ""
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(1, 0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -35, 1, 0)
    lbl.Position = UDim2.new(0, 35, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = place
    lbl.TextColor3 = Color3.fromRGB(200, 200, 205)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    table.insert(farmButtons, {box = box, name = place})

    box.MouseButton1Click:Connect(function()
        for _, b in ipairs(farmButtons) do 
            b.box.BackgroundColor3 = Color3.fromRGB(45, 45, 55) 
        end
        box.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        Config.SelectedFarm = place == "Farm Yard" and "Farmyard" or (place == "Ship Yard" and "Shipyard" or place)
    end)
end

Instance.new("Frame", Tab_Farming).Size = UDim2.new(1, 0, 0, 10).BackgroundTransparency = 1

local StartFarmBtn = UI.createActionButton(Tab_Farming, "START AUTO FARM", Color3.fromRGB(40, 160, 80), function() end)
StartFarmBtn.MouseButton1Click:Connect(function()
    if Config.SelectedFarm == "" then return end
    Config.IsFarming = not Config.IsFarming
    if Config.IsFarming then
        StartFarmBtn.Text = "STOP AUTO FARM"
        StartFarmBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.spawn(function()
            local loopCount = 0
            while Config.IsFarming do
                if Config.FarmLoops > 0 and loopCount >= Config.FarmLoops then
                    Config.IsFarming = false
                    StartFarmBtn.Text = "START AUTO FARM"
                    StartFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
                    break
                end
                loopCount = loopCount + 1
                FarmModule.startAuctionAndCollect(Config.SelectedFarm)
                task.wait(1)
            end
        end)
    else
        StartFarmBtn.Text = "START AUTO FARM"
        StartFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    end
end)

UI.createHeader(Tab_Automation, "Active Workflows")
UI.createToggle(Tab_Automation, "Continuous Auto Wash", false, function(s) Config.AutoWash = s end)
UI.createToggle(Tab_Automation, "Auto Restock Display", false, function(s) Config.AutoSell = s end)

UI.createHeader(Tab_Automation, "Wash Rarity Filters")
UI.createToggle(Tab_Automation, "Wash Junk", false, function(s) Config.WashRarities.Junk = s end)
UI.createToggle(Tab_Automation, "Wash Uncommon", false, function(s) Config.WashRarities.Uncommon = s end)
UI.createToggle(Tab_Automation, "Wash Rare", false, function(s) Config.WashRarities.Rare = s end)
UI.createToggle(Tab_Automation, "Wash Epic", false, function(s) Config.WashRarities.Epic = s end)
UI.createToggle(Tab_Automation, "Wash Legendary", false, function(s) Config.WashRarities.Legendary = s end)
UI.createToggle(Tab_Automation, "Wash Mythical", false, function(s) Config.WashRarities.Mythical = s end)
UI.createToggle(Tab_Automation, "Wash Unknown", false, function(s) Config.WashRarities.Unknown = s end)

UI.createHeader(Tab_Teleports, "Locations")
UI.createActionButton(Tab_Teleports, "Warp to My Plot", Color3.fromRGB(30, 100, 180), Utils.warpToMyPlot)
UI.createActionButton(Tab_Teleports, "Warp to Unpack Zone", Color3.fromRGB(180, 100, 30), WashModule.warpToUnpack)

local function warpToArea(areaName)
    local targetArea = Workspace.Areas:FindFirstChild(areaName)
    if targetArea and targetArea:FindFirstChild("AreaBoundary") then 
        Utils.warpTo(targetArea.AreaBoundary.CFrame) 
    end
end

UI.createActionButton(Tab_Teleports, "Warp to Junk Yard", Color3.fromRGB(45, 45, 55), function() warpToArea("Junk Yard") end)
UI.createActionButton(Tab_Teleports, "Warp to Back Alley", Color3.fromRGB(45, 45, 55), function() warpToArea("Back Alley") end)
UI.createActionButton(Tab_Teleports, "Warp to Farm Yard", Color3.fromRGB(45, 45, 55), function() warpToArea("Farmyard") end)
UI.createActionButton(Tab_Teleports, "Warp to Ship Yard", Color3.fromRGB(45, 45, 55), function() warpToArea("Shipyard") end)
UI.createActionButton(Tab_Teleports, "Warp to Shopping Mall", Color3.fromRGB(45, 45, 55), function() warpToArea("Shopping Mall") end)

UI.createHeader(Tab_Misc, "Utilities")
UI.createActionButton(Tab_Misc, "Spawn: Flatbed (2500 Kg)", Color3.fromRGB(45, 45, 55), function()
    local sp = Workspace:FindFirstChild("_VehicleShop") and Workspace._VehicleShop.VehicleSpawns:FindFirstChild("Spawn2")
    if sp and sp:FindFirstChild("Flatbed") then
        local ds = sp.Flatbed:FindFirstChild("DriveSeat")
        if ds and ds.PromptLocation then
            Utils.warpTo(ds.CFrame)
            task.wait(0.5)
            fireproximityprompt(ds.PromptLocation.VehiclePrompt)
        end
    end
end)

Instance.new("Frame", Tab_Misc).Size = UDim2.new(1, 0, 0, 10).BackgroundTransparency = 1

UI.createActionButton(Tab_Misc, "UNLOAD SCRIPT", Color3.fromRGB(150, 40, 40), function()
    Config.IsFarming = false
    Config.AutoBid = false
    Config.AutoUnload = false
    Config.AutoWash = false
    Config.AutoSell = false
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    if ScreenGui then
        ScreenGui:Destroy()
    end
end)

heartbeatConnection = RunService.Heartbeat:Connect(function()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui and pGui:FindFirstChild("UIControllerGui") then
        if Config.AutoBid and pGui.UIControllerGui:FindFirstChild("AuctionBiddingContainer") and pGui.UIControllerGui.AuctionBiddingContainer.Visible then
            local ev = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Auction")
            if ev and ev:FindFirstChild("Bid") then ev.Bid:FireServer() end
        end
        local outer = pGui.UIControllerGui:FindFirstChild("NewDiscoveryOuter")
        if outer and outer.Visible then
            local popup = outer:FindFirstChild("DiscoveryPopup")
            local btn = popup and popup:FindFirstChild("RepairContinueButton")
            if btn and btn.AbsolutePosition then
                outer.Visible = false
                pcall(function()
                    local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
                    local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) + 56
                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                end)
            end
        end
    end
end)