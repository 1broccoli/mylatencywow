-- Addon Name: MyLatency
local addonName, addonTable = ...
-- Saved variables
MyLatencyDB = {
    sliders = {50, 80, 50}, -- Updated default values for sliders
    checkboxes = {true, true, true, false, false, false}, -- Updated for new checkboxes with defaults
    position = {point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0}, -- Default position
    frameSize = {width = 250, height = 100}, -- Adjusted default frame size
    updateLayout = false
}

local function InitializeSettings()
    if not MyLatencyDB then
        MyLatencyDB = {}
    end
    MyLatencyDB.sliders = MyLatencyDB.sliders or {50, 80, 50}
    MyLatencyDB.checkboxes = MyLatencyDB.checkboxes or {true, true, true, false, false, false}
    MyLatencyDB.position = MyLatencyDB.position or {point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0}
    MyLatencyDB.frameSize = MyLatencyDB.frameSize or {width = 250, height = 100}
    
    -- Ensure updateLayout is loaded properly
    if MyLatencyDB.updateLayout == nil then
        MyLatencyDB.updateLayout = false -- Default to false if not set
    end
end


-- Create a frame for displaying stats
local infoFrame = CreateFrame("Frame", "LatencyFrame", UIParent, "BackdropTemplate")
infoFrame:SetSize(MyLatencyDB.frameSize.width, MyLatencyDB.frameSize.height) -- Adjusted Height
infoFrame:SetPoint(MyLatencyDB.position.point, MyLatencyDB.position.relativeTo, MyLatencyDB.position.relativePoint, MyLatencyDB.position.xOfs, MyLatencyDB.position.yOfs)
infoFrame:Show() -- Initially shown
-- Set the backdrop for the frame
infoFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Background texture
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Border texture
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- Set the backdrop color
infoFrame:SetBackdropColor(0, 0, 0, 0.8) -- Black background with slight transparency

-- Add tooltip to infoFrame
infoFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Right-click to open settings", nil, nil, nil, nil, true)
    GameTooltip:Show()
end)
infoFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Local Latency Text
local localLatencyText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
localLatencyText:SetPoint("TOPLEFT", 10, -10) -- Positioning adjusted for top padding
localLatencyText:SetText("|cFFFFFFFFLocal|r")

-- Dynamic local latency value
local localLatencyValue = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
localLatencyValue:SetTextColor(0, 1, 0) -- Initial color green

-- Server Latency Text
local serverLatencyText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
serverLatencyText:SetPoint("TOPLEFT", 10, -30) -- Adjusted to be below local latency text
serverLatencyText:SetText("|cFFFFFFFFServer|r")

-- Dynamic server latency value
local serverLatencyValue = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
serverLatencyValue:SetTextColor(0, 1, 0) -- Initial color green

-- FPS Text
local fpsText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fpsText:SetText("|cFFFFFFFFFPS|r")
fpsText:SetShown(false) -- Initially hidden

-- Dynamic FPS value
local fpsValue = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fpsValue:SetTextColor(0, 1, 0) -- Initial color green
fpsValue:SetShown(false) -- Initially hidden

-- Create the settings frame
local settingsFrame = CreateFrame("Frame", "SettingsFrame", UIParent, "BackdropTemplate")
settingsFrame:SetSize(200, 280)
settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Centered initially
settingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
settingsFrame:SetBackdropColor(0, 0, 0, 0.8)
settingsFrame:SetBackdropBorderColor(0, 0, 0)
settingsFrame:Hide() -- Hide the frame initially

-- Make the settings frame movable
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
settingsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)
settingsFrame:SetClampedToScreen(true)

-- Title text for the settings frame
local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
settingsTitle:SetPoint("TOP", settingsFrame, "TOP", 0, -10)
settingsTitle:SetText("|cFF00FF00Settings|r") -- Green color

