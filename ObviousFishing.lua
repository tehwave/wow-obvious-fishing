-- Obvious Fishing: make it obvious which bobber is yours and when you get a bite.
--
-- While you're fishing:
--   * Turns game sound up (and optionally mutes music/ambience) so the bite
--     splash is loud. The client has no "bite" event, so the splash sound is the
--     only real signal an addon can amplify.
--   * Puts a static raid target icon on your own bobber's nameplate so you can
--     tell it apart from other players' bobbers. Nothing animates, so the only
--     thing moving on screen is the bobber.
--   * Shows a cast timer bar styled like the default cast bar.
-- Everything is restored a few seconds after you stop fishing.
-- Options: Game Menu > Options > AddOns > Obvious Fishing, or /bobber.

local ADDON = ...
local BOBBER_ENTRY_ID = "35591" -- Fishing Bobber game object entry

local DEFAULTS = {
    soundBoost    = true,
    masterVolume  = 0.6,   -- master volume while fishing (0-1)
    sfxVolume     = 1.0,
    muteMusic     = true,
    muteAmbience  = true,
    restoreDelay  = 12,    -- seconds after the last cast before sound/cvars go back
    showMarker    = true,
    raidIcon      = 1,     -- 1 star, 2 circle, 3 diamond, 4 triangle, 5 moon, 6 square, 7 cross, 8 skull
    iconSize      = 26,
    markerOffset  = 0,     -- vertical offset of the icon from the bobber nameplate
    markerOffsetX = 0,     -- horizontal offset
    showBar       = true,
    barScale      = 1.3,
    barPoint      = nil,   -- saved bar position
}

local RAID_ICON_NAMES = { "star", "circle", "diamond", "triangle", "moon", "square", "cross", "skull" }

local FISHING_IDS = {
    [7620] = true, [7731] = true, [7732] = true, [18248] = true,
    [33095] = true, [51294] = true, [88868] = true, [110410] = true,
    [131474] = true, [131476] = true, [131490] = true,
}

local GetCVar = (C_CVar and C_CVar.GetCVar) or GetCVar
local SetCVar = (C_CVar and C_CVar.SetCVar) or SetCVar

local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
end

local FISHING_NAME -- resolved on login (localized "Fishing")

local DB
local isFishing = false
local restoreTimer
local settingsCategory

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffObvious Fishing:|r " .. msg)
end

---------------------------------------------------------------------------
-- CVar boost / restore
---------------------------------------------------------------------------
local function BuildBoost()
    local t = {
        -- soft targeting so the bobber gets a nameplate + the interact key works on it
        SoftTargetInteract          = "3",
        SoftTargetNameplateInteract = "1",
        SoftTargetIconGameObject    = "1",
        SoftTargetIconInteract      = "1",
        SoftTargetInteractRange     = "30",
        SoftTargetInteractArc       = "2",
    }
    if DB.soundBoost then
        t.Sound_EnableAllSound            = "1"
        t.Sound_EnableSFX                 = "1"
        t.Sound_EnableSoundWhenGameIsInBG = "1"
        t.Sound_MasterVolume              = tostring(DB.masterVolume)
        t.Sound_SFXVolume                 = tostring(DB.sfxVolume)
        if DB.muteMusic    then t.Sound_MusicVolume    = "0" end
        if DB.muteAmbience then t.Sound_AmbienceVolume = "0" end
    end
    return t
end

