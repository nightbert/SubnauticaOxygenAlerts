local addonName = ...
local frame

local SOUND_PATH = "Interface\\AddOns\\" .. addonName .. "\\src\\"
local DEFAULT_SETTINGS = {
  volume = 1.0,
  channel = "SFX",
}

local CHANNEL_OPTIONS = {
  { value = "SFX", text = "SFX" },
  { value = "Master", text = "Master" },
  { value = "Music", text = "Music" },
  { value = "Ambience", text = "Ambience" },
  { value = "Dialog", text = "Dialog" },
}

local CHANNEL_LOOKUP = {}
for _, option in ipairs(CHANNEL_OPTIONS) do
  CHANNEL_LOOKUP[option.value] = option.text
end

local settings
local configFrame
local soundObject

local PERCENT_THRESHOLDS = {
  { key = "pct50", value = 0.50, file = "oxygen_50.ogg" },
  { key = "pct25", value = 0.25, file = "oxygen_25.ogg" },
  { key = "pct10", value = 0.10, file = "oxygen_10.ogg" },
  { key = "pct01", value = 0.01, file = "oxygen_01.ogg" },
}

local state = {
  active = false,
  value = 0,
  max = 0,
  scale = -1,
  paused = false,
  lastRemaining = 0,
  lastUpdateTime = 0,
  ticker = nil,
}

local played = {}

local function ResetPlayed()
  for _, t in ipairs(PERCENT_THRESHOLDS) do
    played[t.key] = false
  end
end

local function ClampVolume(value)
  if type(value) ~= "number" then
    return DEFAULT_SETTINGS.volume
  end
  if value < 0 then
    return 0
  end
  if value > 1 then
    return 1
  end
  return value
end

local function NormalizeSettings(db)
  if type(db) ~= "table" then
    return
  end
  db.volume = ClampVolume(db.volume)
  if type(db.channel) ~= "string" or not CHANNEL_LOOKUP[db.channel] then
    db.channel = DEFAULT_SETTINGS.channel
  end
end

local function InitializeSettings()
  if type(SubnauticaOxygenAlertsDB) ~= "table" then
    SubnauticaOxygenAlertsDB = {}
  end
  NormalizeSettings(SubnauticaOxygenAlertsDB)
  settings = SubnauticaOxygenAlertsDB
end

local function GetSettingVolume()
  if settings then
    return ClampVolume(settings.volume)
  end
  return DEFAULT_SETTINGS.volume
end

local function GetSettingChannel()
  if settings and type(settings.channel) == "string" and CHANNEL_LOOKUP[settings.channel] then
    return settings.channel
  end
  return DEFAULT_SETTINGS.channel
end

local function GetChannelLabel(value)
  return CHANNEL_LOOKUP[value] or value or DEFAULT_SETTINGS.channel
end

local function CreateVolumeSlider(parent)
  return CreateFrame("Slider", "SubnauticaOxygenAlertsVolumeSlider", parent)
end

local function SetSolidTexture(texture, r, g, b, a)
  if not texture then
    return
  end
  if texture.SetColorTexture then
    texture:SetColorTexture(r, g, b, a)
  else
    texture:SetTexture("Interface\\Buttons\\WHITE8x8")
    texture:SetVertexColor(r, g, b, a)
  end
end

local function LayoutSliderBackdrop(slider, background, border)
  if not slider or not background then
    return
  end

  local width, height = slider:GetSize()
  if not width or width <= 0 then
    slider:SetWidth(160)
    width = slider:GetWidth()
  end
  if not height or height <= 0 then
    slider:SetHeight(17)
    height = slider:GetHeight()
  end

  local inset = 8
  local thumb = slider.GetThumbTexture and slider:GetThumbTexture() or nil
  if type(thumb) == "table" and thumb.GetWidth then
    local thumbWidth = thumb:GetWidth()
    if thumbWidth and thumbWidth > 0 then
      inset = math.max(4, math.floor(thumbWidth / 2 + 0.5) - 2)
    end
  end

  local trackHeight = math.min(4, height)
  background:ClearAllPoints()
  background:SetHeight(trackHeight)
  background:SetPoint("LEFT", slider, "LEFT", inset, 0)
  background:SetPoint("RIGHT", slider, "RIGHT", -inset, 0)
  background:SetPoint("CENTER", slider, "CENTER", 0, 0)
  if background.SetHorizTile then
    background:SetHorizTile(true)
    background:SetVertTile(false)
  end

  if border then
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", background, "TOPLEFT", -4, 4)
    border:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", 4, -4)
  end
end

local function HideSliderLabels(slider)
  if not slider or not slider.GetRegions then
    return
  end
  local regions = { slider:GetRegions() }
  for _, region in ipairs(regions) do
    if region and region.GetObjectType and region:GetObjectType() == "FontString" then
      region:Hide()
    end
  end
end

