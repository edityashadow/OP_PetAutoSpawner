-- OP_PetAutoSpawner.lua
-- Roblox OP Pet Auto-Spawner Script with auto-collect, auto-sell, multi-spawn, GUI, and upgrade system

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

-- ========= KONFIGURASI =========
local Config = {
    INTERVAL = 3,                 -- Waktu spawn (detik)
    MAX_PETS = 50,                -- Maksimal jumlah pet aktif
    SPAWN_COUNT = 5,              -- Jumlah pet setiap spawn
    PET_TEMPLATE = "Pet",         -- Nama model pet di ReplicatedStorage
    SPAWN_AREA = "PetArea",       -- Nama folder/area di workspace untuk spawn
    COLLECT_RANGE = 30,           -- Radius auto-collect coin
    AUTO_SELL_INTERVAL = 10,      -- Waktu auto-sell coin
    COIN_NAME = "GoldCoin",       -- Nama coin yang dikoleksi
    SELL_EVENT_NAME = "SellEvent" -- Nama RemoteEvent di ReplicatedStorage
}

-- ========= SISTEM UPGRADE =========
local Upgrades = {
    SPAWN_SPEED = {level = 1, cost = 500, effect = 0.2},
    PET_CAPACITY = {level = 1, cost = 1000, effect = 5},
    COLLECT_RANGE = {level = 1, cost = 800, effect = 5}
}

-- ========= STATE GLOBAL =========
local enabled = true
local activePets = {}
local totalCoins = 0
local playerStats = {}

-- ========= INISIALISASI =========
local petModel = RS:WaitForChild(Config.PET_TEMPLATE)
local spawnFolder = workspace:WaitForChild(Config.SPAWN_AREA)
local sellEvent = RS:FindFirstChild(Config.SELL_EVENT_NAME) or Instance.new("RemoteEvent")
sellEvent.Name = Config.SELL_EVENT_NAME
sellEvent.Parent = RS

-- ========= FUNGSI: SPAWN PET =========
local function spawnPet()
    if not enabled or #activePets >= Config.MAX_PETS then return end

    for i = 1, Config.SPAWN_COUNT do
        local clone = petModel:Clone()
        clone.Parent = spawnFolder

        -- Posisi random di area spawn
        local size = spawnFolder:GetExtentsSize() * 0.4
        local position = Vector3.new(
            spawnFolder.Position.X + math.random(-size.X, size.X),
            spawnFolder.Position.Y + 3,
            spawnFolder.Position.Z + math.random(-size.Z, size.Z)
        )
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(CFrame.new(position))
        end
        table.insert(activePets, clone)

        -- Auto-collect coin
        coroutine.wrap(function()
            while clone.Parent do
                wait(0.5)
                for _, coin in ipairs(workspace:GetChildren()) do
                    if coin.Name == Config.COIN_NAME and (coin.Position - clone.PrimaryPart.Position).magnitude <= Config.COLLECT_RANGE then
                        coin:Destroy()
                        totalCoins += 1
                    end
                end
            end
        end)()
    end
end

-- ========= AUTO-SELL SYSTEM =========
coroutine.wrap(function()
    while true do
        wait(Config.AUTO_SELL_INTERVAL)
        if totalCoins > 0 then
            sellEvent:FireServer(totalCoins)
            totalCoins = 0
        end
    end
end)()

-- ========= UPGRADE SYSTEM =========
local function applyUpgrades()
    Config.INTERVAL = math.max(0.5, 5 - (Upgrades.SPAWN_SPEED.level * Upgrades.SPAWN_SPEED.effect))
    Config.MAX_PETS = 50 + (Upgrades.PET_CAPACITY.level * Upgrades.PET_CAPACITY.effect)
    Config.COLLECT_RANGE = 30 + (Upgrades.COLLECT_RANGE.level * Upgrades.COLLECT_RANGE.effect)
end

-- ========= GUI =========
local function createOPGui(player)
    local gui = Instance.new("ScreenGui")
    gui.Name = "PetSpawnerOPGUI"
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 250)
    frame.Position = UDim2.new(0.05, 0, 0.3, 0)
    frame.BackgroundTransparency = 0.3
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Parent = gui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.9, 0, 0.15, 0)
    toggleBtn.Position = UDim2.new(0.05, 0, 0.05, 0)
    toggleBtn.Text = "PET SPAWNER: ON"
    toggleBtn.Parent = frame

    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
    statsLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.TextColor3 = Color3.new(1,1,1)
    statsLabel.Text = "Loading stats..."
    statsLabel.Parent = frame

    local yPos = 0.7
    for upgradeName, data in pairs(Upgrades) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0.1, 0)
        btn.Position = UDim2.new(0.05, 0, yPos, 0)
        btn.Text = upgradeName.." (Lvl "..data.level..")"
        btn.Parent = frame
        yPos += 0.12
    end

    local function updateGUI()
        toggleBtn.Text = "PET SPAWNER: " .. (enabled and "ON" or "OFF")
        statsLabel.Text = string.format(
            "Active Pets: %d/%d\nCoins: %d\nSpawn Speed: %.1fs\nCollect Range: %d",
            #activePets, Config.MAX_PETS,
            totalCoins,
            Config.INTERVAL,
            Config.COLLECT_RANGE
        )
    end

    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateGUI()
    end)

    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextButton") and child ~= toggleBtn then
            child.MouseButton1Click:Connect(function()
                local upgradeName = string.split(child.Text, " ")[1]
                local upgrade = Upgrades[upgradeName]
                if playerStats[player] and playerStats[player] >= upgrade.cost then
                    playerStats[player] -= upgrade.cost
                    upgrade.level += 1
                    upgrade.cost = math.floor(upgrade.cost * 1.5)
                    child.Text = upgradeName.." (Lvl "..upgrade.level..")"
                    applyUpgrades()
                    updateGUI()
                end
            end)
        end
    end

    coroutine.wrap(function()
        while gui.Parent do
            updateGUI()
            wait(1)
        end
    end)()
end

-- ========= MAIN LOOP =========
coroutine.wrap(function()
    while true do
        if enabled then
            spawnPet()
        end
        wait(Config.INTERVAL)
    end
end)()

-- ========= PLAYER HANDLER =========
Players.PlayerAdded:Connect(function(player)
    playerStats[player] = 0
    player.CharacterAdded:Connect(function()
        createOPGui(player)
    end)
end)

game:BindToClose(function()
    for _, pet in ipairs(activePets) do
        if pet then pet:Destroy() end
    end
end)

return "✅ OP Pet System Activated!"