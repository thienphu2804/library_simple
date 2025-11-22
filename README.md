
--SuperLib v5.0.0
--Dev: Phú 
--Loadstring: https://pastebin.com/raw/Vdg5ZXvT
--Dec: this is a lib with any element

local SuperLib = {} SuperLib.__index = SuperLib
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- 8 KEY THEME CHUẨN
local DefaultTheme = {
    TabList   = "#1C1C24",  -- Nền tab list
    EleList   = "#121216",  -- Nền khu vực element
    Text      = "#FFFFFF",  -- Màu chữ
    ToggleOn  = "#648CFF",  -- Toggle bật + tab active + slider fill
    ToggleOff = "#3A3A44",  -- Toggle tắt
    Lable     = "#2D2D3A",  -- Nền Button/Toggle/Input/Label
    Border    = "#FFFFFF",  -- Viền toàn bộ
    Torbar    = "#1C1C24"   -- Thanh topbar
}
local CurrentTheme = DefaultTheme
local Themes = {}

local function HexToColor(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16))
end

local function New(class, props)
    local obj = Instance.new(class)
    for i,v in pairs(props or {}) do pcall(function() obj[i]=v end) end
    return obj
end

local function SafeCorner(obj, r)
    if obj and obj.Parent then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 12)
        c.Parent = obj
    end
end

local function SafeStroke(obj)
    if obj and obj.Parent then
        local s = Instance.new("UIStroke")
        s.Color = HexToColor(CurrentTheme.Border)
        s.Thickness = 1.4
        s.Parent = obj
    end
end

local function GetSafeParent()
    for _, p in {game:GetService("CoreGui"), game.Players.LocalPlayer:WaitForChild("PlayerGui",5)} do
        if pcall(function() Instance.new("Frame").Parent = p end) then return p end
    end
    return game.Players.LocalPlayer:WaitForChild("PlayerGui",10)
end

