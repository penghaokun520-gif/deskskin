-- Prefer MusicPlayer plugin title; fallback to CloudMusic main window title.

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

function Initialize()
    currentTitle = "CloudMusic"
    tick = 0
end

function Update()
    tick = tick + 1

    local pluginMeasure = SKIN:GetMeasure("MeasureTitlePlugin")
    local pluginTitle = ""
    if pluginMeasure then
        pluginTitle = trim(pluginMeasure:GetStringValue())
    end

    if pluginTitle ~= "" and pluginTitle ~= "0" then
        currentTitle = pluginTitle
        return 0
    end

    if tick % pollInterval == 0 then
        local fallbackTitle = queryWindowTitle()
        if fallbackTitle ~= "" then
            currentTitle = fallbackTitle
        else
            currentTitle = "CloudMusic"
        end
    end

    return 0
end

function GetStringValue()
    return currentTitle
end
