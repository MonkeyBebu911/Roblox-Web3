-- Tracks the amount of time that a player has spent in a server

local Players = game:GetService("Players")
local player = game.Players.LocalPlayer
local username = player.Name


-- Function to track player time
local function trackPlayerTime(player)
	local joinTime = os.time()
	local timeSpent = 0
	local messageShown = false

	while player.Parent do
		timeSpent = os.time() - joinTime

		if timeSpent >= 300 and not messageShown then  -- 300 seconds = 5 minutes
			print(player.Name .. " has spent 5 minutes in the server!")
			-- message shown is the key variable in which we want information to be sent / send 
			messageShown = true

			local data = {
				playerName = player.Name
				messageShown = messageShown
			}

			local jsonData = HttpService:JSONEncode(data)
			local url = ""

			local success, response = pcall(function()
				return HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)
            		end)

		end

		wait(1)  -- Wait for 1 second before checking again
	end
	
end

-- Connect the function to PlayerAdded event
Players.PlayerAdded:Connect(function(player)
	coroutine.wrap(trackPlayerTime)(player)
end)
