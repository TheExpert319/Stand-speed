-- Put this in a LocalScript inside StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function resetHealth(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    while humanoid and humanoid.Parent do
        humanoid.Health = 100
        wait(0.1)
    end
end

if player.Character then
    resetHealth(player.Character)
end

player.CharacterAdded:Connect(resetHealth)