-- Close button for the settings frame
local closeButton = CreateFrame("Button", nil, settingsFrame)
closeButton:SetSize(24, 24)
closeButton:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -5)
closeButton:SetNormalTexture("Interface\\AddOns\\MyLatency\\Textures\\close.png")
closeButton:SetScript("OnClick", function()
    settingsFrame:Hide()
end)
closeButton:SetScript("OnEnter", function(self)
    self:GetNormalTexture():SetVertexColor(1, 0, 0) -- Red color on highlight
end)
closeButton:SetScript("OnLeave", function(self)
    self:GetNormalTexture():SetVertexColor(1, 1, 1) -- Reset color
end)

-- Function to create a slider
local function CreateSlider(parent, label, minVal, maxVal, defaultVal, yOffset, onValueChanged)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOP", parent, "TOP", 0, yOffset)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(defaultVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(150)

    local sliderLabel = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sliderLabel:SetPoint("BOTTOM", slider, "TOP", 0, 0)
    sliderLabel:SetText(label)

    local sliderValue = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sliderValue:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    sliderValue:SetText(slider:GetValue())

    slider:SetScript("OnValueChanged", function(self, value)
        sliderValue:SetText(value)
        if onValueChanged then
            onValueChanged(value)
        end
    end)

    return slider
end

-- Function to create a checkbox
local function CreateCheckbox(parent, label, yOffset, tooltip, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    checkbox.Text:SetText(label)
    checkbox.tooltip = tooltip
    checkbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    checkbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    checkbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            self.Text:SetTextColor(1, 1, 0) -- Yellow
            if onClick then onClick(true) end
        else
            self.Text:SetTextColor(0.5, 0.5, 0.5) -- Gray
            if onClick then onClick(false) end
        end
        MyLatencyDB.checkboxes[self:GetID()] = self:GetChecked() -- Save state
    end)
    -- Set initial color
    checkbox:SetChecked(false)
    checkbox.Text:SetTextColor(0.5, 0.5, 0.5) -- Gray
    return checkbox
end

local checkbox1, checkbox2, checkbox3, checkbox4

-- Function to update the border color based on latency
local function UpdateBorderColor(homeLatency, serverLatency)
    local latency = math.max(homeLatency or 0, serverLatency or 0) -- Use the higher of the two latencies, default to 0 if nil

    if checkbox1 and not checkbox1:GetChecked() then
        infoFrame:SetBackdropBorderColor(0, 0, 0, 0) -- Clear border
        return
    end

    if latency < 70 then
        infoFrame:SetBackdropBorderColor(0, 1, 0) -- Green
    elseif latency < 130 then
        infoFrame:SetBackdropBorderColor(1, 1, 0) -- Yellow
    else
        infoFrame:SetBackdropBorderColor(1, 0, 0) -- Red
    end
end

