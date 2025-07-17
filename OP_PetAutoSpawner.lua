-- DarkSpawner.lua
-- Simple Pet Spawner UI: Pet Name, Weight, Age, Spawn Button

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Konfigurasi
local PET_TEMPLATE = "Pet"       -- Model di ReplicatedStorage
local SPAWN_AREA   = "PetArea"   -- Part/Folder di Workspace

-- Utility: buat UI
local function createGui(player)
    local gui = Instance.new("ScreenGui")
    gui.Name = "DarkSpawner"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    
    -- Frame utama
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 200)
    frame.Position = UDim2.new(0.5, -175, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.Text = "Pet Spawner"
    title.Parent = frame

    -- Helper untuk input field
    local function makeInput(labelText, yPos)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 100, 0, 25)
        lbl.Position = UDim2.new(0, 10, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.Text = labelText
        lbl.Parent = frame

        local txt = Instance.new("TextBox")
        txt.Size = UDim2.new(0, 140, 0, 25)
        txt.Position = UDim2.new(0, 120, 0, yPos)
        txt.BackgroundColor3 = Color3.fromRGB(60,60,60)
        txt.BorderSizePixel = 0
        txt.Font = Enum.Font.Gotham
        txt.TextSize = 14
        txt.TextColor3 = Color3.new(1,1,1)
        txt.Text = ""
        txt.ClearTextOnFocus = false
        txt.Parent = frame

        return txt
    end

    -- Input fields
    local inpName   = makeInput("Pet Name:",   40)
    local inpWeight = makeInput("Pet Weight:", 70)
    local inpAge    = makeInput("Pet Age:",    100)

    -- Spawn Button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 30)
    btn.Position = UDim2.new(0, 120, 0, 140)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = "Spawn"
    btn.Parent = frame

    -- Fungsi Spawn
    local function spawnPet()
        local model = RS:FindFirstChild(PET_TEMPLATE)
        local area  = Workspace:FindFirstChild(SPAWN_AREA)
        if not model or not area then return end

        local clone = model:Clone()
        clone.Parent = area

        -- Set posisi random dalam area
        local size = (area:IsA("BasePart") and area.Size or Vector3.new(20,0,20)) * 0.5
        local pos = Vector3.new(
            area.Position.X + math.random(-size.X, size.X),
            area.Position.Y + 2,
            area.Position.Z + math.random(-size.Z, size.Z)
        )
        if clone.PrimaryPart then
            clone:SetPrimaryPartCFrame(CFrame.new(pos))
        end

        -- Assign Properties dari input
        if inpName.Text ~= "" then
            clone.Name = inpName.Text
        end

        -- Simpan weight & age sebagai Attribute
        local w = tonumber(inpWeight.Text)
        if w then clone:SetAttribute("Weight", w) end

        local a = tonumber(inpAge.Text)
        if a then clone:SetAttribute("Age", a) end
    end

    -- Connect button
    btn.MouseButton1Click:Connect(spawnPet)
end

-- Pasang GUI untuk setiap player
Players.PlayerAdded:Connect(function(p)
    createGui(p)
end)
-- Untuk yang sudah di game ketika script jalan
for _, p in ipairs(Players:GetPlayers()) do
    createGui(p)
end