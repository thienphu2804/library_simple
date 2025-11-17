-- Beautiful Exploiting GUI Library (Lua for Roblox)
-- This is a simple, customizable GUI library for creating exploiting interfaces.
-- It uses Roblox's UI elements for a clean, modern look.
-- Features: Window, Tabs, Labels, Toggles, Buttons, Dropdowns, Notifications, Sliders, Color Pickers, Textboxes.

local Library = {}

-- Configuration (customize colors, fonts, etc.)
Library.Config = {
    PrimaryColor = Color3.fromRGB(30, 30, 30),  -- Dark background
    SecondaryColor = Color3.fromRGB(50, 50, 50), -- Tab/button backgrounds
    AccentColor = Color3.fromRGB(0, 170, 255),  -- Highlights (toggles, sliders)
    TextColor = Color3.fromRGB(255, 255, 255),  -- White text
    Font = Enum.Font.SourceSansBold,
    FontSize = 18,
    CornerRadius = UDim.new(0, 8),  -- Rounded corners
    ShadowOffset = UDim2.new(0, 2, 0, 2),  -- Subtle shadows
}

-- Utility function to create a basic frame with styling
local function CreateStyledFrame(parent, size, position)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Library.Config.PrimaryColor
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Library.Config.CornerRadius
    corner.Parent = frame
    
    -- Add shadow
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, -2, 0, -2)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = frame
    
    return frame
end

-- Utility function to create text labels
local function CreateLabel(parent, text, size, position)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Library.Config.TextColor
    label.Font = Library.Config.Font
    label.TextSize = Library.Config.FontSize
    label.Parent = parent
    return label
end