local function UpdateFrameSize()
    local width, height

    if MyLatencyDB.updateLayout then
        -- Horizontal layout
        width = 290
        height = 35

        if checkbox2 and checkbox2:GetChecked() then
            localLatencyText:ClearAllPoints()
            localLatencyText:SetPoint("LEFT", infoFrame, "LEFT", 10, 0)
            localLatencyValue:ClearAllPoints()
            localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
        end

        if checkbox3 and checkbox3:GetChecked() then
            serverLatencyText:ClearAllPoints()
            if checkbox2 and checkbox2:GetChecked() then
                serverLatencyText:SetPoint("LEFT", localLatencyValue, "RIGHT", 15, 0)
            else
                serverLatencyText:SetPoint("LEFT", infoFrame, "LEFT", 10, 0)
            end
            serverLatencyValue:ClearAllPoints()
            serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
        end

        if checkbox4 and checkbox4:GetChecked() then
            fpsText:ClearAllPoints()
            if checkbox3 and checkbox3:GetChecked() then
                fpsText:SetPoint("LEFT", serverLatencyValue, "RIGHT", 15, 0)
            elseif checkbox2 and checkbox2:GetChecked() then
                fpsText:SetPoint("LEFT", localLatencyValue, "RIGHT", 15, 0)
            else
                fpsText:SetPoint("LEFT", infoFrame, "LEFT", 10, 0)
            end
            fpsValue:ClearAllPoints()
            fpsValue:SetPoint("LEFT", fpsText, "RIGHT", 5, 0)
        end

        -- Adjust width if elements are hidden
        if checkbox2 and not checkbox2:GetChecked() then
            width = width - 100
        end
        if checkbox3 and not checkbox3:GetChecked() then
            width = width - 95
        end
        if checkbox4 and not checkbox4:GetChecked() then
            width = width - 75
        end
    else
        -- Vertical layout
        width = 120
        height = 80

        if checkbox2 and checkbox2:GetChecked() then
            localLatencyText:ClearAllPoints()
            localLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, -10)
            localLatencyValue:ClearAllPoints()
            localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
        end

        if checkbox3 and checkbox3:GetChecked() then
            serverLatencyText:ClearAllPoints()
            if checkbox2 and checkbox2:GetChecked() then
                serverLatencyText:SetPoint("TOPLEFT", localLatencyText, "BOTTOMLEFT", 0, -10)
            else
                serverLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, -10)
            end
            serverLatencyValue:ClearAllPoints()
            serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
        end

        if checkbox4 and checkbox4:GetChecked() then
            fpsText:ClearAllPoints()
            if checkbox3 and checkbox3:GetChecked() then
                fpsText:SetPoint("TOPLEFT", serverLatencyText, "BOTTOMLEFT", 0, -10)
            elseif checkbox2 and checkbox2:GetChecked() then
                fpsText:SetPoint("TOPLEFT", localLatencyText, "BOTTOMLEFT", 0, -10)
            else
                fpsText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, -10)
            end
            fpsValue:ClearAllPoints()
            fpsValue:SetPoint("LEFT", fpsText, "RIGHT", 5, 0)
        end

        -- Adjust height if elements are hidden
        if checkbox2 and not checkbox2:GetChecked() then
            height = height - 20
        end
        if checkbox3 and not checkbox3:GetChecked() then
            height = height - 20
        end
        if checkbox4 and not checkbox4:GetChecked() then
            height = height - 20
        end
    end

    -- Set new size
    infoFrame:SetSize(width, height)
    MyLatencyDB.frameSize = {width = width, height = height}
end

-- Function to update the layout based on checkbox states
local function UpdateLayout()
    if MyLatencyDB.updateLayout then
        -- Horizontal layout
        localLatencyText:ClearAllPoints() 
        localLatencyText:SetPoint("LEFT", infoFrame, "LEFT", 10, 0) 
        localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0) 
        serverLatencyText:SetPoint("LEFT", localLatencyValue, "RIGHT", 20, 0) 
        serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0) 
        fpsText:SetPoint("LEFT", serverLatencyValue, "RIGHT", 15, 0)
        fpsValue:SetPoint("LEFT", fpsText, "RIGHT", 5, 0)
    else
        -- Vertical layout
        localLatencyText:ClearAllPoints()
        localLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, -10)
        localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
        serverLatencyText:SetPoint("TOPLEFT", localLatencyText, "BOTTOMLEFT", 0, -10)
        serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
        fpsText:SetPoint("TOPLEFT", serverLatencyText, "BOTTOMLEFT", 0, -10)
        fpsValue:SetPoint("LEFT", fpsText, "RIGHT", 5, 0)
    end

    UpdateFrameSize()
end

-- Function to apply settings
local function ApplySettings()
    infoFrame:SetScale(MyLatencyDB.sliders[1] / 50)  -- Scale from 0.5 to 2

    -- Update layout based on the checkbox state
    UpdateLayout()

    -- Update backdrop settings
    infoFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    infoFrame:SetBackdropColor(0, 0, 0, MyLatencyDB.sliders[2] / 100)
    infoFrame:SetBackdropBorderColor(1, 1, 1, MyLatencyDB.sliders[2] / 100)
end

-- Create a button for toggling layout
local layoutButton = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
layoutButton:SetSize(110, 24)
layoutButton:SetPoint("BOTTOM", settingsFrame, "BOTTOM", 0, 10)
layoutButton:SetText("Switch Layout")
layoutButton:SetScript("OnClick", function()
--- print("Current Layout: " .. (MyLatencyDB.updateLayout and "Horizontal" or "Vertical"))
    MyLatencyDB.updateLayout = not MyLatencyDB.updateLayout
    ApplySettings()
        
end)


