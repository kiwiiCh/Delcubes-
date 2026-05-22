local Players = game:GetService("Players")
local localplr = Players.LocalPlayer
local cfolder = workspace:WaitForChild("Bricks")
local termiteRunning = false
local THREADS = 100

local function getDeleteTool()
	if localplr.Character then
		for _, v in ipairs(localplr.Character:GetChildren()) do
			if v:IsA("Tool") and v.Name == "Delete" then
				local scr = v:FindFirstChild("Script")
				if scr and scr:FindFirstChild("Event") then
					return scr.Event, v
				end
			end
		end
	end
	for _, v in ipairs(localplr.Backpack:GetChildren()) do
		if v:IsA("Tool") and v.Name == "Delete" then
			local scr = v:FindFirstChild("Script")
			if scr and scr:FindFirstChild("Event") then
				return scr.Event, v
			end
		end
	end
	return nil, nil
end

-- Partial name match against player folders in workspace.Bricks
local function findPlayerFolder(name)
	name = name:lower()
	for _, folder in ipairs(cfolder:GetChildren()) do
		if folder.Name:lower():sub(1, #name) == name then
			return folder
		end
	end
	return nil
end

local function collectBricks(targetFolder)
	local bricks = {}
	local n = 0
	if targetFolder then
		for _, v in ipairs(targetFolder:GetDescendants()) do
			if v:IsA("BasePart") then
				n = n + 1
				bricks[n] = v
			end
		end
	else
		for _, v in ipairs(cfolder:GetDescendants()) do
			if v:IsA("BasePart") then
				n = n + 1
				bricks[n] = v
			end
		end
	end
	return bricks, n
end

local function nukeBricks(bricks, n, label)
	if n == 0 then
		print("[Termite] No bricks found for " .. label)
		termiteRunning = false
		return
	end

	print("[Termite] Found " .. n .. " bricks for " .. label .. ". Nuking...")
	termiteRunning = true

	task.spawn(function()
		while termiteRunning do
			local event, tool = getDeleteTool()
			if not event or not tool then
				warn("[Termite] Lost Delete tool.")
				termiteRunning = false
				break
			end

			tool.Parent = localplr.Character
			tool.Parent = localplr.Backpack

			local hrp = localplr.Character:FindFirstChild("HumanoidRootPart")
			local pos = hrp and hrp.Position or Vector3.zero

			-- Refresh brick list every sweep to catch stragglers
			bricks, n = collectBricks(label == "ALL" and nil or findPlayerFolder(label))

			if n == 0 then
				print("[Termite] All bricks deleted. Stopped.")
				termiteRunning = false
				break
			end

			local chunkSize = math.ceil(n / THREADS)

			for t = 1, THREADS do
				local s = (t - 1) * chunkSize + 1
				local e = math.min(t * chunkSize, n)
				if s > n then continue end

				task.spawn(function()
					for i = s, e do
						local b = bricks[i]
						if b and b.Parent then
							event:FireServer(b, pos)
						end
					end
				end)
			end

			task.wait()
		end
	end)
end

local function runTermite(targetName)
	if termiteRunning then
		warn("[Termite] Already running.")
		return
	end

	local event, tool = getDeleteTool()
	if not event or not tool then
		warn("[Termite] No Delete tool found. Aborting.")
		return
	end

	if targetName then
		local folder = findPlayerFolder(targetName)
		if not folder then
			warn("[Termite] No folder found for player: " .. targetName)
			return
		end
		local bricks, n = collectBricks(folder)
		nukeBricks(bricks, n, targetName)
	else
		local bricks, n = collectBricks(nil)
		nukeBricks(bricks, n, "ALL")
	end
end

localplr.Chatted:Connect(function(msg)
	local cmd = msg:lower():gsub("%s+", " "):match("^%s*(.-)%s*$")

	-- destroy cubes all
	if cmd == "destroy cubes" or cmd == ";destroy cubes" then
		runTermite(nil)

	-- destroy cubes (playername)
	elseif cmd:sub(1, 14) == "destroy cubes " then
		local target = cmd:sub(15)
		runTermite(target)
	elseif cmd:sub(1, 15) == ";destroy cubes " then
		local target = cmd:sub(16)
		runTermite(target)

	-- stop
	elseif cmd == "destroy cubes stop" or cmd == ";destroy cubes stop" then
		if termiteRunning then
			termiteRunning = false
			print("[Termite] Manually stopped.")
		else
			print("[Termite] Not running.")
		end
	end
end)

print("[Termite] Ready.")
