local WashModule = {}
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

function WashModule.init(Config, Utils)
	function WashModule.washInventoryItems()
		local washEvents = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Wash")
		if not washEvents then return end
		
		local getWashable = washEvents:FindFirstChild("GetWashableItems")
		
		if getWashable then
			local successW, dirtyItems = pcall(function() return getWashable:InvokeServer() end)
			if successW and type(dirtyItems) == "table" then
				for k, v in pairs(dirtyItems) do
					if type(v) == "table" then
						local successJson, jsonString = pcall(function()
							return HttpService:JSONEncode(v)
						end)
						if successJson then
							print("DATA_DUMP_KEY_" .. tostring(k) .. ": " .. jsonString)
						else
							for subK, subV in pairs(v) do
								print("SUB_DATA: " .. tostring(subK) .. " = " .. tostring(subV))
							end
						end
					else
						print("RAW_DATA: " .. tostring(k) .. " = " .. tostring(v))
					end
				end
			end
		end
	end

	function WashModule.warpToUnpack()
		local uz = Workspace:FindFirstChild("UnpackZone")
		if not uz or not uz:FindFirstChild("Pad") then return end

		local targetCFrame = uz.Pad.CFrame + Vector3.new(0, 4, 0)
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChild("Humanoid")

		if humanoid and humanoid.SeatPart then
			local vehicle = humanoid.SeatPart:FindFirstAncestorWhichIsA("Model")
			if vehicle then vehicle:PivotTo(targetCFrame) else humanoid.SeatPart.CFrame = targetCFrame end
		else
			Utils.warpTo(uz.Pad.CFrame)
		end
		
		task.wait(1)
		
		local vehiclesEvents = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Vehicles")
		if vehiclesEvents then
			local getOwnedVehicles = vehiclesEvents:FindFirstChild("GetOwnedVehicles")
			local getVehicleItems = vehiclesEvents:FindFirstChild("GetVehicleItems")
			local transferItems = vehiclesEvents:FindFirstChild("TransferVehicleItemsToInventory")
			
			if getOwnedVehicles and getVehicleItems and transferItems then
				local successV, resultV = pcall(function() return getOwnedVehicles:InvokeServer() end)
				if successV and type(resultV) == "table" and resultV.equippedGuid then
					local vehicleId = tostring(resultV.equippedGuid)
					local successI, resultI = pcall(function() return getVehicleItems:InvokeServer(vehicleId) end)
					
					if successI and type(resultI) == "table" then
						local itemsToUnload = {}
						for itemGuid, _ in pairs(resultI) do table.insert(itemsToUnload, itemGuid) end
						
						if #itemsToUnload > 0 then
							transferItems:FireServer(itemsToUnload)
							task.wait(0.5)
							
							if Config.AutoWash then
								WashModule.washInventoryItems()
							end
							
							if humanoid and humanoid.Sit then humanoid.Sit = false end
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
end

return WashModule