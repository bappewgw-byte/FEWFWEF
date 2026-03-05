-- =========================================
-- GENEROUS HUB - CUSTOM KEY UI
-- Style: Dark Minimalist + Scale Pop-up
-- =========================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================
-- CLEANUP UI LAMA
-- =========================================
if PlayerGui:FindFirstChild("GenerousKeyUI") then
    PlayerGui.GenerousKeyUI:Destroy()
end

-- =========================================
-- VARIABLES (dari main.lua via _G)
-- =========================================
local storedKey = ""
local UI_OPEN = true

-- Ambil fungsi dari _G yang di-set oleh main.lua
local _copyLink   = _G.GenerousUI_copyLink
local _verifyKey  = _G.GenerousUI_verifyKey
local _saveKey    = _G.GenerousUI_saveKey
local _runGame    = _G.GenerousUI_runGame
local _lDigest    = _G.GenerousUI_lDigest
local _getHwid    = _G.GenerousUI_getHwid
local _clipboard  = setclipboard or toclipboard or _G.GenerousUI_clipboard

-- =========================================
-- TWEEN HELPER
-- =========================================
local function tween(obj, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- =========================================
-- NOTIFICATION SYSTEM
-- =========================================
local notifQueue = {}
local notifActive = false

local function showNotif(title, message, color)
    color = color or Color3.fromRGB(255, 255, 255)
    table.insert(notifQueue, {title = title, message = message, color = color})
    
    if notifActive then return end
    notifActive = true
    
    local function processNext()
        if #notifQueue == 0 then notifActive = false return end
        local data = table.remove(notifQueue, 1)
        
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.fromOffset(280, 60)
        NotifFrame.Position = UDim2.new(1, 10, 1, -80)
        NotifFrame.AnchorPoint = Vector2.new(1, 1)
        NotifFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        NotifFrame.BorderSizePixel = 0
        NotifFrame.Parent = PlayerGui.GenerousKeyUI
        Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 8)
        
        -- Left accent bar
        local Accent = Instance.new("Frame")
        Accent.Size = UDim2.new(0, 3, 1, 0)
        Accent.BackgroundColor3 = data.color
        Accent.BorderSizePixel = 0
        Accent.Parent = NotifFrame
        Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 8)

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -20, 0, 20)
        TitleLbl.Position = UDim2.fromOffset(14, 8)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Text = data.title
        TitleLbl.TextColor3 = data.color
        TitleLbl.TextSize = 13
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Parent = NotifFrame

        local MsgLbl = Instance.new("TextLabel")
        MsgLbl.Size = UDim2.new(1, -20, 0, 18)
        MsgLbl.Position = UDim2.fromOffset(14, 30)
        MsgLbl.BackgroundTransparency = 1
        MsgLbl.Text = data.message
        MsgLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
        MsgLbl.TextSize = 11
        MsgLbl.Font = Enum.Font.Gotham
        MsgLbl.TextXAlignment = Enum.TextXAlignment.Left
        MsgLbl.TextTruncate = Enum.TextTruncate.AtEnd
        MsgLbl.Parent = NotifFrame

        -- Slide in
        tween(NotifFrame, { Position = UDim2.new(1, -16, 1, -80) }, 0.4, Enum.EasingStyle.Back)
        
        task.wait(3)
        
        -- Slide out
        local t = tween(NotifFrame, { Position = UDim2.new(1, 10, 1, -80) }, 0.3)
        t.Completed:Connect(function()
            NotifFrame:Destroy()
            task.wait(0.1)
            processNext()
        end)
    end
    
    processNext()
end

-- =========================================
-- MAIN SCREEN GUI
-- =========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GenerousKeyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = PlayerGui

-- Background overlay
local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 1
Overlay.BorderSizePixel = 0
Overlay.Parent = ScreenGui

-- Blur
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = game:GetService("Lighting")

