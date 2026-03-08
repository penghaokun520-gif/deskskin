Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ResolvedFilePath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $p = $Path.Trim().Trim('"')
    if ($p -match "^(.*?cloudmusic\.exe),\d+$") {
        $p = $matches[1]
    }

    $p = [Environment]::ExpandEnvironmentVariables($p)
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        return $null
    }

    if ([System.IO.Path]::GetFileName($p).ToLowerInvariant() -ne "cloudmusic.exe") {
        return $null
    }

    return (Resolve-Path -LiteralPath $p).Path
}

function Try-Path {
    param([string]$Path)

    $resolved = Get-ResolvedFilePath -Path $Path
    if ($resolved) {
        return $resolved
    }

    return $null
}

function Try-RunningProcess {
    $processes = Get-Process -Name cloudmusic -ErrorAction SilentlyContinue
    foreach ($p in $processes) {
        try {
            $resolved = Try-Path -Path $p.Path
            if ($resolved) {
                return $resolved
            }
        } catch {
        }
    }

    return $null
}

function Try-AppPaths {
    $keys = @(
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cloudmusic.exe",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cloudmusic.exe",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\cloudmusic.exe"
    )

    foreach ($key in $keys) {
        try {
            $item = Get-Item -LiteralPath $key -ErrorAction SilentlyContinue
            if (-not $item) {
                continue
            }

            $defaultValue = $item.GetValue("")
            $resolved = Try-Path -Path $defaultValue
            if ($resolved) {
                return $resolved
            }
        } catch {
        }
    }

    return $null
}

function Try-UninstallKeys {
    $roots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($root in $roots) {
        $subKeys = Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue
        foreach ($k in $subKeys) {
            try {
                $props = Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction SilentlyContinue
                $name = [string]$props.DisplayName
                if ([string]::IsNullOrWhiteSpace($name)) {
                    continue
                }

                $nameLc = $name.ToLowerInvariant()
                if ($nameLc -notlike "*cloudmusic*" -and $nameLc -notlike "*netease*") {
                    continue
                }

                $resolved = $null
                if ($props.InstallLocation) {
                    $resolved = Try-Path -Path (Join-Path ([string]$props.InstallLocation) "cloudmusic.exe")
                }
                if (-not $resolved -and $props.DisplayIcon) {
                    $resolved = Try-Path -Path ([string]$props.DisplayIcon)
                }
                if ($resolved) {
                    return $resolved
                }
            } catch {
            }
        }
    }

    return $null
}

function Try-Shortcuts {
    $shortcutRoots = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
        "$env:USERPROFILE\Desktop",
        "$env:PUBLIC\Desktop"
    )

    $wsh = New-Object -ComObject WScript.Shell

    foreach ($root in $shortcutRoots) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            continue
        }

        $links = Get-ChildItem -LiteralPath $root -Filter *.lnk -Recurse -ErrorAction SilentlyContinue
        foreach ($lnk in $links) {
            $nameLc = $lnk.Name.ToLowerInvariant()
            if ($nameLc -notlike "*cloudmusic*" -and $nameLc -notlike "*netease*") {
                continue
            }

            try {
                $target = $wsh.CreateShortcut($lnk.FullName).TargetPath
                $resolved = Try-Path -Path $target
                if ($resolved) {
                    return $resolved
                }
            } catch {
            }
        }
    }

    return $null
}

function Try-KnownPaths {
    $paths = @(
        "$env:ProgramFiles\NetEase\CloudMusic\cloudmusic.exe",
        "$env:ProgramFiles(x86)\NetEase\CloudMusic\cloudmusic.exe",
        "$env:LOCALAPPDATA\Programs\cloudmusic\cloudmusic.exe",
        "$env:LOCALAPPDATA\Netease\CloudMusic\cloudmusic.exe",
        "C:\Program Files\NetEase\CloudMusic\cloudmusic.exe",
        "C:\Program Files (x86)\NetEase\CloudMusic\cloudmusic.exe",
        "D:\NetEase\CloudMusic\cloudmusic.exe",
        "D:\CloudMusic\cloudmusic.exe",
        "E:\NetEase\CloudMusic\cloudmusic.exe",
        "E:\CloudMusic\cloudmusic.exe"
    )

    foreach ($p in $paths) {
        $resolved = Try-Path -Path $p
        if ($resolved) {
            return $resolved
        }
    }

    return $null
}

$found = $null

$steps = @(
    ${function:Try-RunningProcess},
    ${function:Try-AppPaths},
    ${function:Try-UninstallKeys},
    ${function:Try-Shortcuts},
    ${function:Try-KnownPaths}
)

foreach ($step in $steps) {
    $found = & $step
    if ($found) {
        break
    }
}

if ($found) {
    Write-Output $found
    exit 0
}

exit 1