local function MakeDraggable(point, gui)
    local dragging, startPos
    point.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = gui.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    point.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - UIS:GetMouseLocation() + UIS:GetMouseLocation() - point.AbsolutePosition
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function SuperLib:Win(cfg)
    cfg = cfg or {}
    local Title = cfg.title or "SuperLib V4.1.0"
    local Keybind = cfg.key or Enum.KeyCode.RightControl

    local ScreenGui = New("ScreenGui", {Name="SuperLibV410", ResetOnSpawn=false, Parent=GetSafeParent()})
    local Window = New("Frame", {Size=UDim2.new(0,520,0,360), Position=UDim2.new(0.5,-260,0.5,-180), BackgroundColor3=HexToColor(CurrentTheme.EleList), BorderSizePixel=0, Parent=ScreenGui})
    SafeCorner(Window,18); SafeStroke(Window)

    local TopBar = New("Frame", {Size=UDim2.new(1,0,0,50), BackgroundColor3=HexToColor(CurrentTheme.Torbar), Parent=Window})
    SafeCorner(TopBar,18); MakeDraggable(TopBar, Window)

    New("TextLabel", {Text=Title, Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.GothamBold, TextSize=18, TextXAlignment="Left", Parent=TopBar})

    local Close = New("TextButton", {Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-40,0.5,-15), BackgroundColor3=Color3.fromRGB(220,50,50), Text="×", TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=20, Parent=TopBar})
    SafeCorner(Close,15); Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    UIS.InputBegan:Connect(function(i,g) if not g and i.KeyCode==Keybind then Window.Visible = not Window.Visible end end)

    local TabContainer = New("ScrollingFrame", {Size=UDim2.new(0,150,1,-50), Position=UDim2.new(0,0,0,50), BackgroundColor3=HexToColor(CurrentTheme.TabList), ScrollBarThickness=0, AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=Window})
    SafeCorner(TabContainer,0); SafeStroke(TabContainer)
    New("UIListLayout", {Padding=UDim.new(0,5), Parent=TabContainer})

    local ContentArea = New("ScrollingFrame", {Size=UDim2.new(1,-150,1,-50), Position=UDim2.new(0,150,0,50), BackgroundColor3=HexToColor(CurrentTheme.EleList), ScrollBarThickness=4, ScrollBarImageColor3=HexToColor(CurrentTheme.ToggleOn), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=Window})
    SafeCorner(ContentArea,0); SafeStroke(ContentArea)
    New("UIPadding", {PaddingLeft=UDim.new(0,15), PaddingRight=UDim.new(0,15), PaddingTop=UDim.new(0,15), PaddingBottom=UDim.new(0,15), Parent=ContentArea})
    New("UIListLayout", {Padding=UDim.new(0,10), Parent=ContentArea})

    local tabButtons = {}
    local currentTabContent = nil

    function SuperLib:Tab(name)
        local btn = New("TextButton", {Size=UDim2.new(1,-10,0,40), BackgroundColor3=HexToColor(CurrentTheme.Lable), Text=name, TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.GothamSemibold, TextSize=14, TextXAlignment="Left", Parent=TabContainer})
        SafeCorner(btn,8); SafeStroke(btn)

        local content = New("Frame", {Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, Visible=false, Parent=ContentArea})
        New("UIListLayout", {Padding=UDim.new(0,8), Parent=content})

        tabButtons[name] = {button=btn, content=content}
        btn.MouseButton1Click:Connect(function()
            for _,t in pairs(tabButtons) do t.content.Visible=false; TweenService:Create(t.button,TweenInfo.new(0.2),{BackgroundColor3=HexToColor(CurrentTheme.Lable)}):Play() end
            content.Visible = true; currentTabContent = content
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=HexToColor(CurrentTheme.ToggleOn)}):Play()
        end)
        if not currentTabContent then content.Visible=true; currentTabContent=content; btn.BackgroundColor3=HexToColor(CurrentTheme.ToggleOn) end

        local tab = {}

        -- BUTTON
        function tab:Button(cfg)
            local b = New("TextButton", {Size=UDim2.new(1,0,0,45), BackgroundColor3=HexToColor(CurrentTheme.Lable), Text="  "..(cfg.text or "Button"), TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.GothamSemibold, TextSize=15, TextXAlignment="Left", Parent=content})
            SafeCorner(b,10); SafeStroke(b)
            b.MouseButton1Click:Connect(cfg.callback or function() end)
            return b
        end

        -- TOGGLE
        function tab:Toggle(cfg)
            local frame = New("Frame", {Size=UDim2.new(1,0,0,45), BackgroundColor3=HexToColor(CurrentTheme.Lable), Parent=content})
            SafeCorner(frame,10); SafeStroke(frame)
            New("TextLabel", {Text=cfg.text or "Toggle", Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.GothamSemibold, TextSize=15, TextXAlignment="Left", Parent=frame})

            local btn = New("TextButton", {Size=UDim2.new(0,40,0,24), Position=UDim2.new(1,-50,0.5,-12), BackgroundColor3=(cfg.default and HexToColor(CurrentTheme.ToggleOn) or HexToColor(CurrentTheme.ToggleOff)), Text="", Parent=frame})
            SafeCorner(btn,12)

            local state = cfg.default or false
            local obj = {}
            function obj:Set(v)
                state = v
                TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3 = v and HexToColor(CurrentTheme.ToggleOn) or HexToColor(CurrentTheme.ToggleOff)}):Play()
                (cfg.callback or function() end)(v)
            end
            btn.MouseButton1Click:Connect(function() obj:Set(not state) end)
            obj:Set(state)
            return obj
        end

        -- SLIDER
        function tab:Slider(cfg)
            local min,max,default,dec = cfg.min or 0, cfg.max or 100, cfg.default or 0, cfg.decimal or 0
            local frame = New("Frame", {Size=UDim2.new(1,0,0,60), BackgroundColor3=HexToColor(CurrentTheme.Lable), Parent=content})
            SafeCorner(frame,10); SafeStroke(frame)

            local label = New("TextLabel", {Text=(cfg.text or "Slider")..": "..default, Size=UDim2.new(1,-20,0,25), Position=UDim2.new(0,15,0,5), BackgroundTransparency=1, TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.GothamSemibold, TextSize=15, TextXAlignment="Left", Parent=frame})

            local track = New("Frame", {Size=UDim2.new(1,-30,0,20), Position=UDim2.new(0,15,0,35), BackgroundColor3=HexToColor(CurrentTheme.ToggleOff), Parent=frame})
            SafeCorner(track,10)
            local fill = New("Frame", {Size=UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor ounces=HexToColor(CurrentTheme.ToggleOn), Parent=track})
            SafeCorner(fill,10)

            local value = default; local dragging = false
            local function update(i)
                local percent = math.clamp((i.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                value = dec>0 and (min + (max-min)*percent) or math.floor(min + (max-min)*percent + 0.5)
                value = math.clamp(value,min,max)
                fill.Size = UDim2.new(percent,0,1,0)
                label.Text = (cfg.text or "Slider")..": "..string.format("%."..dec.."f",value)
                (cfg.callback or function() end)(value)
            end
            track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i) end end)
            UIS.InputEnded:Connect(function() dragging=false end)

            local obj = {Set=function(v) value=math.clamp(v,min,max); local p=(value-min)/(max-min); fill.Size=UDim2.new(p,0,1,0); label.Text=(cfg.text or "Slider")..": "..string.format("%."..dec.."f",value); (cfg.callback or function() end)(value) end}
            obj:Set(default:Set(default)
            return obj
        end

        -- INPUT (TextBox)
        function tab:Input(cfg)
            local frame = New("Frame", {Size=UDim2.new(1,0,0,45), BackgroundColor3=HexToColor(CurrentTheme.Lable), Parent=content})
            SafeCorner(frame,10); SafeStroke(frame)
            New("TextLabel", {Text=cfg.text or "Input", Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,15,0,0), BackgroundTransparency=1, TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.GothamSemibold, TextSize=15, TextXAlignment="Left", Parent=frame})

            local box = New("TextBox", {Size=UDim2.new(0,120,0,24), Position=UDim2.new(1,-130,0.5,-12), BackgroundColor3=HexToColor(CurrentTheme.EleList), Text=cfg.default or "", PlaceholderText=cfg.placeholder or "Enter...", TextColor3=HexToColor(CurrentTheme.Text), PlaceholderColor3=Color3.fromRGB(150,150,150), ClearTextOnFocus=false, Parent=frame})
            SafeCorner(box,8); SafeStroke(box)

            box.FocusLost:Connect(function(enter)
                if enter or box.Text ~= (cfg.default or "") then
                    (cfg.callback or function() end)(box.Text)
                end
            end)

            local obj = {Set=function(t) box.Text=t end, Get=function() return box.Text end}
            return obj
        end

        -- LABEL (title + desc)
        function tab:Label(cfg)
            local frame = New("Frame", {Size=UDim2.new(1,0,0,70), BackgroundColor3=HexToColor(CurrentTheme.Lable), Parent=content})
            SafeCorner(frame,10); SafeStroke(frame)
            New("TextLabel", {Text=cfg.title or "Title", Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,15,0,8), BackgroundTransparency=1, TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.GothamBold, TextSize=16, TextXAlignment="Left", Parent=frame})
            New("TextLabel", {Text=cfg.dec or "Description", Size=UDim2.new(1,-20,0,25), Position=UDim2.new(0,15,0,38), BackgroundTransparency=1, TextColor3=Color3.fromRGB(180,180,180), Font=Enum.Font.Gotham, TextSize=13, TextWrapped=true, TextXAlignment="Left", Parent=frame})
            local obj = {Update=function(c) if c.title then frame:FindFirstChild("TextLabel").Text=c.title end if c.dec then frame:FindFirstChildWhichIsA("TextLabel",true).Text=c.dec end end}
            return obj
        end

        -- SIMPLE LABEL
        function tab:SimpleLabel(cfg)
            local l = New("TextLabel", {Size=UDim2.new(1,0,0,50), BackgroundTransparency=1, Text=cfg.text or "Label", TextColor3=HexToColor(CurrentTheme.Text), Font=Enum.Font.Gotham, TextSize=15, TextWrapped=true, TextXAlignment="Left", Parent=content})
            return {Update=function(t) l.Text=t end}
        end

        setmetatable(tab, {__index=SuperLib})
        return tab
    end

    -- THEME SYSTEM PRO
    function win:Theme(name)
        if Themes[name] then return Themes[name] end
        local theme = {Name=name, Colors={}}
        function theme:Create(c) self.Colors=c; print("Theme '"..name.."' created!") return self end
        function theme:Apply()
            CurrentTheme = self.Colors
            Window.BackgroundColor3 = HexToColor(CurrentTheme.EleList)
            TopBar.BackgroundColor3 = HexToColor(CurrentTheme.Torbar)
            TabContainer.BackgroundColor3 = HexToColor(CurrentTheme.TabList)
            ContentArea.BackgroundColor3 = HexToColor(CurrentTheme.EleList)
            ContentArea.ScrollBarImageColor3 = HexToColor(CurrentTheme.ToggleOn)

            for _,obj in pairs(ScreenGui:GetDescendants()) do
                pcall(function()
                    if obj:IsA("UIStroke") then obj.Color = HexToColor(CurrentTheme.Border)
                    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then obj.TextColor3 = HexToColor(CurrentTheme.Text)
                    elseif obj:IsA("Frame") or obj:IsA("TextButton") then
                        if obj.BackgroundColor3 ~= Color3.fromRGB(40,40,40) and obj.Name ~= "Fill" and not string.find(obj:GetFullName(),"toggleBtn") then
                            TweenService:Create(obj,TweenInfo.new(0.2),{BackgroundColor3=HexToColor(CurrentTheme.Lable)}):Play()
                        end
                        if obj.Name=="Fill" then TweenService:Create(obj,TweenInfo.new(0.2),{BackgroundColor3=HexToColor(CurrentTheme.ToggleOn)}):Play() end
                    end
                end)
            end
            if currentTabContent then
                for _,t in pairs(tabButtons) do
                    TweenService:Create(t.button,TweenInfo.new(0.2),{BackgroundColor3 = (t.content==currentTabContent) and HexToColor(CurrentTheme.ToggleOn) or HexToColor(CurrentTheme.Lable)}):Play()
                end
            end
            print("Applied theme: "..name)
        end
        Themes[name] = theme
        return theme
    end

    local win = {Notify=function(c) print("Notify:",c.title or "",c.content or "") end}
    setmetatable(win, {__index=SuperLib})
    return win
