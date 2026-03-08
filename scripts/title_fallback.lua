-- Display logic:
-- 1) While playing: prefer lyric line, fallback to song title.
-- 2) While paused / stopped: show song title.
-- 3) If plugin title is empty: fallback to CloudMusic window title.

local currentText = "CloudMusic"
local currentTitle = "CloudMusic"
local tick = 0
local pollInterval = 2

local function trim(s)
    if not s then
        return ""
    end
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

local function sanitizeLyric(s)
    s = trim(s)
    if s == "" or s == "0" then
        return ""
    end

    s = s:gsub("[\r\n]+", " ")
    s = s:gsub("^%[[0-9:%.%s]+%]%s*", "")
    s = trim(s)

    if s == "" or s == "0" then
        return ""
    end

    return s
end

local function queryWindowTitle()
    local cmd = [[powershell -NoProfile -WindowStyle Hidden -Command "(Get-Process cloudmusic -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne '' } | Select-Object -First 1 -ExpandProperty MainWindowTitle)"]]
    local pipe = io.popen(cmd)
    if not pipe then
        return ""
    end

    local output = pipe:read("*a") or ""
    pipe:close()

    output = trim(output)
    if output == "" then
        return ""
    end

    return output
end

local function getMeasureString(measureName)
    local m = SKIN:GetMeasure(measureName)
    if not m then
        return ""
    end

    return trim(m:GetStringValue())
end

local function getStateNumber()
    local stateMeasure = SKIN:GetMeasure("MeasureState")
    if not stateMeasure then
        return -1
    end

    local n = tonumber(stateMeasure:GetValue())
    if n then
        return n
    end

    local text = trim(stateMeasure:GetStringValue())
    n = tonumber(text)
    if n then
        return n
    end

    return -1
end

function Initialize()
    currentText = "CloudMusic"
    currentTitle = "CloudMusic"
    tick = 0
end

function Update()
    tick = tick + 1

    local playingStateValue = tonumber(SKIN:GetVariable("PlayingStateValue")) or 1
    local stateValue = getStateNumber()

    local pluginTitle = getMeasureString("MeasureTitlePlugin")
    if pluginTitle ~= "" and pluginTitle ~= "0" then
        currentTitle = pluginTitle
    elseif tick % pollInterval == 0 then
        local fallbackTitle = queryWindowTitle()
        if fallbackTitle ~= "" then
            currentTitle = fallbackTitle
        end
    end

    if currentTitle == "" then
        currentTitle = "CloudMusic"
    end

    if stateValue == playingStateValue then
        local lyric = sanitizeLyric(getMeasureString("MeasureLyricPlugin"))
        if lyric ~= "" then
            currentText = lyric
        else
            currentText = currentTitle
        end
    else
        currentText = currentTitle
    end

    return 0
end

function GetStringValue()
    return currentText
end
