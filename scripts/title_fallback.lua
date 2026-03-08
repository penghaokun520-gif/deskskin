-- Display logic:
-- 1) While playing: prefer lyric line, fallback to song title.
-- 2) While paused / stopped: show song title.
-- 3) If plugin title is empty: fallback to CloudMusic window title.

local currentText = "CloudMusic"
local currentTitle = "CloudMusic"
local tick = 0
local pollInterval = 2

local function isGenericAppTitle(s)
    if not s then
        return true
    end

    local x = s:gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if x == "" then
        return true
    end

    if x == "cloudmusic" then
        return true
    end

    if x == "netease cloud music" then
        return true
    end

    if x == "wang yi yun yin yue" then
        return true
    end

    if x:find("cloudmusic", 1, true) == 1 then
        return true
    end

    return false
end

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

local function sanitizeTitle(s)
    s = trim(s)
    if s == "" or s == "0" then
        return ""
    end

    if isGenericAppTitle(s) then
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

    local pluginTitle = sanitizeTitle(getMeasureString("MeasureTitlePlugin"))

    -- Window title is usually the most accurate track title for CloudMusic.
    if tick % pollInterval == 0 then
        local fallbackTitle = queryWindowTitle()
        fallbackTitle = sanitizeTitle(fallbackTitle)
        if fallbackTitle ~= "" then
            currentTitle = fallbackTitle
        elseif pluginTitle ~= "" then
            currentTitle = pluginTitle
        end
    elseif pluginTitle ~= "" and isGenericAppTitle(currentTitle) then
        currentTitle = pluginTitle
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
