--// LOAD UI
local MacLib = loadstring(game:HttpGet(
    "https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"
))()

--// SERVICES
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

--// WINDOW
local Window = MacLib:Window({
    Title = "WIN700 PRO",
    Subtitle = "Private | V0.1b1 By BKMS Developer",
    Size = UDim2.fromOffset(880, 620),
    DragStyle = 1,
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.RightControl,
})

local TabGroup = Window:TabGroup()
local Tab = TabGroup:Tab({ Name = "หลัก" })
local Section = Tab:Section({ Side = "Left" })

Section:Label({ Text = "HITBOX SYSTEM (ADVANCED)" })

--------------------------------------------------
--// SETTINGS
--------------------------------------------------

local HitboxEnabled = false
local HeadOnlyEnabled = false

local BodyScale = 1.6
local HeadScale = 2.2

local OriginalParts = {} -- [BasePart] = {Size, Transparency}

--------------------------------------------------
--// UTIL : GET REAL HEAD PART
--------------------------------------------------

local function GetHeadPart(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    -- Humanoid.Head (R15 / Custom)
    if hum:FindFirstChild("Head") and hum.Head:IsA("BasePart") then
        return hum.Head
    end

    -- Motor6D ที่ชื่อ Head
    for _, m in ipairs(character:GetDescendants()) do
        if m:IsA("Motor6D") and m.Name:lower():find("head") then
            if m.Part1 and m.Part1:IsA("BasePart") then
                return m.Part1
            end
        end
    end

    -- fallback: part ที่อยู่สูงสุด
    local highest
    for _, p in ipairs(character:GetChildren()) do
        if p:IsA("BasePart") then
            if not highest or p.Position.Y > highest.Position.Y then
                highest = p
            end
        end
    end

    return highest
end

--------------------------------------------------
--// APPLY HITBOX
--------------------------------------------------

local function ApplyHitboxToCharacter(plr)
    if plr == Player then return end
    local char = plr.Character
    if not char then return end

    if HeadOnlyEnabled then
        -- 🎯 HEAD ONLY
        local head = GetHeadPart(char)
        if not head then return end

        if not OriginalParts[head] then
            OriginalParts[head] = {
                Size = head.Size,
                Transparency = head.Transparency
            }
        end

        head.Size = OriginalParts[head].Size * HeadScale
        head.Transparency = math.clamp(OriginalParts[head].Transparency + 0.4, 0, 0.9)

    else
        -- 🧍 FULL BODY
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                if not OriginalParts[obj] then
                    OriginalParts[obj] = {
                        Size = obj.Size,
                        Transparency = obj.Transparency
                    }
                end

                obj.Size = OriginalParts[obj].Size * BodyScale
                obj.Transparency = math.clamp(OriginalParts[obj].Transparency + 0.25, 0, 0.9)
            end
        end
    end
end

--------------------------------------------------
--// LOOP
--------------------------------------------------

local HitboxThread
local function StartLoop()
    if HitboxThread then return end

    HitboxThread = task.spawn(function()
        while HitboxEnabled do
            for _, plr in ipairs(Players:GetPlayers()) do
                ApplyHitboxToCharacter(plr)
            end
            task.wait(0.7)
        end
    end)
end

local function RestoreAll()
    for part, data in pairs(OriginalParts) do
        if part and part.Parent then
            part.Size = data.Size
            part.Transparency = data.Transparency
        end
    end
    table.clear(OriginalParts)
end

local function EnableHitbox()
    HitboxEnabled = true
    StartLoop()
end

local function DisableHitbox()
    HitboxEnabled = false
    HitboxThread = nil
    RestoreAll()
end

--------------------------------------------------
--// RESPAWN / NEW PLAYER
--------------------------------------------------

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if HitboxEnabled then
            ApplyHitboxToCharacter(plr)
        end
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if HitboxEnabled then
            ApplyHitboxToCharacter(plr)
        end
    end)
end

