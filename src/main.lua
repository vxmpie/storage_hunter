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
	
	if not success then 
		warn("[Network Error] " .. fileName) 
		return nil 
	end
	
	local func, err = loadstring(result)
	if not func then 
		warn("[Syntax Error] " .. fileName .. " | Error: " .. tostring(err)) 
		return nil 
	end
	
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
FloatingBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
FloatingBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
FloatingBtn.Text = "G"
FloatingBtn.Font = Enum.Font.GothamBlack
FloatingBtn.TextSize = 30
FloatingBtn.Parent = ScreenGui
FloatingBtn.Draggable = true
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = Color3.fromRGB(255, 50, 50)
FloatStroke.Thickness = 2

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 550, 0, 420)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(50, 50, 60)
MainStroke.Thickness = 2

FloatingBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 10, 1, 0)
SidebarFix.Position = UDim2.new(1, -10, 0, 0)
SidebarFix.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
SidebarFix.BorderSizePixel = 0
SidebarFix.Parent = Sidebar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.BackgroundTransparency = 1
Title.Text = "GENESIS"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -150, 1, 0)
ContentArea.Position = UDim2.new(0, 150, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local Tabs = {}
local Tab_AutoFarm = UI.createTab(Sidebar, ContentArea, Tabs, "Auto Farm", 0)
local Tab_Store = UI.createTab(Sidebar, ContentArea, Tabs, "Wash & Sell", 1)
local Tab_Teleports = UI.createTab(Sidebar, ContentArea, Tabs, "Teleports", 2)
local Tab_Vehicles = UI.createTab(Sidebar, ContentArea, Tabs, "Vehicles", 3)
Tabs[1].scroll.Visible = true
Tabs[1].btn.TextColor3 = Color3.fromRGB(255, 50, 50)

UI.createHeader(Tab_AutoFarm, "Settings")
UI.createToggle(Tab_AutoFarm, "Auto Bid (Bypass Minigame)", false, function(s) Config.AutoBid = s end)
UI.createToggle(Tab_AutoFarm, "Auto Unload when full", false, function(s) Config.AutoUnload = s end)
UI.createHeader(Tab_AutoFarm, "Select Place to Farm")

local farmOptions = {"Junk Yard", "Back Alley", "Farm Yard", "Ship Yard"}
local farmButtons = {}
for _, place in ipairs(farmOptions) do
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 30); frame.BackgroundTransparency = 1; frame.Parent = Tab_AutoFarm
	local box = Instance.new("TextButton")
	box.Size = UDim2.new(0, 20, 0, 20); box.Position = UDim2.new(0, 0, 0.5, -10); box.BackgroundColor3 = Color3.fromRGB(40, 40, 50); box.Text = ""; box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(1, 0)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -30, 1, 0); lbl.Position = UDim2.new(0, 30, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = place; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = frame
	table.insert(farmButtons, {box = box, name = place})
	box.MouseButton1Click:Connect(function()
		for _, b in ipairs(farmButtons) do b.box.BackgroundColor3 = Color3.fromRGB(40, 40, 50) end
		box.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		Config.SelectedFarm = place == "Farm Yard" and "Farmyard" or (place == "Ship Yard" and "Shipyard" or place)
	end)
end

Instance.new("Frame", Tab_AutoFarm).Size = UDim2.new(1, 0, 0, 10)
local StartFarmBtn = UI.createActionButton(Tab_AutoFarm, "START AUTO FARM", Color3.fromRGB(30, 150, 70), function() end)
StartFarmBtn.MouseButton1Click:Connect(function()
	if Config.SelectedFarm == "" then return warn("Select farm location first") end
	Config.IsFarming = not Config.IsFarming
	if Config.IsFarming then
		StartFarmBtn.Text = "STOP AUTO FARM"
		StartFarmBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		task.spawn(function()
			while Config.IsFarming do
				FarmModule.startAuctionAndCollect(Config.SelectedFarm)
				task.wait(1)
			end
		end)
	else
		StartFarmBtn.Text = "START AUTO FARM"
		StartFarmBtn.BackgroundColor3 = Color3.fromRGB(30, 150, 70)
	end
end)

local UnloadScriptBtn = UI.createActionButton(Tab_AutoFarm, "UNLOAD SCRIPT", Color3.fromRGB(150, 35, 35), function()
	Config.IsFarming = false
	Config.AutoBid = false
	Config.AutoUnload = false
	Config.AutoWash = false
	Config.AutoSell = false
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		print("Disconnected Heartbeat Connection")
	end
	if ScreenGui then
		ScreenGui:Destroy()
		print("Genesis UI Destroyed Successfully")
	end
end)

UI.createHeader(Tab_Store, "Auto Shop Workflow")
UI.createToggle(Tab_Store, "Enable Auto Wash (หลัง Unload)", false, function(s) Config.AutoWash = s end)
UI.createToggle(Tab_Store, "Enable Auto Sell (วางโชว์ขาย)", false, function(s) Config.AutoSell = s end)

UI.createActionButton(Tab_Store, "WASH INVENTORY NOW", Color3.fromRGB(0, 120, 180), function()
	WashModule.washInventoryItems()
end)

UI.createHeader(Tab_Store, "Wash Rarity Filter")
UI.createToggle(Tab_Store, "Wash Junk", false, function(s) Config.WashRarities.Junk = s end)
UI.createToggle(Tab_Store, "Wash Uncommon", false, function(s) Config.WashRarities.Uncommon = s end)
UI.createToggle(Tab_Store, "Wash Rare", false, function(s) Config.WashRarities.Rare = s end)
UI.createToggle(Tab_Store, "Wash Epic", false, function(s) Config.WashRarities.Epic = s end)
UI.createToggle(Tab_Store, "Wash Legendary", false, function(s) Config.WashRarities.Legendary = s end)
UI.createToggle(Tab_Store, "Wash Mythical", false, function(s) Config.WashRarities.Mythical = s end)
UI.createToggle(Tab_Store, "Wash Unknown", false, function(s) Config.WashRarities.Unknown = s end)

UI.createActionButton(Tab_Teleports, "Warp to My Plot", Color3.fromRGB(0, 120, 200), Utils.warpToMyPlot)
UI.createActionButton(Tab_Teleports, "Warp to Unpack Zone", Color3.fromRGB(200, 120, 0), WashModule.warpToUnpack)

local function warpToArea(areaName)
	local targetArea = Workspace.Areas:FindFirstChild(areaName)
	if targetArea and targetArea:FindFirstChild("AreaBoundary") then
		Utils.warpTo(targetArea.AreaBoundary.CFrame)
	end
end

UI.createActionButton(Tab_Teleports, "Warp to Junk Yard", nil, function() warpToArea("Junk Yard") end)
UI.createActionButton(Tab_Teleports, "Warp to Back Alley", nil, function() warpToArea("Back Alley") end)
UI.createActionButton(Tab_Teleports, "Warp to Farm Yard", nil, function() warpToArea("Farmyard") end)
UI.createActionButton(Tab_Teleports, "Warp to Ship Yard", nil, function() warpToArea("Shipyard") end)
UI.createActionButton(Tab_Teleports, "Warp to Shopping Mall", nil, function() warpToArea("Shopping Mall") end)

UI.createActionButton(Tab_Vehicles, "Spawn: Flatbed (2500 Kg)", nil, function()
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

heartbeatConnection = RunService.Heartbeat:Connect(function()
	local pGui = LocalPlayer:FindFirstChild("PlayerGui")
	if pGui and pGui:FindFirstChild("UIControllerGui") then
		if Config.AutoBid and pGui.UIControllerGui:FindFirstChild("AuctionBiddingContainer") and pGui.UIControllerGui.AuctionBiddingContainer.Visible then
			local ev = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Auction")
			if ev and ev:FindFirstChild("Bid") then
				ev.Bid:FireServer()
			end
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