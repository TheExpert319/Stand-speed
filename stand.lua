getgenv().Owner = "DoWeNeedMen4"

getgenv().Configuration = {
    CrewID = 32570691,
    AttackDistance = 75,
    SafeLocation = Vector3.new(0, 100, 0),
    MaskToBuy = "Skull",
    GunModes = {"rifle","aug","lmg"},
    AttackCooldown = 0.3,
    AutoMask = true,
    AutoSave = true,
    Prefix = ".", -- Command prefix
}

do
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")
    local LocalPlayer = Players.LocalPlayer
    local cfg = getgenv().Configuration
    local whitelist = {[getgenv().Owner] = true}
    local standSummoned = false
    local selectedGun = nil
    local autoKill = false
    local autoKillGun = false
    local targetKillName = nil
    local autoSave = false

    local function notify(msg)
        pcall(function()
            StarterGui:SetCore("SendNotification", {Title = "Stand", Text = msg, Duration = 3})
        end)
    end

    local function isUser(name) return name == getgenv().Owner end
    local function isWhitelisted(name) return whitelist[name] end
    local function canTarget(attacker, target)
        if isUser(attacker) then return true end
        if isWhitelisted(attacker) then return not isWhitelisted(target) end
        return false
    end

    -- Get remotes (adjust names if different)
    local Punch = ReplicatedStorage:FindFirstChild("Punch") or ReplicatedStorage:FindFirstChild("PunchEvent")
    local Shoot = ReplicatedStorage:FindFirstChild("Shoot") or ReplicatedStorage:FindFirstChild("ShootEvent")
    local Bring = ReplicatedStorage:FindFirstChild("Bring") or ReplicatedStorage:FindFirstChild("BringEvent")
    local Frame = ReplicatedStorage:FindFirstChild("Frame") or ReplicatedStorage:FindFirstChild("FrameEvent")

    local function getDist(player)
        local lp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tp = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if lp and tp then
            return (lp.Position - tp.Position).Magnitude
        else
            return math.huge
        end
    end

    -- PUNCH then STOMP (regular kill)
    local function punchThenStomp(player)
        if not player or not player.Character or getDist(player) > cfg.AttackDistance then
            notify("Target invalid or too far")
            return
        end
        if Punch then
            Punch:FireServer(player.Character)
            task.wait(0.1)
            Punch:FireServer(player.Character) -- stomp is another punch
        end
    end

    -- SHOOT only (gun knock or gknock)
    local function shootOnce(player)
        if player and player.Character and getDist(player) <= cfg.AttackDistance and Shoot and selectedGun then
            Shoot:FireServer(player.Character, selectedGun)
        else
            notify("Target invalid, too far, or no gun selected")
        end
    end

    -- SHOOT then STOMP (gun kill)
    local function shootThenStomp(player)
        if not player or not player.Character or getDist(player) > cfg.AttackDistance then
            notify("Target invalid or too far")
            return
        end
        shootOnce(player)
        task.wait(0.1)
        if Punch then
            Punch:FireServer(player.Character) -- stomp after shoot
        end
    end

    -- PUNCH only (knock)
    local function punchOnce(player)
        if player and player.Character and getDist(player) <= cfg.AttackDistance then
            if Punch then
                Punch:FireServer(player.Character)
            end
        else
            notify("Target invalid or too far")
        end
    end

    local function startAutoKill(name, useGun)
        if autoKill then
            autoKill = false
            targetKillName = nil
            notify("AutoKill stopped")
            return
        end

        local p = Players:FindFirstChild(name)
        if not p then
            notify("Target not found")
            return
        end
        if not standSummoned then
            notify("Summon your stand first")
            return
        end
        if useGun and not selectedGun then
            notify("Select a gun first")
            return
        end
        if not canTarget(LocalPlayer.Name, name) then
            notify("No permission to attack")
            return
        end

        autoKill = true
        autoKillGun = useGun
        targetKillName = name
        notify("AutoKill started on " .. name .. (useGun and " with gun" or " with punches"))

        task.spawn(function()
            while autoKill do
                local t = Players:FindFirstChild(targetKillName)
                if not t or not canTarget(LocalPlayer.Name, t.Name) then
                    notify("AutoKill stopped: target lost or no permission")
                    autoKill = false
                    break
                end
                if useGun then
                    shootThenStomp(t)
                else
                    punchThenStomp(t)
                end
                task.wait(cfg.AttackCooldown)
            end
        end)
    end

    local function teleportSafe()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(cfg.SafeLocation)
            notify("Teleported to safe location")
        end
    end

    local function startAutoSave()
        if autoSave then return notify("AutoSave already ON") end
        autoSave = true
        notify("AutoSave ON")
        task.spawn(function()
            while autoSave do
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and hum.Health < 5 then
                    teleportSafe()
                end
                task.wait(1)
            end
        end)
    end

    local function stopAutoSave()
        if not autoSave then return notify("AutoSave already OFF") end
        autoSave = false
        notify("AutoSave OFF")
    end

    LocalPlayer.Chatted:Connect(function(msg)
        if msg:sub(1, #cfg.Prefix) ~= cfg.Prefix then return end
        local args = msg:split(" ")
        local cmd = args[1]:lower()
        local sender = LocalPlayer.Name

        if not (isUser(sender) or isWhitelisted(sender)) then return end

        if cmd == cfg.Prefix .. "summon" then
            standSummoned = true
            notify("Stand summoned")

        elseif cmd == cfg.Prefix .. "vanish" then
            standSummoned = false
            notify("Stand vanished")

        elseif cmd == cfg.Prefix .. "gun" and args[2] then
            local gm = args[2]:lower()
            for _, v in ipairs(cfg.GunModes) do
                if v == gm then
                    selectedGun = gm
                    notify("Gun selected: " .. gm)
                    return
                end
            end
            notify("Invalid gun")

        elseif cmd == cfg.Prefix .. "kill" and args[2] then
            local p = Players:FindFirstChild(args[2])
            if p and canTarget(sender, args[2]) then
                punchThenStomp(p)
            else
                notify("Target not found or no permission")
            end

        elseif cmd == cfg.Prefix .. "autokill" and args[2] then
            startAutoKill(args[2], false)

        elseif cmd == cfg.Prefix .. "knock" and args[2] then
            local p = Players:FindFirstChild(args[2])
            if p and canTarget(sender, args[2]) then
                punchOnce(p)
                notify("Knock punched " .. args[2])
            else
                notify("Knock failed: target not found or no permission")
            end

        elseif cmd == cfg.Prefix .. "gkill" and args[2] then
            if not selectedGun then return notify("Select a gun first") end
            local p = Players:FindFirstChild(args[2])
            if p and canTarget(sender, args[2]) then
                shootThenStomp(p)
            else
                notify("Target not found or no permission")
            end

        elseif cmd == cfg.Prefix .. "gautokill" and args[2] then
            startAutoKill(args[2], true)

        elseif cmd == cfg.Prefix .. "gknock" and args[2] then
            if not selectedGun then return notify("Select a gun first") end
            local p = Players:FindFirstChild(args[2])
            if p and canTarget(sender, args[2]) then
                shootOnce(p)
                notify("GKnock shot " .. args[2])
            else
                notify("GKnock failed: target not found or no permission")
            end

        elseif cmd == cfg.Prefix .. "bring" and args[2] then
            local p = Players:FindFirstChild(args[2])
            if p and canTarget(sender, args[2]) and Bring then
                Bring:FireServer(p.Character)
                notify("Brought " .. args[2])
            else
                notify("Bring failed: target not found or no permission")
            end

        elseif cmd == cfg.Prefix .. "gbring" and args[2] then
            local p = Players:FindFirstChild(args[2])
            if p and canTarget(sender, args[2]) and Bring then
                Bring:FireServer(p.Character)
                notify("G Brought " .. args[2])
            else
                notify("GBring failed: target not found or no permission")
            end

        elseif cmd == cfg.Prefix .. "frame" and args[2] then
            local p = Players:FindFirstChild(args[2])
            if p and canTarget(sender, args[2]) and Frame then
                Frame:FireServer(p.Character)
                notify("Framed " .. args[2])
            else
                notify("Frame failed: target not found or no permission")
            end

        elseif cmd == cfg.Prefix .. "autosave" then
            startAutoSave()

        elseif cmd == cfg.Prefix .. "stopautosave" then
            stopAutoSave()

        elseif cmd == cfg.Prefix .. "stopautokill" then
            autoKill = false
            targetKillName = nil
            notify("AutoKill stopped")

        else
            notify("Unknown command")
        end
    end)
end
