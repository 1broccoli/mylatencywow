-- Addon namespace
local addonName, addonTable = ...

-- Create a frame for displaying stats
local frame = CreateFrame("Frame", "LatencyFrame", UIParent, "BackdropTemplate")
frame:SetSize(150, 60) -- Initial Width, Height
frame:SetPoint("CENTER") -- Center on screen

-- Set the backdrop for the frame
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- Background texture
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Border texture
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- Set the backdrop color
frame:SetBackdropColor(0, 0, 0, 0.8) -- Black background with slight transparency

-- Local Latency Text
local localLatencyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
localLatencyText:SetPoint("TOPLEFT", 10, -10) -- Positioning adjusted for top padding
localLatencyText:SetText("|cFFFFFFFFHome Latency:|r")

-- Dynamic local latency value
local localLatencyValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
localLatencyValue:SetTextColor(0, 1, 0) -- Initial color green

-- Server Latency Text
local serverLatencyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
serverLatencyText:SetPoint("TOPLEFT", 10, -30) -- Adjusted to be below local latency text
serverLatencyText:SetText("|cFFFFFFFFServer Latency:|r")

-- Dynamic server latency value
local serverLatencyValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
serverLatencyValue:SetTextColor(0, 1, 0) -- Initial color green

-- Function to adjust frame size based on text content
local function AdjustFrameSize()
    local textWidth = math.max(localLatencyText:GetStringWidth() + localLatencyValue:GetStringWidth() + 20, -- 20 for padding
                                serverLatencyText:GetStringWidth() + serverLatencyValue:GetStringWidth() + 20) -- 20 for padding
    frame:SetSize(textWidth, 60) -- Adjust frame size to fit text
end

-- Function to update the border color based on latency
local function UpdateBorderColor(latency)
    if latency < 80 then
        frame:SetBackdropBorderColor(0, 1, 0) -- Green
    elseif latency < 140 then
        frame:SetBackdropBorderColor(1, 1, 0) -- Yellow
    else
        frame:SetBackdropBorderColor(1, 0, 0) -- Red
    end
end

-- Update function
local function UpdateStats()
    -- Get Local and Server Latency
    local homeMS, worldMS = select(3, GetNetStats())

    -- Update local latency text value
    localLatencyValue:SetText(homeMS .. " ms")

    -- Update server latency text value
    serverLatencyValue:SetText(worldMS .. " ms")

    -- Set local latency color for Home Latency
    local latencyColor
    if homeMS < 80 then
        latencyColor = {0, 1, 0} -- Green
    elseif homeMS < 140 then
        latencyColor = {1, 1, 0} -- Yellow
    else
        latencyColor = {1, 0, 0} -- Red
    end

    localLatencyValue:SetTextColor(unpack(latencyColor))

    -- Update the border color based on local latency
    UpdateBorderColor(homeMS)

    -- Adjust frame size based on new text values
    AdjustFrameSize()
end

-- Set script for updating every second
frame:SetScript("OnUpdate", function(self, elapsed)
    self.updateTime = (self.updateTime or 0) + elapsed
    if self.updateTime > 1 then
        UpdateStats()
        self.updateTime = 0
    end
end)

-- Make the frame movable
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
