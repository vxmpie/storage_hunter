local UI = {}

function UI.createTab(Sidebar, ContentArea, Tabs, name, order)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -20)
	scroll.Position = UDim2.new(0, 10, 0, 10)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.Visible = false
	scroll.Parent = ContentArea

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, 60 + (order * 45))
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.Text = name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Parent = Sidebar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(function()
		for _, t in pairs(Tabs) do 
			t.scroll.Visible = false 
			t.btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			t.btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		end
		scroll.Visible = true
		btn.TextColor3 = Color3.fromRGB(255, 50, 50)
		btn.BackgroundColor3 = Color3.fromRGB(40, 30, 35)
	end)

	table.insert(Tabs, {scroll = scroll, btn = btn})
	return scroll
end

function UI.createHeader(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 30)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 16
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
end

function UI.createToggle(parent, text, defaultState, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 35)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local box = Instance.new("TextButton")
	box.Size = UDim2.new(0, 24, 0, 24)
	box.Position = UDim2.new(0, 0, 0.5, -12)
	box.BackgroundColor3 = defaultState and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 50)
	box.Text = ""
	box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -35, 1, 0)
	lbl.Position = UDim2.new(0, 35, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.Font = Enum.Font.GothamSemibold
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame

	local state = defaultState
	box.MouseButton1Click:Connect(function()
		state = not state
		box.BackgroundColor3 = state and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 50)
		callback(state)
	end)
end

function UI.createActionButton(parent, text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 55)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Parent = parent
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

return UI