-- =========================================
-- MAIN PANEL
-- =========================================
local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(400, 340)
Panel.Position = UDim2.fromScale(0.5, 0.5)
Panel.AnchorPoint = Vector2.new(0.5, 0.5)
Panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Panel.BorderSizePixel = 0
Panel.Parent = ScreenGui

-- Start small for scale pop-up animation
Panel.Size = UDim2.fromOffset(0, 0)

Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 16)

-- Subtle border
local PanelStroke = Instance.new("UIStroke", Panel)
PanelStroke.Color = Color3.fromRGB(35, 35, 35)
PanelStroke.Thickness = 1

-- =========================================
-- HEADER
-- =========================================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
Header.BorderSizePixel = 0
Header.Parent = Panel
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)

-- Fix bottom corners of header
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0.5, 0)
HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
HeaderFix.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

-- Logo dot accent
local LogoDot = Instance.new("Frame")
LogoDot.Size = UDim2.fromOffset(8, 8)
LogoDot.Position = UDim2.new(0, 20, 0.5, -4)
LogoDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LogoDot.BorderSizePixel = 0
LogoDot.Parent = Header
Instance.new("UICorner", LogoDot).CornerRadius = UDim.new(1, 0)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.fromOffset(36, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = ".Generous"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 40, 1, 0)
VersionLabel.Position = UDim2.new(1, -90, 0, 0)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v0.0.5"
VersionLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
VersionLabel.TextSize = 11
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
VersionLabel.Parent = Header

-- Close Button (X merah)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(100, 100, 100)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Close hover effects
CloseBtn.MouseEnter:Connect(function()
    tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(200, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(30, 30, 30), TextColor3 = Color3.fromRGB(100, 100, 100) }, 0.15)
end)
CloseBtn.MouseButton1Click:Connect(function()
    -- closeUI didefinisikan setelah Panel, pakai task.defer supaya tidak nil
    task.defer(function()
        if closeUI then closeUI() end
    end)
end)

-- =========================================
-- DIVIDER LINE
-- =========================================
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -40, 0, 1)
Divider.Position = UDim2.new(0, 20, 0, 78)
Divider.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Divider.BorderSizePixel = 0
Divider.Parent = Panel

-- =========================================
-- SUBTITLE
-- =========================================
local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, -40, 0, 30)
SubLabel.Position = UDim2.new(0, 20, 0, 88)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "Enter your key to continue"
SubLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
SubLabel.TextSize = 12
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = Panel

-- =========================================
-- KEY INPUT
-- =========================================
local InputContainer = Instance.new("Frame")
InputContainer.Size = UDim2.new(1, -40, 0, 44)
InputContainer.Position = UDim2.new(0, 20, 0, 124)
InputContainer.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
InputContainer.BorderSizePixel = 0
InputContainer.Parent = Panel
Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 10)

local InputStroke = Instance.new("UIStroke", InputContainer)
InputStroke.Color = Color3.fromRGB(30, 30, 30)
InputStroke.Thickness = 1

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -20, 1, 0)
KeyInput.Position = UDim2.fromOffset(16, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Text = ""
KeyInput.PlaceholderText = "Paste your key here..."
KeyInput.PlaceholderColor3 = Color3.fromRGB(50, 50, 50)
KeyInput.TextColor3 = Color3.fromRGB(220, 220, 220)
KeyInput.TextSize = 13
KeyInput.Font = Enum.Font.GothamMedium
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.ClearTextOnFocus = false
KeyInput.Parent = InputContainer

-- Input focus effects
KeyInput.Focused:Connect(function()
    tween(InputStroke, { Color = Color3.fromRGB(80, 80, 80) }, 0.2)
end)
KeyInput.FocusLost:Connect(function()
    tween(InputStroke, { Color = Color3.fromRGB(30, 30, 30) }, 0.2)
    storedKey = KeyInput.Text
end)
KeyInput:GetPropertyChangedSignal("Text"):Connect(function()
    storedKey = KeyInput.Text
end)

-- =========================================
-- VERIFY BUTTON (Primary)
-- =========================================
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(1, -40, 0, 44)
VerifyBtn.Position = UDim2.new(0, 20, 0, 180)
VerifyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.BorderSizePixel = 0
VerifyBtn.Text = "Verify Key"
VerifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
VerifyBtn.TextSize = 14
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.AutoButtonColor = false
VerifyBtn.Parent = Panel
Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 10)