local function DescribeBoost()
    if not DB.soundBoost then return "bobber highlighting on." end
    local muted = {}
    if DB.muteMusic then muted[#muted + 1] = "music" end
    if DB.muteAmbience then muted[#muted + 1] = "ambience" end
    local extra = #muted > 0 and (", " .. table.concat(muted, " and ") .. " muted") or ""
    return ("sound turned up to %d%%%s, bobber highlighting on."):format(DB.masterVolume * 100 + 0.5, extra)
end

local function ApplyBoost(quiet)
    if restoreTimer then restoreTimer:Cancel(); restoreTimer = nil end
    if DB.saved then return end -- already boosted
    local saved = {}
    for cvar, value in pairs(BuildBoost()) do
        local old = GetCVar(cvar)
        if old ~= nil then
            saved[cvar] = old
            SetCVar(cvar, value)
        end
    end
    DB.saved = saved -- persisted, so a crash/disconnect still gets restored next login
    if not quiet then Print("fishing - " .. DescribeBoost()) end
end

-- reason: chat text explaining why; false = restore silently
local function RestoreBoost(reason)
    if restoreTimer then restoreTimer:Cancel(); restoreTimer = nil end
    if not DB or not DB.saved then return end
    for cvar, old in pairs(DB.saved) do
        SetCVar(cvar, old)
    end
    DB.saved = nil
    if reason ~= false then
        Print((reason or "stopped fishing") .. " - your sound and settings are back to normal.")
    end
end

-- a sound setting changed mid-fishing: swap the boost in place, quietly
local function ReapplyBoost()
    if DB.saved then
        RestoreBoost(false)
        ApplyBoost(true)
    end
end

local function ScheduleRestore()
    if restoreTimer then restoreTimer:Cancel() end
    restoreTimer = C_Timer.NewTimer(DB.restoreDelay, function()
        restoreTimer = nil
        if not isFishing then RestoreBoost() end
    end)
end

---------------------------------------------------------------------------
-- The bobber marker: one static raid target icon on your bobber's nameplate.
---------------------------------------------------------------------------
local marker = CreateFrame("Frame", "ObviousFishingMarker", UIParent)
marker:SetFrameStrata("HIGH")
marker:Hide()

local icon = marker:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
icon:SetAllPoints()

local function LayoutMarker()
    marker:SetSize(DB.iconSize, DB.iconSize)
    local i = DB.raidIcon - 1
    local col, row = i % 4, math.floor(i / 4)
    icon:SetTexCoord(col / 4, (col + 1) / 4, row / 4, (row + 1) / 4)
end

local softGUID -- last GUID from PLAYER_SOFT_INTERACT_CHANGED

local POOL_WORDS = { "school", "pool", "wreckage", "debris", "floating", "swarm", "slick" }

local function IsBobberGUID(guid)
    if not guid then return false end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind ~= "GameObject" then return false end
    if id == BOBBER_ENTRY_ID then return true end
    local name = UnitName("softinteract")
    if not name then return true end -- unnamed game object while fishing: assume bobber
    name = name:lower()
    if name:find("bobber") then return true end
    for _, w in ipairs(POOL_WORDS) do
        if name:find(w) then return false end
    end
    return true -- some other game object right in front of you while fishing
end

local function PlateToken(p)
    return p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
end

-- Other players' bobbers are the same object type, so lock on to the first
-- *new* bobber that shows up after our cast and ignore every other one.
local myBobberGUID, preCastGUID, lastBobberGUID

-- returns plate, guid, how
local function FindBobberPlate()
    local guid = UnitGUID("softinteract") or softGUID
    if not IsBobberGUID(guid) then return nil, guid, "no bobber soft target" end
    if not myBobberGUID then
        if guid == preCastGUID or guid == lastBobberGUID then
            return nil, guid, "waiting for your bobber"
        end
        myBobberGUID = guid
    end
    if guid ~= myBobberGUID then return nil, guid, "someone else's bobber" end
    if not C_NamePlate then return nil, guid, "no nameplate API" end
    local plate = C_NamePlate.GetNamePlateForUnit("softinteract")
    if plate then return plate, guid, "softinteract" end
    for _, p in ipairs(C_NamePlate.GetNamePlates() or {}) do
        local tok = PlateToken(p)
        if tok and UnitGUID(tok) == guid then return p, guid, "scan" end
    end
    return nil, guid, "bobber targeted but no nameplate"
end

local testing = false

local function RefreshMarker()
    if testing then return end
    if not isFishing or not DB.showMarker then marker:Hide(); return end
    local plate = FindBobberPlate()
    if not plate or (plate.IsForbidden and plate:IsForbidden()) then
        marker:Hide(); return
    end
    marker:ClearAllPoints()
    marker:SetPoint("CENTER", plate, "CENTER", DB.markerOffsetX, DB.markerOffset)
    marker:Show()
end

---------------------------------------------------------------------------
-- Cast timer bar, styled after the default cast bar. Forever uses the modern
-- (atlas) cast bar, so copy its look from the real player cast bar when we
-- can, else fall back to the old Classic textures.
---------------------------------------------------------------------------
local function HasAtlas(a)
    return a and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(a) ~= nil
end
local function FirstAtlas(...)
    for i = 1, select("#", ...) do
        local a = select(i, ...)
        if HasAtlas(a) then return a end
    end
end
local realBar = PlayerCastingBarFrame or CastingBarFrame
local function RealAtlas(key)
    local t = realBar and realBar[key]
    return t and t.GetAtlas and t:GetAtlas()
end
local channelInfo = CASTING_BAR_TYPES and CASTING_BAR_TYPES.channel

local ATLAS = {
    fill    = FirstAtlas(channelInfo and channelInfo.filling, "ui-castingbar-filling-channel"),
    bg      = FirstAtlas(RealAtlas("Background"), "ui-castingbar-background"),
    border  = FirstAtlas(RealAtlas("Border"), "ui-castingbar-frame"),
    textbox = FirstAtlas(RealAtlas("TextBorder"), "ui-castingbar-textbox"),
    spark   = FirstAtlas(RealAtlas("Spark"), "ui-castingbar-pip"),
}
local MODERN = ATLAS.fill and ATLAS.border and true or false

local bar = CreateFrame("StatusBar", "ObviousFishingBar", UIParent)
bar:SetFrameStrata("HIGH")
bar:SetMovable(true)
bar:EnableMouse(true)
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    DB.barPoint = { p, rp, x, y }
end)
bar:Hide()

local barBG = bar:CreateTexture(nil, "BACKGROUND")
local barBorder = bar:CreateTexture(nil, "ARTWORK", nil, 1)
local barSpark = bar:CreateTexture(nil, "OVERLAY")
local barTextBox, barText

if MODERN then
    bar:SetSize(208, 11)
    -- modern clients accept an atlas name here (the default cast bar does the same)
    if not pcall(bar.SetStatusBarTexture, bar, ATLAS.fill) or not bar:GetStatusBarTexture() then
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:GetStatusBarTexture():SetAtlas(ATLAS.fill)
    end
    bar:SetStatusBarColor(1, 1, 1)

    if ATLAS.bg then barBG:SetAtlas(ATLAS.bg) else barBG:SetColorTexture(0, 0, 0, 0.6) end
    barBG:SetPoint("TOPLEFT", -1, 1)
    barBG:SetPoint("BOTTOMRIGHT", 1, -1)

    barBorder:SetAtlas(ATLAS.border)
    barBorder:SetPoint("TOPLEFT", -2, 2)
    barBorder:SetPoint("BOTTOMRIGHT", 2, -2)

    if ATLAS.spark then
        barSpark:SetAtlas(ATLAS.spark, true)
    else
        barSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        barSpark:SetBlendMode("ADD")
        barSpark:SetSize(20, 20)
    end

    barTextBox = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
    if ATLAS.textbox then
        barTextBox:SetAtlas(ATLAS.textbox)
    else
        barTextBox:SetColorTexture(0, 0, 0, 0.6)
    end
    -- slim strip under the bar, like the default cast bar (atlas native size is far too tall)
    barTextBox:SetSize(198, 14)
    barTextBox:SetPoint("TOP", bar, "BOTTOM", 0, 1)

    barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    barText:SetPoint("CENTER", barTextBox, "CENTER", 0, 1)
else
    bar:SetSize(195, 13)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0, 1, 0)
    barBG:SetAllPoints()
    barBG:SetColorTexture(0, 0, 0, 0.5)
    barBorder:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
    barBorder:SetSize(256, 64)
    barBorder:SetPoint("TOP", bar, "TOP", 0, 28)
    barSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    barSpark:SetBlendMode("ADD")
    barSpark:SetSize(32, 32)
    barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    barText:SetSize(185, 16)
    barText:SetPoint("TOP", bar, "TOP", 0, 5)
