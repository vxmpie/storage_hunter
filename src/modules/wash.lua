local WashModule = {}
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function WashModule.init(Config, Utils)
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
							print("📦 Unload ของเสร็จสิ้น!")
							task.wait(0.5)
							
							if Config.AutoWash then
								local washEvents = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Wash")
								if washEvents then
									local getWashable = washEvents:FindFirstChild("GetWashableItems")
									local startWash = washEvents:FindFirstChild("StartWash")
									
									if getWashable and startWash then
										local successW, dirtyItems = pcall(function() return getWashable:InvokeServer() end)
										if successW and type(dirtyItems) == "table" then
											local washCount = 0
											for k, v in pairs(dirtyItems) do
												local guid = (type(v) == "table" and (v.guid or v.Id)) or (type(k) == "string" and #k > 10 and k) or v
												local rarity = type(v) == "table" and (v.Rarity or v.rarity) or "Unknown"
												
												local isAllowed = false
												if type(rarity) == "string" then
													for rName, state in pairs(Config.WashRarities) do
														if state and string.match(string.lower(rarity), string.lower(rName)) then
															isAllowed = true; break
													    end
												    end
												end
												if Config.WashRarities.Unknown and rarity == "Unknown" then isAllowed = true end
												
												if guid and isAllowed then
													pcall(function() 
														for slot = 1, 3 do startWash:InvokeServer(slot, guid) end
													end)
													washCount = washCount + 1
													task.wait(0.05)
												end
											end
											print("💦 ส่งไอเทมไปทำความสะอาดจำนวน " .. washCount .. " ชิ้น")
										end
									end
								end
							end
							
							if humanoid and humanoid.Sit then humanoid.Sit = false end
							task.wait(0.5)
							
							if Config.AutoSell then
								print("🏪 กำลังวาร์ปไปที่ Plot เพื่อจัดเรียงของขึ้นโต๊ะขาย...")
								Utils.warpToMyPlot()
								task.wait(1)
								
								local myPlot = Utils.findMyPlot()
								if myPlot and myPlot:FindFirstChild("Furniture") then
									local availableSnaps = {}
									for _, obj in pairs(myPlot.Furniture:GetDescendants()) do
										if obj.Name:match("SnapPoint") and obj:FindFirstChild("ShelfAddItemPrompt") then
											table.insert(availableSnaps, obj)
										end
									end
									print("🔍 พบจุดวางของ (SnapPoint) ว่างในร้าน: " .. #availableSnaps .. " จุด")
								end
							end
						end
					end
				end
			end
		end
	end
end

return WashModule