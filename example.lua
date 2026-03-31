--[[
    Example usage for the modified Bbot UI library.
    Features:
    - ESP (Drawing API)
    - Desync jitter
    - "Server Only" showcase toggle
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Load library if it is not already in getgenv()
if not getgenv().Library then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/meowza1/smori/refs/heads/main/Library.lua"))()
end

local Library = getgenv().Library
local Notifications = Library.Notifications

local window = Library:Window({
    Name = "Bbot Visual Demo",
    Size = UDim2.new(0, 520, 0, 620)
})

Library:Configs(window)

local visuals = window:Tab({Name = "Visuals"})
local misc = window:Tab({Name = "Misc"})

local espSection = visuals:Section({Name = "ESP", Side = "Left"})
local styleSection = visuals:Section({Name = "Style", Side = "Right"})
local desyncSection = misc:Section({Name = "Desync", Side = "Left"})
local serverSection = misc:Section({Name = "Server", Side = "Right"})

local state = {
    espEnabled = false,
    espColor = Color3.fromRGB(50, 170, 255),
    espThickness = 1.6,
    showNames = true,
    showDistance = true,

    desyncEnabled = false,
    desyncX = 1.5,
    desyncY = 0,
    desyncZ = 1.5,

    serverOnly = false,
}

local drawings = {}

local function clearPlayerDrawing(player)
    local cache = drawings[player]
    if not cache then
        return
    end

    for _, object in cache do
        pcall(function()
            object:Remove()
        end)
    end

    drawings[player] = nil
end

local function getDrawingFor(player)
    if drawings[player] then
        return drawings[player]
    end

    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = state.espThickness
    line.Color = state.espColor

    local label = Drawing.new("Text")
    label.Visible = false
    label.Center = true
    label.Outline = true
    label.Size = 13
    label.Color = state.espColor
    label.Font = 2

    drawings[player] = {
        line = line,
        label = label,
    }

    return drawings[player]
end

local function updateESPStyle()
    for _, cache in drawings do
        cache.line.Color = state.espColor
        cache.line.Thickness = state.espThickness
        cache.label.Color = state.espColor
    end
end

local function hideESP()
    for _, cache in drawings do
        cache.line.Visible = false
        cache.label.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if not state.espEnabled then
        hideESP()
        return
    end

    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer then
            local cache = getDrawingFor(player)
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if root and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local dist = myRoot and math.floor((myRoot.Position - root.Position).Magnitude) or 0

                    cache.line.Visible = true
                    cache.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    cache.line.To = Vector2.new(screenPos.X, screenPos.Y)

                    local text = player.Name
                    if state.showDistance then
                        text = string.format("%s [%dm]", text, dist)
                    end

                    cache.label.Visible = state.showNames
                    cache.label.Text = text
                    cache.label.Position = Vector2.new(screenPos.X, screenPos.Y - 18)
                else
                    cache.line.Visible = false
                    cache.label.Visible = false
                end
            else
                cache.line.Visible = false
                cache.label.Visible = false
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not state.desyncEnabled then
        return
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    root.CFrame *= CFrame.new(
        math.random(-100, 100) / 100 * state.desyncX,
        math.random(-100, 100) / 100 * state.desyncY,
        math.random(-100, 100) / 100 * state.desyncZ
    )
end)

Players.PlayerRemoving:Connect(function(player)
    clearPlayerDrawing(player)
end)

espSection:Toggle({
    Name = "Enable ESP",
    Flag = "demo_esp_toggle",
    Callback = function(value)
        state.espEnabled = value
        Notifications:Create({Name = value and "ESP enabled" or "ESP disabled"})
    end
})

espSection:Toggle({
    Name = "Show Names",
    Flag = "demo_esp_names",
    Default = true,
    Callback = function(value)
        state.showNames = value
    end
})

espSection:Toggle({
    Name = "Show Distance",
    Flag = "demo_esp_distance",
    Default = true,
    Callback = function(value)
        state.showDistance = value
    end
})

espSection:Slider({
    Name = "Line Thickness",
    Min = 1,
    Max = 4,
    Decimal = 0.1,
    Suffix = "px",
    Default = state.espThickness,
    Flag = "demo_esp_thickness",
    Callback = function(value)
        state.espThickness = value
        updateESPStyle()
    end
})

styleSection:Label({Name = "ESP Color"}):Colorpicker({
    Flag = "demo_esp_color",
    Color = state.espColor,
    Callback = function(color)
        state.espColor = color
        updateESPStyle()
    end
})

styleSection:Button({
    Name = "Clear ESP Drawings",
    Callback = function()
        for player in drawings do
            clearPlayerDrawing(player)
        end
        Notifications:Create({Name = "Cleared ESP drawings"})
    end
})

desyncSection:Toggle({
    Name = "Enable Desync",
    Flag = "demo_desync_toggle",
    Callback = function(value)
        state.desyncEnabled = value
        Notifications:Create({Name = value and "Desync enabled" or "Desync disabled"})
    end
})

desyncSection:Slider({
    Name = "Desync X",
    Min = 0,
    Max = 5,
    Decimal = 0.1,
    Default = state.desyncX,
    Flag = "demo_desync_x",
    Callback = function(value)
        state.desyncX = value
    end
})

desyncSection:Slider({
    Name = "Desync Y",
    Min = 0,
    Max = 3,
    Decimal = 0.1,
    Default = state.desyncY,
    Flag = "demo_desync_y",
    Callback = function(value)
        state.desyncY = value
    end
})

desyncSection:Slider({
    Name = "Desync Z",
    Min = 0,
    Max = 5,
    Decimal = 0.1,
    Default = state.desyncZ,
    Flag = "demo_desync_z",
    Callback = function(value)
        state.desyncZ = value
    end
})

serverSection:Toggle({
    Name = "Server Only Toggle",
    Flag = "demo_server_only",
    Callback = function(value)
        state.serverOnly = value

        if value then
            if RunService:IsServer() then
                Notifications:Create({Name = "Server-only action executed"})
                -- Place server-side logic here in a proper server environment.
            else
                Notifications:Create({Name = "Server-only action blocked (client context)"})
                state.serverOnly = false
                local setter = Library.ConfigFlags["demo_server_only"]
                if setter then
                    setter(false)
                end
            end
        end
    end
})

serverSection:Button({
    Name = "Unload Demo UI",
    Callback = function()
        for player in drawings do
            clearPlayerDrawing(player)
        end
        Library:Unload()
    end
})

window:Tab({Name = "Credits"}):Section({Name = "Info", Side = "Left"}):Label({
    Name = "Demo includes ESP, Desync, and server-only showcase"
})

window.ToggleMenu(true)
Notifications:Create({Name = "Bbot Visual Demo loaded"})