end

local barTime = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
barTime:SetPoint("LEFT", bar, "RIGHT", 8, 0)

local hint = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hint:SetPoint("TOP", barTextBox or bar, "BOTTOM", 0, -6)
hint:SetTextColor(1, 0.4, 0.4)

local function PlaceBar()
    bar:SetScale(DB.barScale)
    bar:ClearAllPoints()
    local p = DB.barPoint
    if p then bar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else bar:SetPoint("CENTER", UIParent, "CENTER", 0, 180) end
end

-- The bar's OnUpdate also drives marker polling, so when the bar is turned off
-- it stays "shown" but invisible and click-through.
local function ApplyBarVisibility()
    local visible = DB.showBar or testing
    bar:SetAlpha(visible and 1 or 0)
    bar:EnableMouse(visible)
end

local castStart, castEnd = 0, 0
local sinceRefresh = 0

bar:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local total = castEnd - castStart
    if total <= 0 then return end
    local left = math.max(0, castEnd - now)
    self:SetMinMaxValues(0, total)
    self:SetValue(left)
    barSpark:ClearAllPoints()
    barSpark:SetPoint("CENTER", self, "LEFT", self:GetWidth() * (left / total), MODERN and 0 or 2)
    barText:SetText(FISHING_NAME or "Fishing")
    barTime:SetFormattedText("%.1f", left)
    -- poll in case a nameplate/soft-target event was missed
    sinceRefresh = sinceRefresh + elapsed
    if sinceRefresh > 0.2 then sinceRefresh = 0; RefreshMarker() end
    if marker:IsShown() or testing or not DB.showMarker then
        hint:SetText("")
    else
        local _, _, how = FindBobberPlate()
        if how == "someone else's bobber" then
            hint:SetText("Highlighting someone else's bobber - turn toward yours")
        else
            hint:SetText("Bobber not highlighted - face it / turn toward it")
        end
    end
