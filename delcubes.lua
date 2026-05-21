-- Termite Script v4 (Chat Command: destroy cubes)

local Players = game:GetService("Players")
local localplr = Players.LocalPlayer
local cfolder = workspace:WaitForChild("Bricks")
local termiteRunning = false

local function getDeleteEvent()
    if localplr.Character then
        for _, v in ipairs(localplr.Character:GetChildren()) do
            if v:IsA("Tool") and v.Name == "Delete" then
                local scr = v:FindFirstChild("Script")
                if scr and scr:FindFirstChild("Event") then
                    return scr.Event, v
                end
                local ev = v:FindFirstChildWhichIsA("RemoteEvent")
                if ev then return ev, v end
            end
        end
    end
    for _, v in ipairs(localplr.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name == "Delete" then
            local scr = v:FindFirstChild("Script")
            if scr and scr:FindFirstChild("Event") then
                return scr.Event, v
            end
            local ev = v:FindFirstChildWhichIsA("RemoteEvent")
            if ev then return ev, v end
        end
    end
    return nil, nil
end

local function countAllBricks()
    local count = 0
    for _, folder in ipairs(cfolder:GetChildren()) do
        for _, brick in ipairs(folder:GetChildren()) do
            if brick:IsA("BasePart") then
                count = count + 1
            end
        end
    end
    return count
end

local function runTermite()
    if termiteRunning then
        warn("[Termite] Already running.")
        return
    end

    local event, tool = getDeleteEvent()
    if not event then
        warn("[Termite] No Delete tool found. Aborting.")
        return
    end

    local total = countAllBricks()
    if total == 0 then
        print("[Termite] No bricks found on the map.")
        return
    end

    print("[Termite] Found " .. total .. " bricks. Starting...")
    termiteRunning = true
    local dti = 0

    coroutine.wrap(function()
        while termiteRunning do
            event, tool = getDeleteEvent()
            if not event then
                warn("[Termite] Lost Delete tool. Stopping.")
                termiteRunning = false
                break
            end

            local hrp = localplr.Character and localplr.Character:FindFirstChild("HumanoidRootPart")
            local pos = (hrp and hrp.Position) or Vector3.zero
            local foundAny = false

            for _, folder in ipairs(cfolder:GetChildren()) do
                for _, brick in ipairs(folder:GetChildren()) do
                    if not termiteRunning then break end
                    if brick and brick.Parent and brick:IsA("BasePart") then
                        foundAny = true
                        dti = dti + 1

                        if dti % 30 == 0 then
                            event, tool = getDeleteEvent()
                            hrp = localplr.Character and localplr.Character:FindFirstChild("HumanoidRootPart")
                            pos = (hrp and hrp.Position) or Vector3.zero
                            if not event then
                                termiteRunning = false
                                break
                            end
                        end

                        pcall(function()
                            event:FireServer(brick, pos)
                        end)

                        task.wait(0.03)
                    end
                end
            end

            if not foundAny or countAllBricks() == 0 then
                print("[Termite] All bricks deleted. Stopped.")
                termiteRunning = false
                break
            end

            task.wait(0.1)
        end
    end)()
end

-- Chat command listener
localplr.Chatted:Connect(function(msg)
    local cmd = msg:lower():gsub("%s+", " "):match("^%s*(.-)%s*$")

    if cmd == "destroy cubes" or cmd == ";destroy cubes" then
        runTermite()
    elseif cmd == "destroy cubes stop" or cmd == ";destroy cubes stop" then
        if termiteRunning then
            termiteRunning = false
            print("[Termite] Manually stopped.")
        else
            print("[Termite] Not running.")
        end
    end
end)

print("[Termite] Ready. Type 'destroy cubes' or ';destroy cubes' in chat to start.")