-- Apply layout changes initially
InitializeSettings()
UpdateLayout()        

-- Function to apply settings
local function ApplySettings()
    infoFrame:SetScale(MyLatencyDB.sliders[1] / 50)  -- Scale from 0.5 to 2

    -- Update layout based on the checkbox state
    UpdateLayout()

    -- Update backdrop settings
    infoFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    infoFrame:SetBackdropColor(0, 0, 0, MyLatencyDB.sliders[2] / 100)
    infoFrame:SetBackdropBorderColor(1, 1, 1, MyLatencyDB.sliders[2] / 100)
end

-- Create checkboxes
checkbox1 = CreateCheckbox(settingsFrame, "Show Border Color", -160, "Toggle the border color based on latency", function(checked)
    local homeMS = select(3, GetNetStats()) -- Get current home latency
    if checked then
        UpdateBorderColor(homeMS) -- Reapply border color based on current latency
    else
        infoFrame:SetBackdropBorderColor(0, 0, 0, 0) -- Clear border
    end
end)
checkbox1:SetID(1)

checkbox2 = CreateCheckbox(settingsFrame, "Show Home Latency", -180, "Toggle the display of home latency", function(checked)
    localLatencyText:SetShown(checked)
    localLatencyValue:SetShown(checked)
    
    UpdateLayout()
end)
checkbox2:SetID(2)

checkbox3 = CreateCheckbox(settingsFrame, "Show Server Latency", -200, "Toggle the display of server latency", function(checked)
    serverLatencyText:SetShown(checked)
    serverLatencyValue:SetShown(checked)
    UpdateLayout()
end)
checkbox3:SetID(3)
checkbox3.Text:SetTextColor(0.5, 0.5, 0.5) -- Gray

checkbox4 = CreateCheckbox(settingsFrame, "Show FPS", -220, "Toggle the display of FPS", function(checked)
    fpsText:SetShown(checked)
    fpsValue:SetShown(checked)
    UpdateLayout()
end)
checkbox4:SetID(4)

-- Create sliders
local slider1 = CreateSlider(settingsFrame, "Scale", 25, 100, 50, -40, function(value)
    infoFrame:SetScale(value / 50) -- Scale from 0.5 to 2
end)
local slider2 = CreateSlider(settingsFrame, "Background Alpha", 0, 100, 80, -80, function(value)
    local alpha = value / 100
    infoFrame:SetBackdropColor(0, 0, 0, alpha)
    infoFrame:SetBackdropBorderColor(1, 1, 1, alpha)
    if value <= 1 then
        checkbox1:SetChecked(false)
        checkbox1.Text:SetTextColor(0.5, 0.5, 0.5) -- Gray
        checkbox1:Disable()
        infoFrame:SetBackdropBorderColor(0, 0, 0, 0) -- Clear border
    else
        checkbox1.Text:SetTextColor(1, 1, 0) -- Yellow
        checkbox1:Enable()
    end
end)
local slider3 = CreateSlider(settingsFrame, "Text Alpha", 0, 100, 100, -120, function(value)
    local alpha = value / 100
    localLatencyText:SetAlpha(alpha)
    localLatencyValue:SetAlpha(alpha)
    serverLatencyText:SetAlpha(alpha)
    serverLatencyValue:SetAlpha(alpha)
    fpsText:SetAlpha(alpha)
    fpsValue:SetAlpha(alpha)
end)

-- Call ApplySettings to apply the initial settings
ApplySettings()