end)

---------------------------------------------------------------------------
-- Fishing state
---------------------------------------------------------------------------
local function IsFishingSpell(spellID)
    if spellID and FISHING_IDS[spellID] then return true end
    if FISHING_NAME and spellID then return SpellName(spellID) == FISHING_NAME end
    return false
end

local function StartFishing()
    isFishing = true
    preCastGUID = UnitGUID("softinteract") or softGUID
    myBobberGUID = nil
    ApplyBoost()
    local _, _, _, startMS, endMS = UnitChannelInfo("player")
    if startMS then
        castStart, castEnd = startMS / 1000, endMS / 1000
    else
        castStart, castEnd = GetTime(), GetTime() + 21
    end
    ApplyBarVisibility()
    bar:Show()
    RefreshMarker()
    -- the nameplate can take a moment to appear after the bobber lands
    C_Timer.After(0.3, RefreshMarker)
    C_Timer.After(1.0, RefreshMarker)
end

local function StopFishing()
    isFishing = false
    lastBobberGUID = myBobberGUID or lastBobberGUID
    myBobberGUID = nil
    bar:Hide()
    marker:Hide()
    ScheduleRestore()
end

local function RunTest()
    testing = true
    marker:ClearAllPoints()
    marker:SetPoint("CENTER", UIParent, "CENTER", 0, -60)
    marker:Show()
    castStart, castEnd = GetTime(), GetTime() + 6
    ApplyBarVisibility()
    bar:Show()
    C_Timer.After(6, function()
        testing = false
        ApplyBarVisibility()
        if not isFishing then bar:Hide(); marker:Hide() else RefreshMarker() end
    end)
end

