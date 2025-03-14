-- Addon namespace
local addonName, addonTable = ...
-- Saved variables
MyLatencyDB = {
    sliders = {50, 80, 50}, -- Updated default values for sliders
    checkboxes = {true, true, true, false, false}, -- Updated for new checkboxes with defaults
    position = {point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0}, -- Default position
    frameSize = {width = 250, height = 100}, -- Adjusted default frame size
    updateLayout = false
}

-- Function to initialize settings
local function InitializeSettings()
    if not MyLatencyDB then
        MyLatencyDB = {}
    end
    MyLatencyDB.sliders = MyLatencyDB.sliders or {50, 80, 50}
    MyLatencyDB.checkboxes = MyLatencyDB.checkboxes or {true, true, true, false, false}
    MyLatencyDB.position = MyLatencyDB.position or {point = "CENTER", relativeTo = nil, relativePoint = "CENTER", xOfs = 0, yOfs = 0}
    MyLatencyDB.frameSize = MyLatencyDB.frameSize or {width = 250, height = 100}
    MyLatencyDB.updateLayout = MyLatencyDB.updateLayout or false
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

-- Create the settings frame
local settingsFrame = CreateFrame("Frame", "SettingsFrame", UIParent, "BackdropTemplate")
settingsFrame:SetSize(200, 250)
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
closeButton:SetNormalTexture("Interface\\AddOns\\MyLatency\\close.png")
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

-- Function to update the frame size based on content
local function UpdateFrameSize()
    local height = 20 -- Base height for padding
    local width = 20 -- Base width for padding

    if localLatencyText:IsShown() then
        height = height + localLatencyText:GetStringHeight() + 10 -- Add height of local latency text and padding
        width = math.max(width, localLatencyText:GetStringWidth() + localLatencyValue:GetStringWidth() + 20) -- Adjust width to fit local latency text and value
    end

    if serverLatencyText:IsShown() then
        height = height + serverLatencyText:GetStringHeight() + 10 -- Add height of server latency text and padding
        width = math.max(width, serverLatencyText:GetStringWidth() + serverLatencyValue:GetStringWidth() + 20) -- Adjust width to fit server latency text and value
    end

    infoFrame:SetSize(width, height) -- Adjust frame size to fit content
    -- Save frame size
    MyLatencyDB.frameSize = {width = infoFrame:GetWidth(), height = infoFrame:GetHeight()}
end

-- Function to update the layout based on checkbox states
local function UpdateLayout()
    local yOffset = -10 -- Initial offset for the first text element

    if checkbox2 and checkbox2:GetChecked() then
        localLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, yOffset)
        localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
        yOffset = yOffset - localLatencyText:GetStringHeight() - 10 -- Update offset for the next element
    end

    if checkbox3 and checkbox3:GetChecked() then
        if checkbox2 and checkbox2:GetChecked() then
            serverLatencyText:SetPoint("TOPLEFT", localLatencyText, "BOTTOMLEFT", 0, -10)
        else
            serverLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, yOffset)
        end
        serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
    end

    UpdateFrameSize()
end

-- Create checkboxes
local checkbox1, checkbox2, checkbox3

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
    if not checked then
        serverLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, -10)
        serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
    else
        serverLatencyText:SetPoint("TOPLEFT", 10, -30)
        serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
    end
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

-- Create sliders
local slider1 = CreateSlider(settingsFrame, "Scale", 25, 100, 50, -40, function(value)
    infoFrame:SetScale(value / 50) -- Scale from 0.5 to 2
end)
local slider2 = CreateSlider(settingsFrame, "Alpha", 0, 100, 80, -80, function(value)
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
end)

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

    UpdateFrameSize() -- Update frame size based on new content
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
            -- Apply checkbox states
            checkbox1:GetScript("OnClick")(checkbox1)
            checkbox2:GetScript("OnClick")(checkbox2)
            checkbox3:GetScript("OnClick")(checkbox3)
            UpdateLayout()
            -- Apply text alpha
            local alpha = MyLatencyDB.sliders[3] / 100
            localLatencyText:SetAlpha(alpha)
            localLatencyValue:SetAlpha(alpha)
            serverLatencyText:SetAlpha(alpha)
            serverLatencyValue:SetAlpha(alpha)
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

        -- Save frame position
        local point, relativeTo, relativePoint, xOfs, yOfs = infoFrame:GetPoint()
        MyLatencyDB.position = {point = point, relativeTo = relativeTo, relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs}
        -- Save frame size
        MyLatencyDB.frameSize = {width = infoFrame:GetWidth(), height = infoFrame:GetHeight()}
    end
end)
