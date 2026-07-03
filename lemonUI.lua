--[[
    ═══════════════════════════════════════════════════════
      LEMON UI MODDED 
      Standalone UI library (extracted from Lemon Hub style)
      Usage:
        local UI = loadstring(game:HttpGet("<raw github url>"))()
        local Window = UI:CreateWindow({ Title = "Generous Hub", SubTitle = "v1.0" })
        local Tab = Window:CreateTab("Farm", "sprout")
        Tab:CreateToggle({ Title = "Auto Farm", Flag = "autoFarm", Default = false,
            Callback = function(v) end })
    ═══════════════════════════════════════════════════════
]]

local Library = {}
Library.__index = Library

-- ══════════════ Services ══════════════
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")

local LP = Players.LocalPlayer

-- ══════════════ Default theme ══════════════
local DEFAULT_THEME = {
    Bg        = Color3.fromRGB(12, 14, 18),
    Surface   = Color3.fromRGB(19, 22, 29),
    Elevated  = Color3.fromRGB(28, 32, 42),
    Elevated2 = Color3.fromRGB(36, 41, 53),
    Stroke    = Color3.fromRGB(255, 255, 255),
    Text      = Color3.fromRGB(233, 236, 244),
    TextDim   = Color3.fromRGB(136, 145, 164),
    TextFaint = Color3.fromRGB(90, 98, 115),
    Accent    = Color3.fromRGB(250, 204, 21),
    AccentTxt = Color3.fromRGB(28, 23, 5),
    Green     = Color3.fromRGB(74, 222, 128),
    Red       = Color3.fromRGB(248, 113, 113),
    Violet    = Color3.fromRGB(167, 139, 250),
    Blue      = Color3.fromRGB(96, 165, 250),
}
local FONT_B, FONT_M, FONT_R = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.Gotham
local TI_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_POP  = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ══════════════ Small helpers ══════════════
local function mk(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end
local function corner(r) return mk("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function tween(inst, ti, props)
    local tw = TweenService:Create(inst, ti, props)
    tw:Play()
    return tw
end

-- ══════════════ CreateWindow ══════════════
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local T = {}
    for k, v in pairs(DEFAULT_THEME) do T[k] = v end
    if cfg.Theme then for k, v in pairs(cfg.Theme) do T[k] = v end end
    if cfg.ThemeColor then T.Accent = cfg.ThemeColor end

    local alive = true
    local connections = {}
    local function track(con) table.insert(connections, con) return con end

    local function stroke(transp, color)
        return mk("UIStroke", {
            Color = color or T.Stroke, Transparency = transp or 0.92, Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    end
    local function pad(t, r, b, l)
        return mk("UIPadding", {
            PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or t),
            PaddingBottom = UDim.new(0, b or t), PaddingLeft = UDim.new(0, l or r or t),
        })
    end

    -- Async Lucide icons: UI builds immediately, icons pop in once loaded
    local Lucide = nil
    local pendingIcons = {}
    local function applyIcon(img, name)
        if not Lucide then return end
        local ok, a = pcall(Lucide.GetAsset, name, 48)
        if ok and a then
            img.Image = a.Url
            img.ImageRectOffset = a.ImageRectOffset
            img.ImageRectSize = a.ImageRectSize
        end
    end
    task.spawn(function()
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet(
                "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"))()
        end)
        if ok and lib then
            Lucide = lib
            for img, name in pairs(pendingIcons) do
                if img.Parent then applyIcon(img, name) end
            end
            pendingIcons = {}
        end
    end)
    local function icon(name, size, color, parent)
        local img = mk("ImageLabel", {
            BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size),
            ImageColor3 = color or T.Text, ScaleType = Enum.ScaleType.Fit, Parent = parent,
        })
        if Lucide then applyIcon(img, name) else pendingIcons[img] = name end
        return img
    end

    -- Flags / config persistence
    local Flags = {}
    local FlagObjects = {}
    local configFile = cfg.ConfigFile or ((cfg.Title or "GenerousUI"):gsub("%s+", "") .. ".json")
    local saveQueued = false
    local function loadConfig()
        pcall(function()
            if readfile and isfile and isfile(configFile) then
                local data = HttpService:JSONDecode(readfile(configFile))
                for k, v in pairs(data) do Flags[k] = v end
            end
        end)
    end
    local function saveConfig()
        pcall(function()
            if writefile then writefile(configFile, HttpService:JSONEncode(Flags)) end
        end)
    end
    local function queueSave()
        if saveQueued then return end
        saveQueued = true
        task.delay(1, function() saveQueued = false saveConfig() end)
    end
    if cfg.AutoSave ~= false then loadConfig() end

    -- ScreenGui
    local pg = LP:WaitForChild("PlayerGui")
    local gui = mk("ScreenGui", {
        Name = cfg.Name or "GenerousUI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, Parent = pg,
    })

    -- Toasts
    local toastHolder = mk("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(272, 400),
        Parent = gui,
    }, {
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    local toastOrder = 0
    local function notify(opts)
        opts = opts or {}
        if not alive then return end
        toastOrder += 1
        local card = mk("Frame", {
            BackgroundColor3 = T.Surface, Size = UDim2.new(1, 40, 0, 58),
            LayoutOrder = toastOrder, ClipsDescendants = true, Parent = toastHolder,
        }, { corner(10), stroke(0.88), pad(10, 12, 10, 12) })
        local ic = icon(opts.Icon or "bell", 22, opts.Color or T.Accent, card)
        ic.Position = UDim2.fromOffset(0, 7)
        mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_B, Text = opts.Title or "", TextSize = 13,
            TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(34, 2), Size = UDim2.new(1, -34, 0, 16), Parent = card,
        })
        mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_R, Text = opts.Desc or "", TextSize = 12,
            TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.fromOffset(34, 20), Size = UDim2.new(1, -34, 0, 16), Parent = card,
        })
        card.BackgroundTransparency = 1
        tween(card, TI_MED, { Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 0 })
        task.delay(opts.Duration or 4, function()
            if card.Parent then
                tween(card, TI_MED, { Size = UDim2.new(1, 40, 0, 58), BackgroundTransparency = 1 })
                task.wait(0.25)
                card:Destroy()
            end
        end)
    end

    -- Main window
    local WIN_W, WIN_H = cfg.Width or 680, cfg.Height or 440
    local win = mk("Frame", {
        Name = "Window", BackgroundColor3 = T.Bg, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WIN_W, WIN_H),
        ClipsDescendants = true, Parent = gui,
    }, { corner(14), stroke(0.9) })

    local topbar = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = win })
    local titleIcon = icon(cfg.Icon or "layout-dashboard", 20, T.Accent, topbar)
    titleIcon.Position = UDim2.fromOffset(18, 14)
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_B, Text = cfg.Title or "Generous Hub", TextSize = 15,
        TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(46, 8), Size = UDim2.fromOffset(220, 18), Parent = topbar,
    })
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_R, Text = cfg.SubTitle or "", TextSize = 11,
        TextColor3 = T.TextFaint, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(46, 26), Size = UDim2.fromOffset(220, 14), Parent = topbar,
    })

    local statusDot = mk("Frame", {
        BackgroundColor3 = T.TextFaint, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -160, 0.5, 0), Size = UDim2.fromOffset(8, 8), Parent = topbar,
    }, { corner(4) })
    local statusLbl = mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_M, Text = "ready", TextSize = 11,
        TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -96, 0.5, 0),
        Size = UDim2.fromOffset(52, 14), Parent = topbar,
    })

    local function winButton(iconName, xOff)
        local btn = mk("TextButton", {
            BackgroundColor3 = T.Surface, Text = "", AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0),
            Size = UDim2.fromOffset(28, 28), Parent = topbar,
        }, { corner(8) })
        local ic = icon(iconName, 14, T.TextDim, btn)
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        track(btn.MouseEnter:Connect(function()
            tween(btn, TI_FAST, { BackgroundColor3 = T.Elevated })
            tween(ic, TI_FAST, { ImageColor3 = T.Text })
        end))
        track(btn.MouseLeave:Connect(function()
            tween(btn, TI_FAST, { BackgroundColor3 = T.Surface })
            tween(ic, TI_FAST, { ImageColor3 = T.TextDim })
        end))
        return btn
    end
    local minBtn = winButton("minus", -52)
    local closeBtn = winButton("x", -16)

    local function makeDraggable(handle, target)
        local dragging, dragStart, startPos = false, nil, nil
        track(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true dragStart = input.Position startPos = target.Position
            end
        end))
        track(handle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
    end
    makeDraggable(topbar, win)

    -- Sidebar / tabs
    local sidebar = mk("Frame", {
        BackgroundColor3 = T.Surface, Position = UDim2.fromOffset(10, 56),
        Size = UDim2.fromOffset(150, WIN_H - 56 - 10), Parent = win,
    }, { corner(12), stroke(0.94) })
    mk("TextLabel", {
        BackgroundTransparency = 1, Font = FONT_R, TextSize = 10,
        Text = LP.Name, TextColor3 = T.TextFaint, TextTruncate = Enum.TextTruncate.AtEnd,
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
        Size = UDim2.new(1, -20, 0, 12), Parent = sidebar,
    })
    local content = mk("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(170, 56),
        Size = UDim2.new(1, -180, 1, -66), Parent = win,
    })

    local tabs, tabOrder, activeTab = {}, 0, nil
    local tabIndicator = mk("Frame", {
        BackgroundColor3 = T.Accent, Size = UDim2.fromOffset(3, 20),
        Position = UDim2.fromOffset(0, 14), Parent = sidebar, Visible = false,
    }, { corner(2) })

    local function makePage()
        return mk("ScrollingFrame", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = T.Elevated2,
            BorderSizePixel = 0, Visible = false, Parent = content,
        }, {
            mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
            pad(2, 6, 12, 2),
        })
    end

    -- ══════════════ Row/control builders (shared by all tabs) ══════════════
    local function sectionLabel(page, text)
        mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_B, Text = string.upper(text), TextSize = 10,
            TextColor3 = T.TextFaint, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 18), Parent = page,
        })
    end
    local function baseRow(page, height)
        return mk("Frame", {
            BackgroundColor3 = T.Surface, Size = UDim2.new(1, 0, 0, height or 54), Parent = page,
        }, { corner(10), stroke(0.94) })
    end
    local function rowHeader(row, opt)
        local iconBg = mk("Frame", {
            BackgroundColor3 = T.Elevated, Position = UDim2.fromOffset(12, 11),
            Size = UDim2.fromOffset(32, 32), Parent = row,
        }, { corner(8) })
        local ic = icon(opt.Icon or "circle", 17, opt.Danger and T.Red or T.TextDim, iconBg)
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_M, Text = opt.Title or "", TextSize = 13,
            TextColor3 = opt.Danger and T.Red or T.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(54, 10), Size = UDim2.new(1, -120, 0, 16), Parent = row,
        })
        mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_R, Text = opt.Desc or "", TextSize = 11,
            TextColor3 = T.TextFaint, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.fromOffset(54, 28), Size = UDim2.new(1, -120, 0, 14), Parent = row,
        })
        return iconBg, ic
    end

    local function CreateToggle(page, opt)
        opt = opt or {}
        local flag = opt.Flag
        if flag and Flags[flag] == nil then Flags[flag] = opt.Default or false end
        local getV = function() return flag and Flags[flag] or (opt._v or false) end
        local setV0 = function(v) if flag then Flags[flag] = v else opt._v = v end end

        local row = baseRow(page)
        local iconBg, ic = rowHeader(row, opt)
        local onColor = opt.Danger and T.Red or T.Accent

        local pill = mk("Frame", {
            BackgroundColor3 = T.Elevated2, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(40, 22), Parent = row,
        }, { corner(11) })
        local knob = mk("Frame", {
            BackgroundColor3 = Color3.fromRGB(200, 205, 215), Position = UDim2.fromOffset(3, 3),
            Size = UDim2.fromOffset(16, 16), Parent = pill,
        }, { corner(8) })

        local function render(v, instant)
            local ti = instant and TweenInfo.new(0) or TI_MED
            tween(pill, ti, { BackgroundColor3 = v and onColor or T.Elevated2 })
            tween(knob, ti, {
                Position = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = v and (opt.Danger and Color3.fromRGB(255, 235, 235) or T.AccentTxt) or Color3.fromRGB(200, 205, 215),
            })
            tween(ic, ti, { ImageColor3 = v and onColor or (opt.Danger and T.Red or T.TextDim) })
        end
        render(getV(), true)

        local confirmed = false
        local function set(v)
            if opt.Confirm and v and not confirmed then
                confirmed = true
                notify({ Title = "Are you sure?", Desc = "Klik lagi dalam 3s buat aktifin " .. (opt.Title or ""), Icon = "triangle-alert", Color = T.Red })
                task.delay(3, function() confirmed = false end)
                return
            end
            setV0(v)
            render(v)
            if cfg.AutoSave ~= false and flag then queueSave() end
            if opt.Callback then opt.Callback(v) end
        end

        local hit = mk("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = row })
        track(hit.MouseButton1Click:Connect(function() set(not getV()) end))
        track(hit.MouseEnter:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Elevated }) end))
        track(hit.MouseLeave:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Surface }) end))

        local obj = { Set = set, Get = getV }
        if flag then FlagObjects[flag] = obj end
        return obj
    end

    local function CreateSlider(page, opt)
        opt = opt or {}
        local flag = opt.Flag
        if flag and Flags[flag] == nil then Flags[flag] = opt.Default or opt.Min or 0 end
        local getV = function() return flag and Flags[flag] or (opt._v or opt.Min or 0) end
        local setV0 = function(v) if flag then Flags[flag] = v else opt._v = v end end

        local row = baseRow(page, 68)
        rowHeader(row, opt)
        local valLbl = mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_B, TextSize = 12, TextColor3 = T.Accent,
            Text = tostring(getV()), TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12),
            Size = UDim2.fromOffset(80, 16), Parent = row,
        })
        local trackBar = mk("Frame", {
            BackgroundColor3 = T.Elevated2, Position = UDim2.fromOffset(54, 50),
            Size = UDim2.new(1, -70, 0, 5), Parent = row,
        }, { corner(3) })
        local fill = mk("Frame", { BackgroundColor3 = T.Accent, Size = UDim2.fromScale(0, 1), Parent = trackBar }, { corner(3) })
        local knob = mk("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(13, 13), Parent = trackBar,
        }, { corner(7), mk("UIStroke", { Color = T.Stroke, Transparency = 0.7, Thickness = 1 }) })

        local min, max = opt.Min or 0, opt.Max or 100
        local function render(v)
            local a = (v - min) / (max - min)
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            valLbl.Text = tostring(v) .. (opt.Suffix or "")
        end
        render(getV())

        local dragging = false
        local function applyFromX(x)
            local a = math.clamp((x - trackBar.AbsolutePosition.X) / trackBar.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + a * (max - min) + 0.5)
            if v ~= getV() then
                setV0(v) render(v)
                if cfg.AutoSave ~= false and flag then queueSave() end
                if opt.Callback then opt.Callback(v) end
            end
        end
        local hit = mk("TextButton", {
            BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(48, 38),
            Size = UDim2.new(1, -58, 0, 26), Parent = row,
        })
        track(hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true applyFromX(input.Position.X)
            end
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then applyFromX(input.Position.X) end
        end))

        local obj = { Set = function(v) setV0(v) render(v) end, Get = getV }
        if flag then FlagObjects[flag] = obj end
        return obj
    end

    local function CreateButton(page, opt)
        opt = opt or {}
        local row = baseRow(page)
        rowHeader(row, opt)
        local hit = mk("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = row })
        track(hit.MouseButton1Click:Connect(function() if opt.Callback then opt.Callback() end end))
        track(hit.MouseEnter:Connect(function()
            tween(row, TI_FAST, { BackgroundColor3 = opt.Danger and Color3.fromRGB(60, 25, 25) or T.Elevated })
        end))
        track(hit.MouseLeave:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Surface }) end))
        return { Row = row }
    end

    local function CreateDropdown(page, opt)
        opt = opt or {}
        local flag = opt.Flag
        local options = opt.Options or {}
        if flag and Flags[flag] == nil then Flags[flag] = opt.Default or options[1] end
        local getV = function() return flag and Flags[flag] or (opt._v or opt.Default or options[1]) end
        local setV0 = function(v) if flag then Flags[flag] = v else opt._v = v end end

        local row = baseRow(page, 54)
        rowHeader(row, opt)
        local valLbl = mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_B, TextSize = 12, TextColor3 = T.Accent,
            Text = tostring(getV() or "—"), TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(140, 16), Parent = row,
        })
        local idx = table.find(options, getV()) or 1
        local function set(i)
            idx = i
            local v = options[idx]
            setV0(v)
            valLbl.Text = tostring(v)
            if cfg.AutoSave ~= false and flag then queueSave() end
            if opt.Callback then opt.Callback(v) end
        end
        local hit = mk("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = row })
        track(hit.MouseButton1Click:Connect(function()
            if #options == 0 then return end
            set((idx % #options) + 1)
        end))
        track(hit.MouseEnter:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Elevated }) end))
        track(hit.MouseLeave:Connect(function() tween(row, TI_FAST, { BackgroundColor3 = T.Surface }) end))

        local obj = { Set = function(v) set(table.find(options, v) or 1) end, Get = getV }
        if flag then FlagObjects[flag] = obj end
        return obj
    end

    -- ══════════════ Tab object ══════════════
    local function CreateTab(self, name, iconName)
        tabOrder += 1
        local order = tabOrder
        local page = makePage()
        local btn = mk("TextButton", {
            BackgroundColor3 = T.Surface, BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false, Position = UDim2.fromOffset(8, 12 + (order - 1) * 42),
            Size = UDim2.new(1, -16, 0, 36), Parent = sidebar,
        }, { corner(9) })
        local ic = icon(iconName or "circle", 17, T.TextDim, btn)
        ic.Position = UDim2.fromOffset(11, 9)
        local lbl = mk("TextLabel", {
            BackgroundTransparency = 1, Font = FONT_M, Text = name, TextSize = 13,
            TextColor3 = T.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -38, 1, 0), Parent = btn,
        })
        local tab = { name = name, page = page, btn = btn, ic = ic, lbl = lbl, order = order }
        table.insert(tabs, tab)

        local function select()
            for _, t2 in ipairs(tabs) do
                t2.page.Visible = false
                tween(t2.btn, TI_FAST, { BackgroundTransparency = 1 })
                tween(t2.ic, TI_FAST, { ImageColor3 = T.TextDim })
                tween(t2.lbl, TI_FAST, { TextColor3 = T.TextDim })
            end
            activeTab = tab
            page.Visible = true
            tween(btn, TI_FAST, { BackgroundTransparency = 0, BackgroundColor3 = T.Elevated })
            tween(ic, TI_FAST, { ImageColor3 = T.Accent })
            tween(lbl, TI_FAST, { TextColor3 = T.Text })
            tabIndicator.Visible = true
            tween(tabIndicator, TI_MED, { Position = UDim2.fromOffset(0, 12 + (order - 1) * 42 + 8) })
        end
        track(btn.MouseButton1Click:Connect(select))
        track(btn.MouseEnter:Connect(function()
            if activeTab ~= tab then tween(btn, TI_FAST, { BackgroundTransparency = 0.5, BackgroundColor3 = T.Elevated }) end
        end))
        track(btn.MouseLeave:Connect(function()
            if activeTab ~= tab then tween(btn, TI_FAST, { BackgroundTransparency = 1 }) end
        end))

        if #tabs == 1 then select() end

        return {
            Select = select,
            CreateSection = function(self, text) sectionLabel(page, text) end,
            CreateToggle = function(self, o) return CreateToggle(page, o) end,
            CreateSlider = function(self, o) return CreateSlider(page, o) end,
            CreateButton = function(self, o) return CreateButton(page, o) end,
            CreateDropdown = function(self, o) return CreateDropdown(page, o) end,
        }
    end

    -- Minimize bubble
    local bubble = mk("TextButton", {
        BackgroundColor3 = T.Accent, Text = "", AutoButtonColor = false, Visible = false,
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0),
        Size = UDim2.fromOffset(48, 48), Parent = gui,
    }, { corner(24), mk("UIStroke", { Color = T.Stroke, Transparency = 0.6, Thickness = 1 }) })
    local bubbleIc = icon(cfg.Icon or "layout-dashboard", 24, T.AccentTxt, bubble)
    bubbleIc.AnchorPoint = Vector2.new(0.5, 0.5)
    bubbleIc.Position = UDim2.fromScale(0.5, 0.5)
    makeDraggable(bubble, bubble)

    local minimized = false
    local function setMinimized(v)
        minimized = v
        if v then
            tween(win, TI_MED, { Size = UDim2.fromOffset(WIN_W, 0) })
            task.delay(0.2, function() if minimized then win.Visible = false end end)
            bubble.Visible = true
            bubble.Size = UDim2.fromOffset(0, 0)
            tween(bubble, TI_POP, { Size = UDim2.fromOffset(48, 48) })
        else
            win.Visible = true
            tween(win, TI_POP, { Size = UDim2.fromOffset(WIN_W, WIN_H) })
            bubble.Visible = false
        end
    end
    track(minBtn.MouseButton1Click:Connect(function() setMinimized(true) end))
    track(closeBtn.MouseButton1Click:Connect(function()
        alive = false
        for _, con in ipairs(connections) do pcall(function() con:Disconnect() end) end
        pcall(function() gui:Destroy() end)
        if cfg.OnClose then pcall(cfg.OnClose) end
    end))
    local bubbleDownPos
    track(bubble.MouseButton1Down:Connect(function(x, y) bubbleDownPos = Vector2.new(x, y) end))
    track(bubble.MouseButton1Up:Connect(function(x, y)
        if bubbleDownPos and (Vector2.new(x, y) - bubbleDownPos).Magnitude < 6 then setMinimized(false) end
    end))
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            if minimized then setMinimized(false) else gui.Enabled = not gui.Enabled end
        end
    end))

    win.Size = UDim2.fromOffset(WIN_W, 0)
    tween(win, TI_POP, { Size = UDim2.fromOffset(WIN_W, WIN_H) })

    local Window = {
        CreateTab = CreateTab,
        Notify = function(_, opts) notify(opts) end,
        SetStatus = function(_, text, active)
            statusLbl.Text = text
            statusDot.BackgroundColor3 = active and T.Green or T.TextFaint
        end,
        Flags = Flags,
        SetFlag = function(_, key, value)
            Flags[key] = value
            if FlagObjects[key] then FlagObjects[key].Set(value) end
            if cfg.AutoSave ~= false then queueSave() end
        end,
        GetFlag = function(_, key) return Flags[key] end,
        Minimize = function(_, v) setMinimized(v) end,
        Destroy = function()
            alive = false
            for _, con in ipairs(connections) do pcall(function() con:Disconnect() end) end
            pcall(function() gui:Destroy() end)
        end,
    }
    return Window
end

return Library
