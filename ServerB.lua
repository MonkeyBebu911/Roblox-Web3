local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Function to track player time
local function trackPlayerTime(player)
	local joinTime = os.time()

	while player.Parent do
		local timeSpent = os.time() - joinTime

		if timeSpent >= 300 then  -- 300 seconds = 5 minutes
			print(player.Name .. " has spent 5 minutes in the server!")
			local datapoint = {
				username = player.Name,
			}	
			
			local jsonData = HttpService:JSONEncode(datapoint)
			local url = "http://localhost:3000/reward"
	
			local success, response = pcall(function()
				return HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)
			end)
			
			if success then
				print("Reward request sent for " .. player.Name)
				
				-- Visual notification
				local message = Instance.new("Message")
				message.Text = "You have spent 5 minutes in the server! Reward request sent."
				message.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
				task.wait(3)  -- Show the message for 3 seconds
				message:Destroy()
			else
				warn("Failed to send reward request: " .. tostring(response))
			end
			
			break  -- Exit the loop after sending the reward
		end 

		wait(1)  -- Wait for 1 second before checking again
	end
end

-- Connect the function to PlayerAdded event
Players.PlayerAdded:Connect(function(player)
	coroutine.wrap(trackPlayerTime)(player)
end)
