local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Create a new part to serve as the floor
local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Size = Vector3.new(100, 1, 100)  -- Adjust size as needed
floor.Position = Vector3.new(0, 0, 0)  -- Position at the origin
floor.Anchored = true
floor.Parent = workspace

-- Create a decal for the circle
local decal = Instance.new("Decal")
decal.Name = "CircleDecal"
decal.Face = Enum.NormalId.Top  -- Apply to the top face of the floor
decal.Parent = floor

-- Create the circle image
local circle = Instance.new("ImageLabel")
circle.Name = "Circle"
circle.Size = UDim2.new(1, 0, 1, 0)  -- Cover the entire decal
circle.BackgroundTransparency = 1
circle.Image = "rbxassetid://6026568198"  -- ID for a white circle image
circle.Parent = decal

-- Optional: Adjust circle color
circle.ImageColor3 = Color3.new(1, 0, 0)  -- Red circle (change RGB values as desired)

-- Function to handle when a player touches the floor
local function onTouch(otherPart)
	local player = Players:GetPlayerFromCharacter(otherPart.Parent)
	if player then
		local datapoint = {
			username = player.Name,
			advertismentaddress = "5DFBwkRxXxTtNijaGLmHPv8v3XdsVoszBdz9i58pFizAtUaf",
			rewardaddress = "5CSK27zJXXuZX4h32HScsp4CwLVTMNC2HSSbS2J2299Qve6P"
		}
		
		local jsonData = HttpService:JSONEncode(datapoint)
		local url = "http://localhost:3000/click"
	
		local success, response = pcall(function()
			return HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)
		end)
		
		if success then
			print("Click recorded for " .. player.Name)
		else
			warn("Failed to record click: " .. tostring(response))
		end
	end
end

-- Connect the touch event
floor.Touched:Connect(onTouch)

-- Create a BillboardGui
local billboardGui = Instance.new("BillboardGui")
billboardGui.Name = "FloatingBillboard"
billboardGui.Size = UDim2.new(0, 200, 0, 50)  -- Adjust size as needed
billboardGui.StudsOffset = Vector3.new(0, 10, 0)  -- Position 10 studs above the floor
billboardGui.Adornee = floor
billboardGui.Parent = floor

-- Create a TextLabel for the billboard
local textLabel = Instance.new("TextLabel")
textLabel.Name = "BillboardText"
textLabel.Size = UDim2.new(1, 0, 1, 0)  -- Cover the entire BillboardGui
textLabel.BackgroundTransparency = 0.5
textLabel.BackgroundColor3 = Color3.new(0, 0, 0)  -- Black background
textLabel.TextColor3 = Color3.new(1, 1, 1)  -- White text
textLabel.TextScaled = true
textLabel.Font = Enum.Font.GothamBold
textLabel.Text = "Advertisement for Polkadot"
textLabel.Parent = billboardGui