end

return SuperLibTheme.B))  
            local label = New("TextLabel", {  
                Text = text .. ": " .. default,  
                Size = UDim2.new(1, -20, 0, 25),  
                Position = UDim2.new(0, 15, 0, 5),  
                BackgroundTransparency = 1,  
                TextColor3 = HexToColor(CurrentTheme.CT),  
                Font = Enum.Font.GothamSemibold,  
                TextSize = 15,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = sliderFrame  
            })  
            local track = New("Frame", {  
                Size = UDim2.new(1, -30, 0, 20),  
                Position = UDim2.new(0, 15, 0, 35),  
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),  
                BorderSizePixel = 0,  
                Parent = sliderFrame  
            })  
            SafeCorner(track, 10)  
            local fill = New("Frame", {  
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),  
                BackgroundColor3 = HexToColor(CurrentTheme.TO),  
                BorderSizePixel = 0,  
                Parent = track  
            })  
            SafeCorner(fill, 10)  
            local value = default  
            local draggingSlider = false  
            local function updateSlider(input)  
                local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)  
                value = decimal > 0 and (min + (max - min) * percent) or math.floor(min + (max - min) * percent + 0.5)  
                value = math.clamp(value, min, max)  
                fill.Size = UDim2.new(percent, 0, 1, 0)  
                label.Text = text .. ": " .. string.format("%." .. decimal .. "f", value)  
                callback(value)  
            end  
            track.InputBegan:Connect(function(input)  
                if input.UserInputType == Enum.UserInputType.MouseButton1 then  
                    draggingSlider = true  
                    updateSlider(input)  
                end  
            end)  
            UIS.InputChanged:Connect(function(input)  
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then  
                    updateSlider(input)  
                end  
            end)  
            UIS.InputEnded:Connect(function(input)  
                if input.UserInputType == Enum.UserInputType.MouseButton1 then  
                    draggingSlider = false  
                end  
            end)  
            local sliderObj = {}  
            function sliderObj:Set(val)  
                value = math.clamp(val, min, max)  
                local percent = (value - min) / (max - min)  
                fill.Size = UDim2.new(percent, 0, 1, 0)  
                label.Text = text .. ": " .. string.format("%." .. decimal .. "f", value)  
                callback(value)  
            end  
            sliderObj:Set(default)  
            return sliderObj  
        end  
        -- NEW & FIXED: Input Component 
        function tab:Input(cfg) 
            local text = cfg.text or "Input Field" 
            local placeholder = cfg.placeholder or "Nhập text..." 
            local default = cfg.default or "" 
            local callback = cfg.callback or function() end 
            local inputFrame = New("Frame", { 
                Size = UDim2.new(1, 0, 0, 45), 
                BackgroundColor3 = HexToColor(CurrentTheme.CBG), 
                BorderSizePixel = 0, 
                Parent = tabContent 
            }) 
            SafeCorner(inputFrame, 10) 
            SafeStroke(inputFrame, HexToColor(CurrentTheme.B)) 
            New("TextLabel", { 
                Text = text, 
                Size = UDim2.new(1, -70, 1, 0), 
                Position = UDim2.new(0, 15, 0, 0), 
                BackgroundTransparency = 1, 
                TextColor3 = HexToColor(CurrentTheme.CT), 
                Font = Enum.Font.GothamSemibold, 
                TextSize = 15, 
                TextXAlignment = Enum.TextXAlignment.Left, 
                Parent = inputFrame 
            }) 
            local textBox = New("TextBox", { 
                Size = UDim2.new(0, 50, 0, 24), 
                Position = UDim2.new(1, -60, 0.5, -12), 
                BackgroundColor3 = Color3.fromRGB(40, 40, 40), -- Màu nền cho textbox 
                Text = default, 
                PlaceholderText = placeholder, 
                PlaceholderColor3 = Color3.fromRGB(150, 150, 150), 
                TextColor3 = HexToColor(CurrentTheme.CT), 
                Font = Enum.Font.Gotham, 
                TextSize = 12, 
                TextXAlignment = Enum.TextXAlignment.Center, 
                ClearTextOnFocus = false, 
                MultiLine = false, 
                BorderSizePixel = 0, 
                Parent = inputFrame 
            }) 
            SafeCorner(textBox, 8) 
            SafeStroke(textBox, HexToColor(CurrentTheme.B)) 
            -- FIX: Xử lý InputBegan cho Enter key 
            textBox.InputBegan:Connect(function(input) 
                if input.KeyCode == Enum.KeyCode.Return then 
                    local inputText = textBox.Text 
                    pcall(callback, inputText) 
                    textBox:ReleaseFocus() -- Buộc mất focus sau khi nhấn Enter 
                    DebugPrint("Input: Callback triggered by Enter for '" .. inputText .. "'") 
                end 
            end) 
            -- FIX: Xử lý FocusLost. Chỉ gọi callback nếu không phải do Enter (đã xử lý ở trên) 
            -- và nếu text có thay đổi so với default ban đầu hoặc có giá trị. 
            textBox.FocusLost:Connect(function(enterPressed) 
                if not enterPressed then -- Nếu không phải do Enter (đã xử lý ở InputBegan) 
                    local inputText = textBox.Text 
                    if inputText ~= default then -- Kiểm tra nếu text có thay đổi 
                        pcall(callback, inputText) 
                        DebugPrint("Input: Callback triggered by FocusLost for '" .. inputText .. "'") 
                    end 
                end 
            end) 
            local inputObj = {} 
            function inputObj:Set(value) 
                textBox.Text = value or "" 
            end 
            function inputObj:Get() 
                return textBox.Text 
            end 
            inputObj:Set(default) 
            return inputObj 
        end 
        -- END NEW & FIXED: Input Component 
        -- Refactored from 'Lable' to 'Label' for consistency with common English 
        function tab:Label(cfg)  
            -- Cấu trúc cũ của Lable, nay đổi tên thành Label để đồng bộ 
            -- Và thêm một trường 'type' để phân biệt với Label đơn giản nếu cần. 
            local title = cfg.title or "Title"  
            local dec = cfg.dec or "Description"  
            local labelFrame = New("Frame", {  
                Size = UDim2.new(1, 0, 0, 70),  
                BackgroundColor3 = HexToColor(CurrentTheme.BGL),  
                BorderSizePixel = 0,  
                Parent = tabContent  
            })  
            SafeCorner(labelFrame, 10)  
            SafeStroke(labelFrame, HexToColor(CurrentTheme.B))  
            local titleLabel = New("TextLabel", {  
                Text = title,  
                Size = UDim2.new(1, -20, 0, 30),  
                Position = UDim2.new(0, 15, 0, 8),  
                BackgroundTransparency = 1,  
                TextColor3 = HexToColor(CurrentTheme.CT),  
                Font = Enum.Font.GothamBold,  
                TextSize = 16,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = labelFrame  
            })  
            local descLabel = New("TextLabel", {  
                Text = dec,  
                Size = UDim2.new(1, -20, 0, 25),  
                Position = UDim2.new(0, 15, 0, 38),  
                BackgroundTransparency = 1,  
                TextColor3 = Color3.fromRGB(180, 180, 180),  
                Font = Enum.Font.Gotham,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                TextWrapped = true,  
                Parent = labelFrame  
            })  
            local labelObj = {}  
            function labelObj:Update(cfg)  
                if cfg.title then titleLabel.Text = cfg.title end  
                if cfg.dec then descLabel.Text = cfg.dec end  
            end  
            return labelObj  
        end  
        -- Original simple Label function 
        function tab:SimpleLabel(cfg) -- Đổi tên để tránh trùng với Label có title/desc 
            local l = New("TextLabel", {  
                Size = UDim2.new(1, 0, 0, 50),  
                BackgroundTransparency = 1,  
                Text = cfg.text or "Label",  
                TextColor3 = HexToColor(CurrentTheme.CT),  
                Font = Enum.Font.Gotham,  
                TextSize = 15,  
                TextWrapped = true,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = tabContent  
            })  
            return {Update = function(t) if l then l.Text = t end end}  
        end  
        setmetatable(tab, {__index = SuperLib})  
        return tab  
    end  
    local win = {  
        Notify = function(cfg)  
            DebugPrint("🔔 " .. (cfg.title or "Alert") .. ": " .. (cfg.content or "No content")) 
            -- Có thể phát triển thành GUI notification pop-up sau 
        end,  
        Theme = function(theme)  
            if type(theme) == "table" then  
                local oldTheme = CurrentTheme -- Lưu theme cũ để so sánh nếu cần 
                CurrentTheme = theme -- Cập nhật CurrentTheme trước tiên 
                DebugPrint("Bắt đầu cập nhật theme...") 
                -- Cập nhật màu của các frame chính của cửa sổ 
                Window.BackgroundColor3 = HexToColor(CurrentTheme.BG) 
                TopBar.BackgroundColor3 = HexToColor(CurrentTheme.BGT) 
                TabContainer.BackgroundColor3 = HexToColor(CurrentTheme.BGT) 
                ContentArea.BackgroundColor3 = HexToColor(CurrentTheme.BGE) 
                ContentArea.ScrollBarImageColor3 = HexToColor(CurrentTheme.CS) 
                -- Duyệt qua TẤT CẢ các thành phần con để cập nhật màu 
                -- Sử dụng ScreenGui:GetDescendants() để đảm bảo bao phủ hết 
                for _, obj in pairs(ScreenGui:GetDescendants()) do  
                    if obj:IsA("UIStroke") then  
                        obj.Color = HexToColor(CurrentTheme.B)  
                    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then 
                        -- Cập nhật màu text chung 
                        -- Nếu màu text không phải là màu lỗi hoặc màu tạm thời (ví dụ: placeholder), thì cập nhật 
                        if obj.TextColor3 ~= Color3.new(1,1,1) then -- Tránh cập nhật màu lỗi default 
                            obj.TextColor3 = HexToColor(CurrentTheme.CT) 
                        end 
                        -- Cập nhật PlaceholderColor3 cho TextBox 
                        if obj:IsA("TextBox") then 
                            obj.PlaceholderColor3 = Color3.fromRGB(150, 150, 150) -- Giữ màu này cố định cho placeholder 
                        end 
                        if obj:IsA("TextButton") then 
                            -- Cập nhật màu nền cho các button, đặc biệt là nút tab 
                            local isCurrentTab = false 
                            if currentTabContent and obj.Parent == TabContainer then -- Nếu là nút tab 
                                for _, tabData in pairs(tabButtons) do 
                                    if tabData.button == obj and tabData.content == currentTabContent then 
                                        isCurrentTab = true 
                                        break 
                                    end 
                                end 
                            end 
                            if isCurrentTab then 
                                TweenService:Create(obj, TweenInfo.new(0.1), { 
                                    BackgroundColor3 = HexToColor(CurrentTheme.TO) -- Màu cho tab đang chọn 
                                }):Play() 
                            else 
                                TweenService:Create(obj, TweenInfo.new(0.1), { 
                                    BackgroundColor3 = HexToColor(CurrentTheme.CBG) -- Màu cho các button/tab không chọn 
                                }):Play() 
                            end 
                        end 
                    elseif obj:IsA("Frame") then 
                        -- Cập nhật màu nền của các frame con (toggle, slider, input, label frames) 
                        -- Cần kiểm tra màu nền hiện tại để tránh thay đổi màu của các UI không liên quan (ví dụ: hình ảnh) 
                        if obj.BackgroundColor3 == HexToColor(oldTheme.CBG) or 
                           obj.BackgroundColor3 == HexToColor(oldTheme.BGL) or 
                           obj.BackgroundColor3 == Color3.fromRGB(40,40,40) or -- Màu nền của textbox 
                           obj.BackgroundColor3 == Color3.fromRGB(50,50,50) -- Màu nền của track slider 
                        then 
                            -- Logic đặc biệt cho các thanh fill của slider 
                            if obj.Name == "Fill" and obj.Parent.Name == "track" then -- Thanh fill của slider 
                                TweenService:Create(obj, TweenInfo.new(0.1), { 
                                    BackgroundColor3 = HexToColor(CurrentTheme.TO) -- Màu cho thanh fill 
                                }):Play() 
                            else 
                                TweenService:Create(obj, TweenInfo.new(0.1), { 
                                    BackgroundColor3 = HexToColor(CurrentTheme.CBG) -- Màu nền chung cho các frame 
                                }):Play() 
                            end 
                        end 
                    end 
                end  
                -- Sau khi duyệt và cập nhật chung, force re-apply màu cho tab hiện tại và các tab khác 
                -- Điều này sẽ đảm bảo tab đang chọn có màu TO và các tab khác có màu CBG một cách chính xác 
                if currentTabContent then 
                    for name, tabData in pairs(tabButtons) do 
                        if tabData.content == currentTabContent then 
                            TweenService:Create(tabData.button, TweenInfo.new(0.1), { 
                                BackgroundColor3 = HexToColor(CurrentTheme.TO) 
                            }):Play() 
                        else 
                            TweenService:Create(tabData.button, TweenInfo.new(0.1), { 
                                BackgroundColor3 = HexToColor(CurrentTheme.CBG) 
                            }):Play() 
                        end 
                    end 
                end 
                DebugPrint("Chủ đề đã được cập nhật hoàn chỉnh!") 
            end  
        end  
    }  
    setmetatable(win, {__index = SuperLib})  
    return win  
end  
return SuperLib Lib})  
    return win  
end  
return SuperLib 