---------------------------------------------------------------------------
-- Options panel (Game Menu > Options > AddOns > Obvious Fishing)
---------------------------------------------------------------------------
local function RegisterSettings()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting) then return end
    local category, layout = Settings.RegisterVerticalLayoutCategory("Obvious Fishing")
    local VT = Settings.VarType

    local function Header(text)
        if layout and CreateSettingsListSectionHeaderInitializer then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
        end
    end

    local function Setting(key, varType, name, get, set)
        return Settings.RegisterProxySetting(category, "ObviousFishing_" .. key, varType, name,
            DEFAULTS[key], get or function() return DB[key] end, set)
    end

    local function Slider(setting, minV, maxV, step, fmt, tooltip)
        local options = Settings.CreateSliderOptions(minV, maxV, step)
        if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Label then
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt)
        end
        Settings.CreateSlider(category, setting, options, tooltip)
    end

    -- Sound
    Header("Sound while fishing")
    Settings.CreateCheckbox(category,
        Setting("soundBoost", VT.Bool, "Turn sound up while fishing", nil,
            function(v) DB.soundBoost = v; ReapplyBoost() end),
        "Raises game sound while you fish so the bite splash is easy to hear. Your own sound settings come back when you stop.")

    local vol = Settings.RegisterProxySetting(category, "ObviousFishing_masterVolume", VT.Number,
        "Volume while fishing", DEFAULTS.masterVolume * 100,
        function() return math.floor(DB.masterVolume * 100 + 0.5) end,
        function(v) DB.masterVolume = v / 100; if DB.saved and DB.soundBoost then SetCVar("Sound_MasterVolume", tostring(DB.masterVolume)) end end)
    Slider(vol, 0, 100, 5, function(v) return ("%d%%"):format(v) end,
        "Master volume used while fishing.")

    Settings.CreateCheckbox(category,
        Setting("muteMusic", VT.Bool, "Mute music", nil,
            function(v) DB.muteMusic = v; ReapplyBoost() end),
        "Silences music while you fish.")
    Settings.CreateCheckbox(category,
        Setting("muteAmbience", VT.Bool, "Mute ambience", nil,
            function(v) DB.muteAmbience = v; ReapplyBoost() end),
        "Silences ambient sounds (wind, water, crowds) while you fish.")

    -- Bobber
    Header("Bobber")
    Settings.CreateCheckbox(category,
        Setting("showMarker", VT.Bool, "Mark your bobber", nil,
            function(v) DB.showMarker = v; RefreshMarker() end),
        "Shows a raid target icon on your own bobber, so you can tell it apart from other players' bobbers.")

    local iconSetting = Setting("raidIcon", VT.Number, "Marker icon", nil,
        function(v) DB.raidIcon = v; LayoutMarker() end)
    Settings.CreateDropdown(category, iconSetting, function()
        local c = Settings.CreateControlTextContainer()
        for i, name in ipairs(RAID_ICON_NAMES) do
            c:Add(i, ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:14|t %s"):format(i, name:gsub("^%l", string.upper)))
        end
        return c:GetData()
    end, "Which raid target icon marks your bobber.")

    Slider(Setting("iconSize", VT.Number, "Marker size", nil,
            function(v) DB.iconSize = v; LayoutMarker() end),
        12, 64, 2, function(v) return ("%d"):format(v) end, "Size of the marker icon.")

    -- Cast bar
    Header("Cast bar")
    Settings.CreateCheckbox(category,
        Setting("showBar", VT.Bool, "Show fishing cast bar", nil,
            function(v) DB.showBar = v; ApplyBarVisibility() end),
        "A cast bar showing how long your cast has left. Shift-drag it to move it.")

    Slider(Setting("barScale", VT.Number, "Cast bar size", nil,
            function(v) DB.barScale = v; PlaceBar() end),
        0.5, 3, 0.1, function(v) return ("%.1fx"):format(v) end, "Size of the fishing cast bar.")

    if layout and CreateSettingsButtonInitializer then
        layout:AddInitializer(CreateSettingsButtonInitializer("Preview", "Show marker and bar",
            RunTest, "Shows the marker and cast bar for a few seconds.", true))
    end

    Settings.RegisterAddOnCategory(category)
    settingsCategory = category
end

local function OpenSettings()
    if settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(settingsCategory:GetID())
    else
        Print("the options panel isn't available - type /bobber help for commands.")
    end
end
ObviousFishing_OpenSettings = OpenSettings -- addon compartment (minimap addon menu)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
pcall(ev.RegisterEvent, ev, "PLAYER_SOFT_INTERACT_CHANGED")
ev:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
ev:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

ev:SetScript("OnEvent", function(_, event, a1, a2, a3)
    if event == "ADDON_LOADED" then
        if a1 ~= ADDON then return end
        ObviousFishingDB = ObviousFishingDB or {}
        DB = ObviousFishingDB
        for k, v in pairs(DEFAULTS) do
            if DB[k] == nil then DB[k] = v end
        end
    elseif event == "PLAYER_LOGIN" then
        FISHING_NAME = SpellName(7620)
        -- leftover boost from a crash / disconnect mid-fishing
        if DB.saved then RestoreBoost("last session ended while fishing") end
        LayoutMarker()
        PlaceBar()
        RegisterSettings()
    elseif event == "PLAYER_LOGOUT" then
        RestoreBoost(false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        if IsFishingSpell(a3) then StartFishing() end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if isFishing then StopFishing() end
    else
        -- nameplate / soft-target changes
        if event == "PLAYER_SOFT_INTERACT_CHANGED" then softGUID = a2 end
        RefreshMarker()
    end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_OBVIOUSFISHING1 = "/bobber"
SLASH_OBVIOUSFISHING2 = "/obviousfishing"
SlashCmdList.OBVIOUSFISHING = function(msg)
    local cmd, arg = strsplit(" ", (msg or ""):lower(), 2)
    if cmd == "" or cmd == "options" or cmd == "config" then
        OpenSettings()
    elseif cmd == "test" then
        RunTest()
    elseif cmd == "offset" then
        local ys, xs = strsplit(" ", arg or "")
        local y, x = tonumber(ys), tonumber(xs)
        if y then
            DB.markerOffset = y
            if x then DB.markerOffsetX = x end
            RefreshMarker()
            Print(("marker offset: up/down %d, left/right %d"):format(DB.markerOffset, DB.markerOffsetX))
        else
            Print(("usage: /bobber offset <y> [x]  (negative = lower / left). now %d %d")
                :format(DB.markerOffset, DB.markerOffsetX))
        end
    elseif cmd == "reset" then
        RestoreBoost("reset")
        DB.barPoint = nil; PlaceBar()
        Print("cast bar position reset.")
    elseif cmd == "debug" then
        local u = "softinteract"
        Print(("fishing=%s  UnitExists=%s"):format(tostring(isFishing), tostring(UnitExists(u))))
        Print(("UnitGUID=%s"):format(tostring(UnitGUID(u))))
        Print(("eventGUID=%s"):format(tostring(softGUID)))
        Print(("UnitName=%s"):format(tostring(UnitName(u))))
        local plate, guid, how = FindBobberPlate()
        Print(("isBobber=%s  plate=%s (%s)"):format(tostring(IsBobberGUID(guid)), plate and "yes" or "no", how))
        for _, cv in ipairs({ "SoftTargetInteract", "SoftTargetNameplateInteract",
                              "SoftTargetIconGameObject", "SoftTargetInteractRange" }) do
            Print(("  %s = %s"):format(cv, tostring(GetCVar(cv))))
        end
    else
        Print("commands:")
        Print("  /bobber - open the options panel")
        Print("  /bobber test - preview the marker and cast bar")
        Print("  /bobber offset <y> [x] - nudge the marker")
        Print("  /bobber reset - restore your sound now and reset the bar position")
        Print("  /bobber debug - (while fishing) show why your bobber is or isn't detected")
        Print("  Shift-drag the cast bar to move it.")
    end
end