-- Verify hover effects
VerifyBtn.MouseEnter:Connect(function()
    tween(VerifyBtn, { BackgroundColor3 = Color3.fromRGB(210, 210, 210) }, 0.15)
end)
VerifyBtn.MouseLeave:Connect(function()
    tween(VerifyBtn, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
end)
VerifyBtn.MouseButton1Down:Connect(function()
    tween(VerifyBtn, { Size = UDim2.new(1, -44, 0, 40), Position = UDim2.new(0, 22, 0, 182) }, 0.1)
end)
VerifyBtn.MouseButton1Up:Connect(function()
    tween(VerifyBtn, { Size = UDim2.new(1, -40, 0, 44), Position = UDim2.new(0, 20, 0, 180) }, 0.2, Enum.EasingStyle.Back)
end)

-- =========================================
-- BOTTOM ROW BUTTONS
-- =========================================
-- Get Key Button
local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(0.5, -26, 0, 40)
GetKeyBtn.Position = UDim2.new(0, 20, 0, 238)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
GetKeyBtn.BorderSizePixel = 0
GetKeyBtn.Text = "Get Key"
GetKeyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
GetKeyBtn.TextSize = 13
GetKeyBtn.Font = Enum.Font.GothamMedium
GetKeyBtn.AutoButtonColor = false
GetKeyBtn.Parent = Panel
Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 10)

local GetKeyStroke = Instance.new("UIStroke", GetKeyBtn)
GetKeyStroke.Color = Color3.fromRGB(30, 30, 30)
GetKeyStroke.Thickness = 1

-- Copy HWID Button
local HWIDBtn = Instance.new("TextButton")
HWIDBtn.Size = UDim2.new(0.5, -26, 0, 40)
HWIDBtn.Position = UDim2.new(0.5, 6, 0, 238)
HWIDBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
HWIDBtn.BorderSizePixel = 0
HWIDBtn.Text = "Copy HWID"
HWIDBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
HWIDBtn.TextSize = 13
HWIDBtn.Font = Enum.Font.GothamMedium
HWIDBtn.AutoButtonColor = false
HWIDBtn.Parent = Panel
Instance.new("UICorner", HWIDBtn).CornerRadius = UDim.new(0, 10)

local HWIDStroke = Instance.new("UIStroke", HWIDBtn)
HWIDStroke.Color = Color3.fromRGB(30, 30, 30)
HWIDStroke.Thickness = 1

-- Hover effects for secondary buttons
local function secondaryHover(btn, stroke)
    btn.MouseEnter:Connect(function()
        tween(btn, { BackgroundColor3 = Color3.fromRGB(22, 22, 22) }, 0.15)
        tween(stroke, { Color = Color3.fromRGB(55, 55, 55) }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, { BackgroundColor3 = Color3.fromRGB(16, 16, 16) }, 0.15)
        tween(stroke, { Color = Color3.fromRGB(30, 30, 30) }, 0.15)
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, { BackgroundTransparency = 0.3 }, 0.1)
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, { BackgroundTransparency = 0 }, 0.15)
    end)
end

secondaryHover(GetKeyBtn, GetKeyStroke)
secondaryHover(HWIDBtn, HWIDStroke)

-- =========================================
-- FOOTER
-- =========================================
local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(1, -40, 0, 20)
FooterLabel.Position = UDim2.new(0, 20, 0, 306)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "generous.my.id  ·  PlatoBoost Key System"
FooterLabel.TextColor3 = Color3.fromRGB(35, 35, 35)
FooterLabel.TextSize = 10
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.TextXAlignment = Enum.TextXAlignment.Center
FooterLabel.Parent = Panel