--------------------------------------------------
--// TEAM ESP SYSTEM
--------------------------------------------------

local ESPEnabled = false
local ESPTeamCheck = true
local ESPMode = "Box" -- "Box" | "Adornee"
local ESPObjects = {}

local function SameTeam(plr)
    if not ESPTeamCheck then
        return false
    end

    if not Player.Team or not plr.Team then
        return false
    end

    return plr.Team == Player.Team
end

local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        if esp.Gui then esp.Gui:Destroy() end
        if esp.Adorn then esp.Adorn:Destroy() end
    end
    table.clear(ESPObjects)
end

local function CreateESP(plr)
    if plr == Player then return end
    if SameTeam(plr) then return end
    if not plr.Character then return end
    if ESPObjects[plr] then return end

    local char = plr.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local esp = {}

    if ESPMode == "Box" then
        local gui = Instance.new("BillboardGui")
        gui.Adornee = hrp
        gui.Size = UDim2.fromScale(4, 5)
        gui.AlwaysOnTop = true
        gui.Parent = hrp

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 60, 60)
        frame.Parent = gui

        esp.Gui = gui
    else
        local adorn = Instance.new("BoxHandleAdornment")
        adorn.Adornee = hrp
        adorn.Size = hrp.Size + Vector3.new(1.5, 2.5, 1.5)
        adorn.Color3 = Color3.fromRGB(255, 60, 60)
        adorn.Transparency = 0.6
        adorn.AlwaysOnTop = true
        adorn.ZIndex = 5
        adorn.Parent = hrp

        esp.Adorn = adorn
    end

    ESPObjects[plr] = esp
end

local function RefreshESP()
    ClearESP()
    if not ESPEnabled then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        CreateESP(plr)
    end
end

local function EnableESP()
    ESPEnabled = true
    RefreshESP()
end

local function DisableESP()
    ESPEnabled = false
    ClearESP()
end

--------------------------------------------------
--// PLAYER EVENTS
--------------------------------------------------

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled then
            RefreshESP()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESPObjects[plr] then
        ClearESP()
    end
end)

Player:GetPropertyChangedSignal("Team"):Connect(function()
    if ESPEnabled then
        RefreshESP()
    end
end)


--------------------------------------------------
--// UI
--------------------------------------------------

Section:Toggle({
    Name = "ขนาด HITBOX",
    Default = false,
    Callback = function(v)
        if v then
            EnableHitbox()
        else
            DisableHitbox()
        end
    end,
}, "HitboxToggle")

Section:Toggle({
    Name = "หัวเท่านั้น",
    Default = false,
    Callback = function(v)
        HeadOnlyEnabled = v
        if HitboxEnabled then
            RestoreAll()
        end
    end,
}, "HeadOnlyToggle")

Section:Slider({
    Name = "ขนาดตัว",
    Default = 16,
    Minimum = 12,
    Maximum = 30,
    DisplayMethod = "Percent",
    Callback = function(v)
        BodyScale = v / 10
    end,
}, "BodyScaleSlider")

Section:Slider({
    Name = "ขนาดหัว",
    Default = 22,
    Minimum = 15,
    Maximum = 40,
    DisplayMethod = "Percent",
    Callback = function(v)
        HeadScale = v / 10
    end,
}, "HeadScaleSlider")

Section:Toggle({
    Name = "ESP",
    Default = false,
    Callback = function(v)
        if v then
            EnableESP()
        else
            DisableESP()
        end
    end,
}, "ESPToggle")

Section:Toggle({
    Name = "ESP เชคทีม",
    Default = true,
    Callback = function(v)
        ESPTeamCheck = v
        if ESPEnabled then
            RefreshESP()
        end
    end,
}, "ESPTeamToggle")

Section:Toggle({
    Name = "ESP โหมด (Adornee)",
    Default = false,
    Callback = function(v)
        ESPMode = v and "Adornee" or "Box"
        if ESPEnabled then
            RefreshESP()
        end
    end,
}, "ESPModeToggle")
