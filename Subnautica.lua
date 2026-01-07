local addonName = ...
local frame

local SOUND_PATH = "Interface\\AddOns\\" .. addonName .. "\\src\\"
local SOUND_CHANNEL = "SFX"

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

local function PlaySound(name)
  local path = SOUND_PATH .. name
  local handle = PlaySoundFile(path, SOUND_CHANNEL)
  if not handle then
    handle = PlaySoundFile(path, "Master")
  end
  if not handle then
    handle = PlaySoundFile(path)
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
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("MIRROR_TIMER_START")
frame:RegisterEvent("MIRROR_TIMER_STOP")
frame:RegisterEvent("MIRROR_TIMER_PAUSE")

frame:SetScript("OnEvent", function(_, event, ...)
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

SLASH_SUBNAUTICA1 = "/subnautica"
SlashCmdList.SUBNAUTICA = function(msg)
  msg = msg and msg:lower() or ""
  if msg == "test" then
    print("Subnautica: playing test sound")
    PlaySound("oxygen_50.ogg")
    return
  end
  print("Subnautica: commands: /subnautica test")
end
