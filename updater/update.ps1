param(
    [switch]$Auto,
    [string]$Repo = "penghaokun520-gif/deskskin"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$skinRoot = Split-Path -Path $scriptRoot -Parent
if (-not (Test-Path -LiteralPath (Join-Path $skinRoot "version.json"))) {
    $skinRoot = $scriptRoot
}

$localVersionFile = Join-Path $skinRoot "version.json"
$repoName = ($Repo -split "/")[-1]
$releaseApiUrl = "https://api.github.com/repos/$Repo/releases/latest"

function Show-Message {
    param(
        [string]$Text,
        [string]$Title = "Skin Update",
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )

    if ($Auto) {
        return
    }

    [System.Windows.Forms.MessageBox]::Show(
        $Text,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    ) | Out-Null
}

function Confirm-Update {
    param([string]$Text)

    if ($Auto) {
        return $true
    }

    $result = [System.Windows.Forms.MessageBox]::Show(
        $Text,
        "Skin Update",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

function To-Version {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [Version]"0.0.0"
    }

    $clean = $Value.Trim().TrimStart("v", "V")
    if ($clean -match "^(\d+\.\d+\.\d+(?:\.\d+)?)") {
        $clean = $matches[1]
    }

    try {
        return [Version]$clean
    } catch {
        return [Version]"0.0.0"
    }
}

function Get-LatestRelease {
    $headers = @{
        "Accept"     = "application/vnd.github+json"
        "User-Agent" = "deskskin-updater"
    }

    try {
        $release = Invoke-RestMethod -Uri $releaseApiUrl -Headers $headers -Method Get
    } catch {
        throw "Cannot read GitHub latest release. Publish at least one release first."
    }

    if ($null -eq $release) {
        throw "GitHub latest release response is empty."
    }

    if ([string]::IsNullOrWhiteSpace([string]$release.tag_name)) {
        throw "GitHub latest release has no tag_name."
    }

    if ([string]::IsNullOrWhiteSpace([string]$release.zipball_url)) {
        throw "GitHub latest release has no zipball_url."
    }

    return $release
}

function Read-LocalVersion {
    if (-not (Test-Path -LiteralPath $localVersionFile)) {
        return "0.0.0"
    }

    try {
        $localMeta = Get-Content -Raw -LiteralPath $localVersionFile | ConvertFrom-Json
        if ($null -eq $localMeta.version) {
            return "0.0.0"
        }

        return [string]$localMeta.version
    } catch {
        return "0.0.0"
    }
}

function Refresh-Rainmeter {
    $rainmeter = Get-Command Rainmeter.exe -ErrorAction SilentlyContinue
    if ($null -ne $rainmeter) {
        Start-Process -FilePath $rainmeter.Source -ArgumentList "!RefreshApp" -WindowStyle Hidden | Out-Null
    }
}

$tempDir = Join-Path $env:TEMP ("deskskin_update_" + [Guid]::NewGuid().ToString("N"))

try {
    $localVersionText = Read-LocalVersion
    $localVersion = To-Version $localVersionText

    $releaseMeta = Get-LatestRelease
    $remoteVersionText = [string]$releaseMeta.tag_name
    $remoteVersion = To-Version $remoteVersionText
    $zipUrl = [string]$releaseMeta.zipball_url

    if ($remoteVersion -le $localVersion) {
        Show-Message "Already up to date.`nLocal version: $localVersionText`nLatest release: $remoteVersionText"
        exit 0
    }

    $confirmText = "New release found: $remoteVersionText`nCurrent version: $localVersionText`n`nUpdate now?"
    if (-not (Confirm-Update -Text $confirmText)) {
        exit 0
    }

    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $zipPath = Join-Path $tempDir "deskskin.zip"

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -LiteralPath $zipPath -DestinationPath $tempDir -Force

    $repoFolder = Join-Path $tempDir "$repoName-$($remoteVersionText.TrimStart('v', 'V'))"
    if (-not (Test-Path -LiteralPath $repoFolder)) {
        $matched = Get-ChildItem -LiteralPath $tempDir -Directory | Where-Object { $_.Name -like "$repoName-*" } | Select-Object -First 1
        if ($null -eq $matched) {
            throw "Cannot find the extracted repository folder."
        }
        $repoFolder = $matched.FullName
    }

    $copyLog = Join-Path $tempDir "copy.log"
    & robocopy $repoFolder $skinRoot /E /R:2 /W:1 /NFL /NDL /NP /NJH /NJS /XD ".git" ".github" /LOG:$copyLog | Out-Null
    $rc = $LASTEXITCODE
    if ($rc -ge 8) {
        $logText = ""
        if (Test-Path -LiteralPath $copyLog) {
            $logText = Get-Content -Raw -LiteralPath $copyLog
        }
        throw "File copy failed (robocopy exit code: $rc). $logText"
    }

    Refresh-Rainmeter
    Show-Message "Update completed.`nCurrent version: $remoteVersionText"
} catch {
    Show-Message "Update failed: $($_.Exception.Message)" "Skin Update Failed" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
} finally {
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