-- Function to update the layout dynamically based on latency text width
local function AdjustLatencyLayout()
    local localLatencyWidth = localLatencyValue:GetStringWidth() or 0
    local serverLatencyWidth = serverLatencyValue:GetStringWidth() or 0

    -- Adjust positions dynamically to prevent overlap
    localLatencyValue:ClearAllPoints()
    localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)

    serverLatencyText:ClearAllPoints()
    if localLatencyWidth > 50 then -- Adjust if local latency is wide
        serverLatencyText:SetPoint("TOPLEFT", localLatencyText, "BOTTOMLEFT", 0, -10)
    else
        serverLatencyText:SetPoint("TOPLEFT", 10, -30)
    end

    serverLatencyValue:ClearAllPoints()
    serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)

    -- Adjust frame width dynamically
    local maxWidth = math.max(localLatencyText:GetStringWidth() + localLatencyWidth, serverLatencyText:GetStringWidth() + serverLatencyWidth) + 20
    local currentHeight = infoFrame:GetHeight()
    infoFrame:SetSize(math.max(maxWidth, 120), currentHeight)
end

-- Update function
local function UpdateStats()
    -- Get Local and Server Latency
    local homeMS, worldMS = select(3, GetNetStats())

    -- Ensure valid values
    homeMS = homeMS or 0
    worldMS = worldMS or 0

    -- Update local latency text value
    localLatencyValue:SetText(homeMS .. " |cff808080ms|r")

    -- Update server latency text value
    serverLatencyValue:SetText(worldMS .. " |cff808080ms|r")

    -- Set local latency color for Home Latency
    local homeLatencyColor
    if homeMS < 70 then
        homeLatencyColor = {0, 1, 0} -- Green
    elseif homeMS < 130 then
        homeLatencyColor = {1, 1, 0} -- Yellow
    else
        homeLatencyColor = {1, 0, 0} -- Red
    end

    localLatencyValue:SetTextColor(unpack(homeLatencyColor))

    -- Set server latency color for Server Latency
    local serverLatencyColor
    if worldMS < 70 then
        serverLatencyColor = {0, 1, 0} -- Green
    elseif worldMS < 130 then
        serverLatencyColor = {1, 1, 0} -- Yellow
    else
        serverLatencyColor = {1, 0, 0} -- Red
    end

    serverLatencyValue:SetTextColor(unpack(serverLatencyColor))

    -- Update the border color based on the higher of home and server latency
    if checkbox1 and checkbox1:GetChecked() then
        UpdateBorderColor(homeMS, worldMS)
    else
        infoFrame:SetBackdropBorderColor(0, 0, 0, 0) -- Clear border
    end

    -- Update FPS
    if checkbox4 and checkbox4:GetChecked() then
        local fps = math.floor(GetFramerate() + 0.5) -- Round to nearest whole number
        fpsValue:SetText(fps)

        -- Set FPS color based on value
        if fps <= 30 then
            fpsValue:SetTextColor(1, 0, 0) -- Red
        elseif fps < 60 then
            fpsValue:SetTextColor(1, 1, 0) -- Yellow
        else
            fpsValue:SetTextColor(0, 1, 0) -- Green
        end
    end

    -- Adjust layout dynamically to prevent overlap
    AdjustLatencyLayout()

    UpdateFrameSize() -- Update frame size based on new content
end

-- Adjust visibility and position of elements
local function AdjustElementsVisibility()
    local yOffset = -10
    if AMU_Settings.showHomeLatency then
        latencyHomeLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
        latencyHomeLabel:Show()
        latencyHomeValue:SetPoint("LEFT", latencyHomeLabel, "RIGHT", 5, 0)
        latencyHomeValue:Show()
        yOffset = yOffset - 20
    else
        latencyHomeLabel:Hide()
        latencyHomeValue:Hide()
    end

    if AMU_Settings.showWorldLatency then
        latencyWorldLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
        latencyWorldLabel:Show()
        latencyWorldValue:SetPoint("LEFT", latencyWorldLabel, "RIGHT", 5, 0)
        latencyWorldValue:Show()
        yOffset = yOffset - 20
    else
        latencyWorldLabel:Hide()
        latencyWorldValue:Hide()
    end

    if AMU_Settings.showMemoryUsage then
        memoryUsageLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
        memoryUsageLabel:Show()
        memoryUsageValue:SetPoint("LEFT", memoryUsageLabel, "RIGHT", 5, 0)
        memoryUsageValue:Show()
        yOffset = yOffset - 20
    else
        memoryUsageLabel:Hide()
        memoryUsageValue:Hide()
    end

    if AMU_Settings.showFPS then
        fpsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
        fpsLabel:Show()
        fpsValue:SetPoint("LEFT", fpsLabel, "RIGHT", 5, 0)
        fpsValue:Show()
        yOffset = yOffset - 20
    else
        fpsLabel:Hide()
        fpsValue:Hide()
    end

    -- Adjust frame height based on visible elements
    local height = -yOffset + 10  -- Base height plus padding
    frame:SetHeight(height)
    
    -- Hide frame if all checkboxes are unchecked
    if not (AMU_Settings.showFPS or AMU_Settings.showHomeLatency or AMU_Settings.showWorldLatency or AMU_Settings.showMemoryUsage) then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Set script for updating every second