-- Create Window
function Library:CreateWindow(title)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ExploitingGUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local window = CreateStyledFrame(screenGui, UDim2.new(0, 600, 0, 400), UDim2.new(0.5, -300, 0.5, -200))
    window.Name = "Window"
    
    -- Title bar
    local titleBar = CreateStyledFrame(window, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 0))
    titleBar.BackgroundColor3 = Library.Config.SecondaryColor
    CreateLabel(titleBar, title, UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0))
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Library.Config.TextColor
    closeBtn.Font = Library.Config.Font
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Tab container
    local tabContainer = CreateStyledFrame(window, UDim2.new(1, -20, 1, -60), UDim2.new(0, 10, 0, 50))
    tabContainer.BackgroundTransparency = 1
    
    local tabs = {}
    local currentTab = nil
    
    -- Function to create tabs
    function window:CreateTab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 100, 0, 30)
        tabBtn.Position = UDim2.new(0, #tabs * 110, 0, 0)
        tabBtn.BackgroundColor3 = Library.Config.SecondaryColor
        tabBtn.Text = name
        tabBtn.TextColor3 = Library.Config.TextColor
        tabBtn.Font = Library.Config.Font
        tabBtn.TextSize = Library.Config.FontSize
        tabBtn.Parent = tabContainer
        
        local tabFrame = CreateStyledFrame(tabContainer, UDim2.new(1, 0, 1, -40), UDim2.new(0, 0, 0, 40))
        tabFrame.Visible = false
        
        tabBtn.MouseButton1Click:Connect(function()
            if currentTab then currentTab.Visible = false end
            tabFrame.Visible = true
            currentTab = tabFrame
        end)
        
        table.insert(tabs, tabBtn)
        
        local elements = {}
        
        -- Create Label
        function tabFrame:CreateLabel(text)
            local label = CreateLabel(tabFrame, text, UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, #elements * 40))
            table.insert(elements, label)
            return label
        end
        
        -- Create Toggle
        function tabFrame:CreateToggle(text, default, callback)
            local toggleFrame = CreateStyledFrame(tabFrame, UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, #elements * 40))
            toggleFrame.BackgroundColor3 = Library.Config.SecondaryColor
            
            local label = CreateLabel(toggleFrame, text, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 10, 0, 0))
            
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(0, 40, 0, 20)
            toggleBtn.Position = UDim2.new(0.8, 0, 0.5, -10)
            toggleBtn.BackgroundColor3 = default and Library.Config.AccentColor or Color3.fromRGB(100, 100, 100)
            toggleBtn.Text = ""
            toggleBtn.Parent = toggleFrame
            
            local state = default
            toggleBtn.MouseButton1Click:Connect(function()
                state = not state
                toggleBtn.BackgroundColor3 = state and Library.Config.AccentColor or Color3.fromRGB(100, 100, 100)
                if callback then callback(state) end
            end)
            
            table.insert(elements, toggleFrame)
            return toggleBtn
        end
        
        -- Create Button
        function tabFrame:CreateButton(text, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 30)
            btn.Position = UDim2.new(0, 10, 0, #elements * 40)
            btn.BackgroundColor3 = Library.Config.SecondaryColor
            btn.Text = text
            btn.TextColor3 = Library.Config.TextColor
            btn.Font = Library.Config.Font
            btn.TextSize = Library.Config.FontSize
            btn.Parent = tabFrame
            
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            
            table.insert(elements, btn)
            return btn
        end
        
        -- Create Dropdown
        function tabFrame:CreateDropdown(text, options, default, callback)
            local dropdownFrame = CreateStyledFrame(tabFrame, UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, #elements * 40))
            dropdownFrame.BackgroundColor3 = Library.Config.SecondaryColor
            
            local label = CreateLabel(dropdownFrame, text, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 10, 0, 0))
            
            local selected = Instance.new("TextButton")
            selected.Size = UDim2.new(0.2, 0, 1, 0)
            selected.Position = UDim2.new(0.8, 0, 0, 0)
            selected.BackgroundColor3 = Library.Config.AccentColor
            selected.Text = default or options[1]
            selected.TextColor3 = Library.Config.TextColor
            selected.Font = Library.Config.Font
            selected.TextSize = Library.Config.FontSize
            selected.Parent = dropdownFrame
            
            local list = Instance.new("Frame")
            list.Size = UDim2.new(0.2, 0, 0, #options * 30)
            list.Position = UDim2.new(0.8, 0, 1, 0)
            list.BackgroundColor3 = Library.Config.SecondaryColor
            list.Visible = false
            list.Parent = dropdownFrame
            
            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 30)
                optBtn.Position = UDim2.new(0, 0, 0, (i-1)*30)
                optBtn.BackgroundColor3 = Library.Config.SecondaryColor
                optBtn.Text = opt
                optBtn.TextColor3 = Library.Config.TextColor
                optBtn.Font = Library.Config.Font
                optBtn.TextSize = Library.Config.FontSize
                optBtn.Parent = list
                
                optBtn.MouseButton1Click:Connect(function()
                    selected.Text = opt
                    list.Visible = false
                    if callback then callback(opt) end
                end)
            end
            
            selected.MouseButton1Click:Connect(function()
                list.Visible = not list.Visible
            end)
            
            table.insert(elements, dropdownFrame)
            return selected
        end
        
        -- Create Notify (simple popup)
        function tabFrame:CreateNotify(message, duration)
            local notify = CreateStyledFrame(screenGui, UDim2.new(0, 300, 0, 50), UDim2.new(0.5, -150, 0.8, 0))
            notify.BackgroundColor3 = Library.Config.AccentColor
            CreateLabel(notify, message, UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0))
            
            wait(duration or 3)
            notify:Destroy()
        end
        
        -- Create Slider
        function tabFrame:CreateSlider(text, min, max, default, callback)
            local sliderFrame = CreateStyledFrame(tabFrame, UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, #elements * 40))
            sliderFrame.BackgroundColor3 = Library.Config.SecondaryColor
            
            local label = CreateLabel(sliderFrame, text .. ": " .. default, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 10, 0, 0))
            
            local sliderBar = Instance.new("Frame")
            sliderBar.Size = UDim2.new(0.2, 0, 0, 10)
            sliderBar.Position = UDim2.new(0.8, 0, 0.5, -5)
            sliderBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            sliderBar.Parent = sliderFrame
            
            local sliderBtn = Instance.new("TextButton")
            sliderBtn.Size = UDim2.new(0, 20, 0, 20)
            sliderBtn.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
            sliderBtn.BackgroundColor3 = Library.Config.AccentColor
            sliderBtn.Text = ""
            sliderBtn.Parent = sliderBar
            
            local value = default
            sliderBtn.MouseButton1Down:Connect(function()
                local moveConn
                moveConn = game:GetService("UserInputService").InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                        value = min + (max - min) * pos
                        sliderBtn.Position = UDim2.new(pos, -10, 0.5, -10)
                        label.Text = text .. ": " .. math.floor(value)
                        if callback then callback(value) end
                    end
                end)
                game:GetService("UserInputService").InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        moveConn:Disconnect()
                    end
                end)
            end)
            
            table.insert(elements, sliderFrame)
            return sliderBtn
        end
        
        -- Create Color Picker
        function tabFrame:CreateColorPicker(text, default, callback)
            local pickerFrame = CreateStyledFrame(tabFrame, UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, #elements * 40))
            pickerFrame.BackgroundColor3 = Library.Config.SecondaryColor
            
            local label = CreateLabel(pickerFrame, text, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 10, 0, 0))
            
            local colorBtn = Instance.new("TextButton")
            colorBtn.Size = UDim2.new(0, 40, 0, 20)
            colorBtn.Position = UDim2.new(0.8, 0, 0.5, -10)
            colorBtn.BackgroundColor3 = default
            colorBtn.Text = ""
            colorBtn.Parent = pickerFrame
            
            colorBtn.MouseButton1Click:Connect(function()
                -- Simple color picker (for demo, cycles through colors)
                local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255)}
                local idx = 1
                colorBtn.BackgroundColor3 = colors[idx]
                if callback then callback(colors[idx]) end
                idx = idx % #colors + 1
            end)
            
            table.insert(elements, pickerFrame)
            return colorBtn
        end
        
        -- Create Textbox
        function tabFrame:CreateTextbox(text, placeholder, callback)
            local textboxFrame = CreateStyledFrame(tabFrame, UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, #elements * 40))
            textboxFrame.BackgroundColor3 = Library.Config.SecondaryColor
            
            local label = CreateLabel(textboxFrame, text, UDim2.new(0.3, 0, 1, 0), UDim2.new(0, 10, 0, 0))
            
            local textbox = Instance.new("TextBox")
            textbox.Size = UDim2.new(0.6, 0, 1, 0)
            textbox.Position = UDim2.new(0.4, 0, 0, 0)
            textbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            textbox.Text = ""
            textbox.PlaceholderText = placeholder
            textbox.TextColor3 = Library.Config.TextColor
            textbox.Font = Library.Config.Font
            textbox.TextSize = Library.Config.FontSize
            textbox.Parent = textboxFrame
            
            textbox.FocusLost:Connect(function(enterPressed)
                if callback then callback(textbox.Text) end
            end)
            
            table.insert(elements, textboxFrame)
            return textbox
        end
        
        return tabFrame
    end
    
    return window
end

return Library
