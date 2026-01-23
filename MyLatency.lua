-- Addon Name: MyLatency
local addonName, addonTable = ...

-- Embed libraries
local AceAddon = LibStub("AceAddon-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local LSM = LibStub("LibSharedMedia-3.0", true)  -- Optional: true means don't error if missing
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Create addon
local MyLatency = AceAddon:NewAddon(addonName, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

-- Default settings
local defaults = {
    profile = {
        scale = 1,
        bgAlpha = 0.8,
        textAlpha = 1,
        lineSpacing = 10,
        font = "Friz Quadrata TT",  -- Default WoW font
        fontSize = 14,
        bgTexture = "Blizzard Dialog", -- SharedMedia background
        borderTexture = "Tooltip",      -- SharedMedia border
        showBorder = true,
        showLocal = true,
        showServer = true,
        showFPS = false,
        lockFrame = false,
        textOutline = false,
        horizontalLayout = false,
        position = { point = "CENTER", x = 0, y = 0 },
        minimap = { hide = false },
    },
}

-- Create display frame
local infoFrame
local localLatencyText, localLatencyValue
local serverLatencyText, serverLatencyValue
local fpsText, fpsValue

function MyLatency:OnInitialize()
    self.db = AceDB:New("MyLatencyDB", defaults, true)
    self:SetupOptions()
    self:InitMinimapIcon()
end

function MyLatency:OnEnable()
    self:CreateDisplayFrame()
    self:RegisterEvent("PLAYER_LOGOUT")
    self:UpdateStats()  -- Initial update populates text and sizes frame correctly
    self:ScheduleRepeatingTimer("UpdateStats", 1)
    self:RefreshMinimapIcon()
end

function MyLatency:OnDisable()
    self:CancelAllTimers()
end

function MyLatency:InitMinimapIcon()
    if not LDB or not LDBIcon then return end
    if self.minimapIcon then return end

    local dataObject = LDB:NewDataObject(addonName, {
        type = "launcher",
        text = "MyLatency",
        icon = "Interface\\Icons\\inv_misc_pocketwatch_01",
        OnClick = function(_, button)
            if button == "LeftButton" then
                self.db.profile.lockFrame = not self.db.profile.lockFrame
                print("MyLatency: Frame " .. (self.db.profile.lockFrame and "locked" or "unlocked"))
                AceConfigRegistry:NotifyChange(addonName) -- refresh options UI if open
            else
                AceConfigDialog:Open(addonName)
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("MyLatency")
            tt:AddLine("Left-Click: Lock/Unlock frame", 1, 1, 1)
            tt:AddLine("Right-Click: Open settings", 1, 1, 1)
            tt:AddLine("Current: " .. (self.db and self.db.profile.lockFrame and "Locked" or "Unlocked"), 0, 1, 0)
        end,
    })

    self.minimapIcon = dataObject
    LDBIcon:Register(addonName, dataObject, self.db.profile.minimap)
end

function MyLatency:RefreshMinimapIcon()
    if not LDBIcon or not self.minimapIcon then return end
    if self.db.profile.minimap.hide then
        LDBIcon:Hide(addonName)
    else
        LDBIcon:Show(addonName)
    end
end

function MyLatency:CreateDisplayFrame()
    infoFrame = CreateFrame("Frame", "LatencyFrame", UIParent, "BackdropTemplate")
    infoFrame:SetSize(200, 50)  -- Starting size, will be recalculated by UpdateStats
    infoFrame:ClearAllPoints()
    local point = self.db.profile.position.point or "CENTER"
    local x = self.db.profile.position.x or 0
    local y = self.db.profile.position.y or 0
    infoFrame:SetPoint(point, UIParent, point, x, y)
    self:ApplyBackdrop()
    infoFrame:SetScale(self.db.profile.scale)
    infoFrame:Show()

    infoFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Right-click to open settings", nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    infoFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    localLatencyText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    localLatencyText:SetText("|cFFFFFFFFLocal|r")
    localLatencyText:SetAlpha(self.db.profile.textAlpha)
    self:SetFontString(localLatencyText)

    localLatencyValue = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    localLatencyValue:SetText("0 |cff808080ms|r")  -- Placeholder for sizing
    localLatencyValue:SetTextColor(0, 1, 0)
    localLatencyValue:SetAlpha(self.db.profile.textAlpha)
    self:SetFontString(localLatencyValue)

    serverLatencyText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    serverLatencyText:SetText("|cFFFFFFFFServer|r")
    serverLatencyText:SetAlpha(self.db.profile.textAlpha)
    self:SetFontString(serverLatencyText)
    self:SetFontString(serverLatencyText)

    serverLatencyValue = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    serverLatencyValue:SetText("0 |cff808080ms|r")  -- Placeholder for sizing
    serverLatencyValue:SetTextColor(0, 1, 0)
    serverLatencyValue:SetAlpha(self.db.profile.textAlpha)
    self:SetFontString(serverLatencyValue)
    self:SetFontString(serverLatencyValue)

    fpsText = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpsText:SetText("|cFFFFFFFFFPS|r")
    fpsText:SetAlpha(self.db.profile.textAlpha)
    fpsText:SetShown(self.db.profile.showFPS)
    self:SetFontString(fpsText)
    self:SetFontString(fpsText)

    fpsValue = infoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpsValue:SetText("0")  -- Placeholder for sizing
    fpsValue:SetTextColor(0, 1, 0)
    fpsValue:SetAlpha(self.db.profile.textAlpha)
    fpsValue:SetShown(self.db.profile.showFPS)
    self:SetFontString(fpsValue)
    self:SetFontString(fpsValue)

    infoFrame:EnableMouse(true)
    infoFrame:SetMovable(true)
    infoFrame:RegisterForDrag("LeftButton")
    infoFrame:SetScript("OnDragStart", function(self)
        if not MyLatency.db.profile.lockFrame then
            self:StartMoving()
        end
    end)
    infoFrame:SetScript("OnDragStop", function(self)
        if not MyLatency.db.profile.lockFrame then
            self:StopMovingOrSizing()
            local point, relativeTo, relativePoint, x, y = self:GetPoint()
            MyLatency.db.profile.position.point = point
            MyLatency.db.profile.position.x = x
            MyLatency.db.profile.position.y = y
        end
    end)
    infoFrame:SetClampedToScreen(true)

    infoFrame:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            AceConfigDialog:Open(addonName)
        end
    end)

    self:ApplyFontOutline()
    -- UpdateLayout and CalculateFrameSize will be called by UpdateStats()
end

function MyLatency:ApplyFontOutline()
    local outlineFlag = self.db.profile.textOutline and "OUTLINE" or ""
    local function updateFontString(fs)
        if not fs then return end
        local fontPath, fontHeight = fs:GetFont()
        fs:SetFont(fontPath, fontHeight, outlineFlag)
    end
    updateFontString(localLatencyText)
    updateFontString(localLatencyValue)
    updateFontString(serverLatencyText)
    updateFontString(serverLatencyValue)
    updateFontString(fpsText)
    updateFontString(fpsValue)
end

function MyLatency:ApplyBackdrop()
    if not infoFrame then return end
    local bg = (LSM and self.db.profile.bgTexture) and LSM:Fetch("background", self.db.profile.bgTexture, true) or "Interface\\DialogFrame\\UI-DialogBox-Background"
    local edge = (LSM and self.db.profile.borderTexture) and LSM:Fetch("border", self.db.profile.borderTexture, true) or "Interface\\Tooltips\\UI-Tooltip-Border"
    infoFrame:SetBackdrop({
        bgFile = bg,
        edgeFile = edge,
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    infoFrame:SetBackdropColor(0, 0, 0, self.db.profile.bgAlpha)
    if self.db.profile.showBorder then
        infoFrame:SetBackdropBorderColor(0, 1, 0)
    else
        infoFrame:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

function MyLatency:SetFontString(fs)
    if not fs then return end
    local fontPath = LSM and LSM:Fetch("font", self.db.profile.font) or "Fonts\\FRIZQT__.TTF"
    local fontSize = self.db.profile.fontSize or 14
    local outlineFlag = self.db.profile.textOutline and "OUTLINE" or ""
    fs:SetFont(fontPath, fontSize, outlineFlag)
end
function MyLatency:UpdateAllFonts()
    if not infoFrame then return end
    self:SetFontString(localLatencyText)
    self:SetFontString(localLatencyValue)
    self:SetFontString(serverLatencyText)
    self:SetFontString(serverLatencyValue)
    self:SetFontString(fpsText)
    self:SetFontString(fpsValue)
    self:UpdateStats()  -- Recalculate layout with new font sizes
end

function MyLatency:StyleOptionsFrame(frame)
    if not frame or frame.__MyLatencyStyled then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(0.2, 0.9, 0.2, 1)
    frame.__MyLatencyStyled = true
end
function MyLatency:UpdateAllFonts()
    if not infoFrame then return end
    self:SetFontString(localLatencyText)
    self:SetFontString(localLatencyValue)
    self:SetFontString(serverLatencyText)
    self:SetFontString(serverLatencyValue)
    self:SetFontString(fpsText)
    self:SetFontString(fpsValue)
    self:UpdateLayout()
end

function MyLatency:UpdateLayout()
    if not infoFrame then return end
    local spacing = self.db.profile.lineSpacing
    local padding = 8

    if self.db.profile.horizontalLayout then
        self:UpdateLayoutHorizontal(spacing)
    else
        self:UpdateLayoutVertical(spacing, padding)
    end
    self:CalculateFrameSize()
end

function MyLatency:UpdateLayoutHorizontal(spacing)
    local xPos = 10
    if self.db.profile.showLocal then
        localLatencyText:ClearAllPoints()
        localLatencyText:SetPoint("LEFT", infoFrame, "LEFT", xPos, 0)
        localLatencyValue:ClearAllPoints()
        localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
        localLatencyText:Show()
        localLatencyValue:Show()
        xPos = xPos + (localLatencyText:GetStringWidth() or 0) + (localLatencyValue:GetStringWidth() or 0) + spacing + 5
    else
        localLatencyText:Hide()
        localLatencyValue:Hide()
    end

    if self.db.profile.showServer then
        serverLatencyText:ClearAllPoints()
        serverLatencyText:SetPoint("LEFT", infoFrame, "LEFT", xPos, 0)
        serverLatencyValue:ClearAllPoints()
        serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
        serverLatencyText:Show()
        serverLatencyValue:Show()
        xPos = xPos + (serverLatencyText:GetStringWidth() or 0) + (serverLatencyValue:GetStringWidth() or 0) + spacing + 5
    else
        serverLatencyText:Hide()
        serverLatencyValue:Hide()
    end

    if self.db.profile.showFPS then
        fpsText:ClearAllPoints()
        fpsText:SetPoint("LEFT", infoFrame, "LEFT", xPos, 0)
        fpsValue:ClearAllPoints()
        fpsValue:SetPoint("LEFT", fpsText, "RIGHT", 5, 0)
        fpsText:Show()
        fpsValue:Show()
    else
        fpsText:Hide()
        fpsValue:Hide()
    end
end

function MyLatency:UpdateLayoutVertical(spacing, padding)
    local yPos = -padding
    local lineHeight = select(2, localLatencyText:GetFont()) or 14

    if self.db.profile.showLocal then
        localLatencyText:ClearAllPoints()
        localLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, yPos)
        localLatencyValue:ClearAllPoints()
        localLatencyValue:SetPoint("LEFT", localLatencyText, "RIGHT", 5, 0)
        localLatencyText:Show()
        localLatencyValue:Show()
        yPos = yPos - (lineHeight + spacing)
    else
        localLatencyText:Hide()
        localLatencyValue:Hide()
    end

    if self.db.profile.showServer then
        serverLatencyText:ClearAllPoints()
        serverLatencyText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, yPos)
        serverLatencyValue:ClearAllPoints()
        serverLatencyValue:SetPoint("LEFT", serverLatencyText, "RIGHT", 5, 0)
        serverLatencyText:Show()
        serverLatencyValue:Show()
        yPos = yPos - (lineHeight + spacing)
    else
        serverLatencyText:Hide()
        serverLatencyValue:Hide()
    end

    if self.db.profile.showFPS then
        fpsText:ClearAllPoints()
        fpsText:SetPoint("TOPLEFT", infoFrame, "TOPLEFT", 10, yPos)
        fpsValue:ClearAllPoints()
        fpsValue:SetPoint("LEFT", fpsText, "RIGHT", 5, 0)
        fpsText:Show()
        fpsValue:Show()
    else
        fpsText:Hide()
        fpsValue:Hide()
    end
end

function MyLatency:CalculateFrameSize()
    local spacing = self.db.profile.lineSpacing
    local padding = 8
    local lineHeight = select(2, localLatencyText:GetFont()) or 14
    local width, height

    if self.db.profile.horizontalLayout then
        width = 20  -- Just left/right padding
        height = 35
        local visibleCount = 0

        if self.db.profile.showLocal then
            width = width + (localLatencyText:GetStringWidth() or 0) + (localLatencyValue:GetStringWidth() or 0) + 5
            visibleCount = visibleCount + 1
        end
        if self.db.profile.showServer then
            width = width + (serverLatencyText:GetStringWidth() or 0) + (serverLatencyValue:GetStringWidth() or 0) + 5
            visibleCount = visibleCount + 1
        end
        if self.db.profile.showFPS then
            width = width + (fpsText:GetStringWidth() or 0) + (fpsValue:GetStringWidth() or 0) + 5
            visibleCount = visibleCount + 1
        end

        if visibleCount > 1 then
            width = width + (visibleCount - 1) * spacing
        end
    else
        width = 120
        height = 40
        local visibleCount = 0
        local maxLineWidth = 0

        if self.db.profile.showLocal then
            visibleCount = visibleCount + 1
            maxLineWidth = math.max(maxLineWidth, (localLatencyText:GetStringWidth() or 0) + (localLatencyValue:GetStringWidth() or 0) + 20)
        end
        if self.db.profile.showServer then
            visibleCount = visibleCount + 1
            maxLineWidth = math.max(maxLineWidth, (serverLatencyText:GetStringWidth() or 0) + (serverLatencyValue:GetStringWidth() or 0) + 20)
        end
        if self.db.profile.showFPS then
            visibleCount = visibleCount + 1
            maxLineWidth = math.max(maxLineWidth, (fpsText:GetStringWidth() or 0) + (fpsValue:GetStringWidth() or 0) + 20)
        end

        if visibleCount > 0 then
            height = (visibleCount * lineHeight) + ((visibleCount - 1) * spacing) + padding * 2
        end
        width = math.max(width, maxLineWidth + padding)
    end

    infoFrame:SetSize(width, height)
end

function MyLatency:UpdateBorderColor(homeMS, worldMS)
    if not self.db.profile.showBorder then
        infoFrame:SetBackdropBorderColor(0, 0, 0, 0)
        return
    end

    local latency = math.max(homeMS or 0, worldMS or 0)
    if latency < 70 then
        infoFrame:SetBackdropBorderColor(0, 1, 0)
    elseif latency < 130 then
        infoFrame:SetBackdropBorderColor(1, 1, 0)
    else
        infoFrame:SetBackdropBorderColor(1, 0, 0)
    end
end

function MyLatency:UpdateStats()
    local homeMS, worldMS = select(3, GetNetStats())
    homeMS = homeMS or 0
    worldMS = worldMS or 0

    if self.db.profile.showLocal then
        localLatencyValue:SetText(homeMS .. " |cff808080ms|r")
        local color = self:GetLatencyColor(homeMS)
        localLatencyValue:SetTextColor(unpack(color))
    end

    if self.db.profile.showServer then
        serverLatencyValue:SetText(worldMS .. " |cff808080ms|r")
        local color = self:GetLatencyColor(worldMS)
        serverLatencyValue:SetTextColor(unpack(color))
    end

    if self.db.profile.showFPS then
        local fps = math.floor(GetFramerate() + 0.5)
        fpsValue:SetText(fps)
        local fpsColor = fps <= 30 and {1, 0, 0} or (fps < 60 and {1, 1, 0} or {0, 1, 0})
        fpsValue:SetTextColor(unpack(fpsColor))
    end

    self:UpdateBorderColor(homeMS, worldMS)
    self:UpdateLayout()  -- Layout with accurate text widths
    self:CalculateFrameSize()
end

function MyLatency:GetLatencyColor(ms)
    if ms < 70 then return {0, 1, 0} end
    if ms < 130 then return {1, 1, 0} end
    return {1, 0, 0}
end

function MyLatency:PLAYER_LOGOUT()
    if infoFrame then
        local point, relativeTo, relativePoint, x, y = infoFrame:GetPoint()
        self.db.profile.position.point = point
        self.db.profile.position.x = x
        self.db.profile.position.y = y
    end
end

function MyLatency:SetupOptions()
    local options = {
        name = "|cff1eff00My|rLatency",
        handler = MyLatency,
        type = "group",
        args = {
            display = {
                name = "|cff1eff00Display|r Settings",
                                inline = true,
                type = "group",
                order = 1,
                args = {
                    font = { name = "|cffff9900Font|r", desc = "Choose font for all text", type = "select", dialogControl = "LSM30_Font", values = LSM and LSM:HashTable("font") or {}, get = function() return self.db.profile.font end, set = function(info, val) self.db.profile.font = val; self:UpdateAllFonts() end, order = 1 },
                    fontSize = { name = "|cffff9900Font Size|r", desc = "Adjust the font size (8 - 32)", type = "range", min = 8, max = 32, step = 1, get = function() return self.db.profile.fontSize end, set = function(info, val) self.db.profile.fontSize = val; self:UpdateAllFonts() end, order = 2 },
                    bgTexture = { name = "|cffff9900Background Texture|r", desc = "Choose background texture (SharedMedia)", type = "select", dialogControl = "LSM30_Background", values = LSM and LSM:HashTable("background") or {}, get = function() return self.db.profile.bgTexture end, set = function(info, val) self.db.profile.bgTexture = val; self:ApplyBackdrop() end, order = 2.5 },
                    borderTexture = { name = "|cffff9900Border Texture|r", desc = "Choose border texture (SharedMedia)", type = "select", dialogControl = "LSM30_Border", values = LSM and LSM:HashTable("border") or {}, get = function() return self.db.profile.borderTexture end, set = function(info, val) self.db.profile.borderTexture = val; self:ApplyBackdrop() end, order = 2.6 },
                    scale = { name = "|cffff9900Scale|r", desc = "Adjust the size of the display frame (0.5 - 2.0)", type = "range", min = 0.5, max = 2, step = 0.1, get = function() return self.db.profile.scale end, set = function(info, val) self.db.profile.scale = val; if infoFrame then infoFrame:SetScale(val) end end, order = 3 },
                    bgAlpha = { name = "|cffff9900Background Alpha|r", desc = "Background transparency (0 = transparent, 1 = opaque)", type = "range", min = 0, max = 1, step = 0.05, get = function() return self.db.profile.bgAlpha end, set = function(info, val) self.db.profile.bgAlpha = val; if infoFrame then infoFrame:SetBackdropColor(0, 0, 0, val) end end, order = 4 },
                    textAlpha = { name = "|cffff9900Text Alpha|r", desc = "Text transparency (0 = transparent, 1 = opaque)", type = "range", min = 0, max = 1, step = 0.05, get = function() return self.db.profile.textAlpha end, set = function(info, val) self.db.profile.textAlpha = val; if localLatencyText then localLatencyText:SetAlpha(val); localLatencyValue:SetAlpha(val); serverLatencyText:SetAlpha(val); serverLatencyValue:SetAlpha(val); fpsText:SetAlpha(val); fpsValue:SetAlpha(val) end end, order = 5 },
                    lineSpacing = { name = "|cffff9900Line Spacing|r", desc = "Space between lines or stat groups (0 - 100)", type = "range", min = 0, max = 100, step = 1, get = function() return self.db.profile.lineSpacing end, set = function(info, val) self.db.profile.lineSpacing = val; self:UpdateLayout() end, order = 6 },
                },
            },
            content = {
                name = "|cff1eff00Content|r Options",
                                inline = true,
                type = "group",
                order = 2,
                args = {
                    showBorder = { name = "|cffff9900Show Border Color|r", desc = "Display border color indicator based on latency", type = "toggle", get = function() return self.db.profile.showBorder end, set = function(info, val) self.db.profile.showBorder = val; if not val then infoFrame:SetBackdropBorderColor(0, 0, 0, 0) end end },
                    showLocal = { name = "|cffff9900Show Local Latency|r", desc = "Display local/home latency", type = "toggle", get = function() return self.db.profile.showLocal end, set = function(info, val) self.db.profile.showLocal = val; self:UpdateLayout() end },
                    showServer = { name = "|cffff9900Show Server Latency|r", desc = "Display server/world latency", type = "toggle", get = function() return self.db.profile.showServer end, set = function(info, val) self.db.profile.showServer = val; self:UpdateLayout() end },
                    showFPS = { name = "|cffff9900Show FPS|r", desc = "Display frames per second", type = "toggle", get = function() return self.db.profile.showFPS end, set = function(info, val) self.db.profile.showFPS = val; self:UpdateLayout() end },
                },
            },
            style = {
                name = "|cff1eff00Style|r & Layout",
                                inline = true,
                type = "group",
                order = 3,
                args = {
                    lockFrame = { name = "|cffff9900Lock Frame|r", desc = "Prevent accidental dragging of the display frame", type = "toggle", get = function() return self.db.profile.lockFrame end, set = function(info, val) self.db.profile.lockFrame = val end },
                    textOutline = { name = "|cffff9900Text Outline|r", desc = "Draw outline around latency and FPS text for better visibility", type = "toggle", get = function() return self.db.profile.textOutline end, set = function(info, val) self.db.profile.textOutline = val; self:UpdateAllFonts() end },
                    horizontalLayout = { name = "|cffff9900Horizontal Layout|r", desc = "Switch between horizontal and vertical display layouts", type = "toggle", get = function() return self.db.profile.horizontalLayout end, set = function(info, val) self.db.profile.horizontalLayout = val; self:UpdateLayout() end },
                    showMinimap = { name = "|cffff9900Show Minimap Icon|r", desc = "Show or hide the minimap launcher", type = "toggle", get = function() return not self.db.profile.minimap.hide end, set = function(info, val) self.db.profile.minimap.hide = not val; self:RefreshMinimapIcon() end },
                },
            },
            profiles = AceDBOptions:GetOptionsTable(self.db),
        },
    }
    options.args.profiles.order = 4
        options.args.profiles.inline = true
    AceConfig:RegisterOptionsTable(addonName, options)
    AceConfigDialog:SetDefaultSize(addonName, 780, 680)  
    AceConfigDialog:AddToBlizOptions(addonName, "MyLatency")
end

MyLatency:RegisterChatCommand("mlat", function() AceConfigDialog:Open(addonName) end)
MyLatency:RegisterChatCommand("mylatency", function() AceConfigDialog:Open(addonName) end)