local function EnsureSliderBackdrop(slider)
  if not slider then
    return
  end

  if slider.SetThumbTexture and not slider:GetThumbTexture() then
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  end
  local thumb = slider.GetThumbTexture and slider:GetThumbTexture() or nil
  if thumb and thumb.SetSize then
    thumb:SetSize(44, 44)
  end

  local name = slider.GetName and slider:GetName() or nil
  local background = slider.Background or (name and _G[name .. "Background"])
  if not background then
    background = slider:CreateTexture(nil, "ARTWORK")
    slider.Background = background
  else
    background:Show()
  end
  SetSolidTexture(background, 0.55, 0.55, 0.55, 0.9)

  local border = slider.Border or (name and _G[name .. "Border"])
  if border then
    border:Hide()
  end
  slider.Border = nil
  LayoutSliderBackdrop(slider, background, nil)
  slider:SetScript("OnSizeChanged", function(self)
    LayoutSliderBackdrop(self, self.Background, self.Border)
  end)
end

local function RefreshConfigFrame()
  if not configFrame then
    return
  end
  local volumePercent = math.floor(GetSettingVolume() * 100 + 0.5)
  configFrame.volumeSlider:SetValue(volumePercent)
  configFrame.volumeValue:SetText(volumePercent .. "%")
  local channel = GetSettingChannel()
  UIDropDownMenu_SetSelectedValue(configFrame.channelDropdown, channel)
  UIDropDownMenu_SetText(configFrame.channelDropdown, GetChannelLabel(channel))
end

