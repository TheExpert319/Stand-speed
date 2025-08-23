-- Godmode.lua
-- This script will make the player invincible

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local function enableGodmode(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    -- Set health to a very high number
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge

    -- Optional: Prevent further health changes
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)

    -- Optional: Prevent death state
    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Dead then
            humanoid.Health = humanoid.MaxHealth
        end
    end)

    -- Keep health maxed in a loop (fail-safe)
    task.spawn(function()
        while humanoid and humanoid.Parent do
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
            task.wait(0.1)
        end
    end)
end

-- Activate godmode on current and future characters
enableGodmode(character)
player.CharacterAdded:Connect(enableGodmode)