-- =========================================
-- OPEN ANIMATION (Scale Pop-up)
-- =========================================
local function openUI()
    tween(Overlay, { BackgroundTransparency = 0.5 }, 0.3)
    tween(Blur, { Size = 16 }, 0.4)
    tween(Panel, { Size = UDim2.fromOffset(420, 340) }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function closeUI()
    tween(Panel, { Size = UDim2.fromOffset(0, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tween(Overlay, { BackgroundTransparency = 1 }, 0.3)
    tween(Blur, { Size = 0 }, 0.3)
    task.wait(0.35)
    ScreenGui:Destroy()
    Blur:Destroy()
end

-- =========================================
-- BUTTON LOGIC
-- =========================================
VerifyBtn.MouseButton1Click:Connect(function()
    if not storedKey or storedKey == "" then
        showNotif("Error", "Please enter your key first", Color3.fromRGB(255, 80, 80))
        tween(InputStroke, { Color = Color3.fromRGB(255, 80, 80) }, 0.2)
        task.wait(1.5)
        tween(InputStroke, { Color = Color3.fromRGB(30, 30, 30) }, 0.3)
        return
    end

    -- Loading state
    VerifyBtn.Text = "Verifying..."
    VerifyBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
    tween(VerifyBtn, { BackgroundColor3 = Color3.fromRGB(180, 180, 180) }, 0.2)

    local isValid = _verifyKey and _verifyKey(storedKey) or false

    if not isValid then
        -- Reset button
        VerifyBtn.Text = "Verify Key"
        VerifyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        tween(VerifyBtn, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)

        -- Shake input
        for i = 1, 4 do
            tween(InputContainer, { Position = UDim2.new(0, 20 + (i % 2 == 0 and 5 or -5), 0, 124) }, 0.05)
            task.wait(0.06)
        end
        tween(InputContainer, { Position = UDim2.new(0, 20, 0, 124) }, 0.1)
        return
    end

    -- SUCCESS
    VerifyBtn.Text = "Access Granted"
    tween(VerifyBtn, { BackgroundColor3 = Color3.fromRGB(50, 200, 100) }, 0.3)
    showNotif("Success", "Key verified! Loading script...", Color3.fromRGB(50, 200, 100))

    if _saveKey then _saveKey(storedKey) end
    task.wait(1)
    closeUI()
    if _runGame then _runGame() end
end)

GetKeyBtn.MouseButton1Click:Connect(function()
    KeyInput:ReleaseFocus()
    game:GetService("RunService").Heartbeat:Wait()
    if _copyLink then
        _copyLink()
        showNotif("Copied!", "Key link copied to clipboard", Color3.fromRGB(255, 255, 255))
    else
        showNotif("Error", "copyLink tidak tersedia", Color3.fromRGB(255, 80, 80))
    end
end)

HWIDBtn.MouseButton1Click:Connect(function()
    -- Release focus dari input supaya tidak ke-paste ke TextBox
    KeyInput:ReleaseFocus()
    game:GetService("RunService").Heartbeat:Wait()

    if _lDigest and _getHwid then
        local myHwid = _lDigest(_getHwid())
        local cb = setclipboard or toclipboard or _clipboard
        if cb then
            pcall(cb, myHwid)
            showNotif("HWID Copied!", "Paste in Discord #donatur-script", Color3.fromRGB(255, 255, 255))
        else
            showNotif("Error", "Clipboard tidak didukung executor ini", Color3.fromRGB(255, 80, 80))
        end
    else
        showNotif("Error", "HWID function tidak tersedia", Color3.fromRGB(255, 80, 80))
    end
end)

-- =========================================
-- PLAY OPEN ANIMATION
-- =========================================
openUI()

-- =========================================
-- RETURN closeUI function untuk dipanggil
-- dari luar jika perlu
-- =========================================
return {
    close = closeUI,
    notify = showNotif
}