infoFrame:SetScript("OnUpdate", function(self, elapsed)
    self.updateTime = (self.updateTime or 0) + elapsed
    if self.updateTime > 1 then
        UpdateStats()
        self.updateTime = 0
    end
end)

-- Make the frame movable
infoFrame:EnableMouse(true)
infoFrame:SetMovable(true)
infoFrame:RegisterForDrag("LeftButton")
infoFrame:SetScript("OnDragStart", infoFrame.StartMoving)
infoFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    MyLatencyDB.position = {point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs}
    -- Save frame size
    MyLatencyDB.frameSize = {width = infoFrame:GetWidth(), height = infoFrame:GetHeight()}
end)
infoFrame:SetClampedToScreen(true)

-- Show settings frame on right-click
infoFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        if settingsFrame:IsShown() then
            settingsFrame:Hide()
        else
            settingsFrame:Show()
        end
    end
end)

-- Event frame for saving settings
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize settings
        InitializeSettings()
        -- Load saved variables
        if MyLatencyDB then
            slider1:SetValue(MyLatencyDB.sliders[1])
            slider2:SetValue(MyLatencyDB.sliders[2])
            slider3:SetValue(MyLatencyDB.sliders[3])
            checkbox1:SetChecked(MyLatencyDB.checkboxes[1])
            checkbox2:SetChecked(MyLatencyDB.checkboxes[2])
            checkbox3:SetChecked(MyLatencyDB.checkboxes[3])
            checkbox4:SetChecked(MyLatencyDB.checkboxes[4])
            -- Apply checkbox states
            checkbox1:GetScript("OnClick")(checkbox1)
            checkbox2:GetScript("OnClick")(checkbox2)
            checkbox3:GetScript("OnClick")(checkbox3)
            checkbox4:GetScript("OnClick")(checkbox4)
            -- Apply text alpha
            local alpha = MyLatencyDB.sliders[3] / 100
            localLatencyText:SetAlpha(alpha)
            localLatencyValue:SetAlpha(alpha)
            serverLatencyText:SetAlpha(alpha)
            serverLatencyValue:SetAlpha(alpha)
            fpsText:SetAlpha(alpha)
            fpsValue:SetAlpha(alpha)
            -- Apply frame size
            UpdateLayout()
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save current settings
        MyLatencyDB.sliders[1] = slider1:GetValue()
        MyLatencyDB.sliders[2] = slider2:GetValue()
        MyLatencyDB.sliders[3] = slider3:GetValue()
        MyLatencyDB.checkboxes[1] = checkbox1:GetChecked()
        MyLatencyDB.checkboxes[2] = checkbox2:GetChecked()
        MyLatencyDB.checkboxes[3] = checkbox3:GetChecked()
        MyLatencyDB.checkboxes[4] = checkbox4:GetChecked()
        MyLatencyDB.updateLayout = not not MyLatencyDB.updateLayout -- Save button state

        -- Save frame position
        local point, relativeTo, relativePoint, xOfs, yOfs = infoFrame:GetPoint()
        MyLatencyDB.position = {point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs}
        -- Save frame size
        MyLatencyDB.frameSize = {width = infoFrame:GetWidth(), height = infoFrame:GetHeight()}
    end
end)