local function CreateConfigFrame()
  if configFrame then
    return configFrame
  end

  local f = CreateFrame("Frame", "SubnauticaOxygenAlertsConfigFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(320, 200)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()

  if UISpecialFrames then
    table.insert(UISpecialFrames, "SubnauticaOxygenAlertsConfigFrame")
  end

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 6, 0)
  f.title:SetText("Subnautica Alerts")

  local volumeSlider = CreateVolumeSlider(f)
  volumeSlider:SetPoint("TOP", f, "TOP", 0, -60)
  volumeSlider:SetWidth(200)
  volumeSlider:SetHeight(17)
  if volumeSlider.SetOrientation then
    volumeSlider:SetOrientation("HORIZONTAL")
  end
  if volumeSlider.EnableMouse then
    volumeSlider:EnableMouse(true)
  end
  volumeSlider:SetMinMaxValues(0, 100)
  volumeSlider:SetValueStep(1)
  if volumeSlider.SetObeyStepOnDrag then
    volumeSlider:SetObeyStepOnDrag(true)
  end
  EnsureSliderBackdrop(volumeSlider)
  HideSliderLabels(volumeSlider)

  local volumeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  volumeLabel:SetPoint("BOTTOM", volumeSlider, "TOP", 0, 6)
  volumeLabel:SetText("Alert volume")

  local volumeLowLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  volumeLowLabel:SetPoint("TOPLEFT", volumeSlider, "BOTTOMLEFT", 0, -2)
  volumeLowLabel:SetText("0%")

  local volumeHighLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  volumeHighLabel:SetPoint("TOPRIGHT", volumeSlider, "BOTTOMRIGHT", 0, -2)
  volumeHighLabel:SetText("100%")

  local volumeValue = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  volumeValue:SetPoint("TOP", volumeSlider, "BOTTOM", 0, -18)
  volumeValue:SetText("100%")

  volumeSlider:SetScript("OnValueChanged", function(_, value)
    local rounded = math.floor(value + 0.5)
    if settings then
      settings.volume = ClampVolume(rounded / 100)
    end
    volumeValue:SetText(rounded .. "%")
  end)

  local channelLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  channelLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -115)
  channelLabel:SetText("Sound channel")

  local channelDropdown = CreateFrame("Frame", "SubnauticaOxygenAlertsChannelDropdown", f, "UIDropDownMenuTemplate")
  channelDropdown:SetPoint("TOPLEFT", channelLabel, "BOTTOMLEFT", -16, -4)

  UIDropDownMenu_Initialize(channelDropdown, function()
    for _, option in ipairs(CHANNEL_OPTIONS) do
      local value = option.value
      local info = UIDropDownMenu_CreateInfo()
      info.text = option.text
      info.value = value
      info.func = function()
        if settings then
          settings.channel = value
        end
        UIDropDownMenu_SetSelectedValue(channelDropdown, value)
        UIDropDownMenu_SetText(channelDropdown, GetChannelLabel(value))
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  UIDropDownMenu_SetWidth(channelDropdown, 140)
  UIDropDownMenu_JustifyText(channelDropdown, "LEFT")

  f.volumeSlider = volumeSlider
  f.volumeValue = volumeValue
  f.channelDropdown = channelDropdown

  configFrame = f
  return f
end

local function OpenConfig()
  if not settings then
    InitializeSettings()
  end
  local f = CreateConfigFrame()
  RefreshConfigFrame()
  f:Show()
end

local function ComputeRemaining(value, max, scale)
  if not value or not max or max <= 0 then
    return 0
  end
  local remaining = value
  if remaining < 0 then
    remaining = 0
  elseif remaining > max then
    remaining = max
  end
  return remaining
end

local function EnsureSoundObject()
  if soundObject then
    return soundObject
  end
  if not CreateSound then
    return nil
  end
  local ok, obj = pcall(CreateSound, "SubnauticaOxygenAlertsSound")
  if not ok then
    ok, obj = pcall(CreateSound)
  end
  if ok and obj then
    soundObject = obj
    return soundObject
  end
  return nil
end

local function PlaySound(name)
  local path = SOUND_PATH .. name
  local channel = GetSettingChannel()
  local volume = GetSettingVolume()

  local obj = EnsureSoundObject()
  if obj and obj.Play then
    local setFile = obj.SetSoundFile or obj.SetFile
    if setFile then
      setFile(obj, path)
      if obj.SetChannel then
        obj:SetChannel(channel)
      end
      if obj.SetVolume then
        obj:SetVolume(volume)
      end
      obj:Play()
      return
    end
  end

  local handle = PlaySoundFile(path, channel)
  if handle and SetSoundVolume then
    pcall(SetSoundVolume, handle, volume)
  end
  if not handle then
    handle = PlaySoundFile(path, "Master")
  end
  if not handle then
    PlaySoundFile(path)
  end
end

local function CheckThresholds(remaining)
  if state.max <= 0 then
    return
  end

  local last = state.lastRemaining or remaining

  for _, t in ipairs(PERCENT_THRESHOLDS) do
    local threshold = state.max * t.value
    if not played[t.key] and last > threshold and remaining <= threshold then
      PlaySound(t.file)
      played[t.key] = true
    end
  end
end

local function TickBreathTimer(elapsed)
  if not state.active then
    return
  end

  if type(elapsed) ~= "number" then
    elapsed = nil
  end

  local now = GetTime()
  local delta = elapsed
  if not delta then
    local last = state.lastUpdateTime or now
    delta = now - last
  end
  state.lastUpdateTime = now

  if state.paused or state.max <= 0 then
    return
  end

  state.value = state.value + (delta * 1000 * state.scale)

  if state.scale < 0 and state.value < 0 then
    state.value = 0
  elseif state.scale > 0 and state.value > state.max then
    state.value = state.max
  end

  local remaining = ComputeRemaining(state.value, state.max, state.scale)
  CheckThresholds(remaining)
  state.lastRemaining = remaining

  if remaining <= 0 and state.scale < 0 then
    state.active = false
  end
end

local function EnsureTicker()
  if state.ticker then
    return
  end

  if C_Timer and C_Timer.NewTicker then
    state.ticker = C_Timer.NewTicker(0.1, TickBreathTimer)
  else
    frame:SetScript("OnUpdate", function(_, elapsed)
      TickBreathTimer(elapsed)
    end)
  end
end

local function StartBreathTimer(value, max, scale, paused)
  state.active = true
  state.value = value or 0
  state.max = max or 0
  state.scale = scale or -1
  state.paused = paused == 1 or paused == true
  state.lastRemaining = ComputeRemaining(state.value, state.max, state.scale)
  state.lastUpdateTime = GetTime()
  ResetPlayed()
  EnsureTicker()
end

local function StopBreathTimer()
  state.active = false
  state.paused = false
  state.lastRemaining = 0
  state.lastUpdateTime = 0
  if state.ticker then
    state.ticker:Cancel()
    state.ticker = nil
  end
end

local function FindBreathTimer()
  if not GetMirrorTimerInfo or not MIRRORTIMER_NUMTIMERS then
    return
  end
  for i = 1, MIRRORTIMER_NUMTIMERS do
    local timer, value, maxvalue, scale, paused = GetMirrorTimerInfo(i)
    if timer == "BREATH" then
      StartBreathTimer(value, maxvalue, scale, paused)
      return
    end
  end
end

frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("MIRROR_TIMER_START")
frame:RegisterEvent("MIRROR_TIMER_STOP")
frame:RegisterEvent("MIRROR_TIMER_PAUSE")

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local name = ...
    if name == addonName then
      InitializeSettings()
    end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    FindBreathTimer()
    return
  end

  if event == "MIRROR_TIMER_START" then
    local timer, value, maxvalue, scale, paused = ...
    if timer == "BREATH" then
      StartBreathTimer(value, maxvalue, scale, paused)
    end
    return
  end

  if event == "MIRROR_TIMER_STOP" then
    local timer = ...
    if timer == "BREATH" then
      StopBreathTimer()
    end
    return
  end

  if event == "MIRROR_TIMER_PAUSE" then
    local timer, paused = ...
    if timer == "BREATH" then
      state.paused = paused == 1 or paused == true
      state.lastUpdateTime = GetTime()
    end
  end
end)

SLASH_SUBNAUTICA1 = "/soa"
SlashCmdList.SUBNAUTICA = function(msg)
  msg = msg and msg:lower() or ""
  if msg == "test" then
    print("Subnautica: playing test sound")
    PlaySound("oxygen_50.ogg")
    return
  end
  if msg == "config" or msg == "settings" then
    OpenConfig()
    return
  end
  print("Subnautica: commands: /soa test, /soa config")
end
