Option Explicit

Dim WshShell, Fso, ScriptDir, ResolverScript, CachePath, FoundPath
Set WshShell = WScript.CreateObject("WScript.Shell")
Set Fso = CreateObject("Scripting.FileSystemObject")

ScriptDir = Fso.GetParentFolderName(WScript.ScriptFullName)
ResolverScript = Fso.BuildPath(ScriptDir, "resolve_cloudmusic_path.ps1")
CachePath = Fso.BuildPath(ScriptDir, "cloudmusic_path.cache")

Function TrimText(ByVal s)
    s = Replace(s, vbCr, "")
    s = Replace(s, vbLf, "")
    TrimText = Trim(s)
End Function

Function TryReadCache()
    Dim ts, p
    TryReadCache = ""

    If Not Fso.FileExists(CachePath) Then
        Exit Function
    End If

    On Error Resume Next
    Set ts = Fso.OpenTextFile(CachePath, 1, False)
    p = ""
    If Err.Number = 0 Then
        p = TrimText(ts.ReadAll)
        ts.Close
    End If
    On Error GoTo 0

    If p <> "" Then
        If Fso.FileExists(p) Then
            TryReadCache = p
        End If
    End If
End Function

Sub SaveCache(ByVal p)
    Dim ts
    On Error Resume Next
    Set ts = Fso.OpenTextFile(CachePath, 2, True)
    If Err.Number = 0 Then
        ts.Write p
        ts.Close
    End If
    On Error GoTo 0
End Sub

Function TryResolveByPlugin()
    Dim cmd, execObj, outputText
    TryResolveByPlugin = ""

    If Not Fso.FileExists(ResolverScript) Then
        Exit Function
    End If

    cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File """ & ResolverScript & """"

    On Error Resume Next
    Set execObj = WshShell.Exec(cmd)
    If Err.Number <> 0 Then
        Err.Clear
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0

    outputText = TrimText(execObj.StdOut.ReadAll)
    If outputText <> "" Then
        If Fso.FileExists(outputText) Then
            TryResolveByPlugin = outputText
        End If
    End If
End Function

Function TryKnownCandidates()
    Dim candidates, cnFolder, candidatePath
    TryKnownCandidates = ""

    cnFolder = ChrW(&H7F51) & ChrW(&H6613) & ChrW(&H4E91)
    candidates = Array( _
        "D:\" & cnFolder & "\CloudMusic\cloudmusic.exe", _
        "D:\" & cnFolder & "\cloudmusic.exe", _
        WshShell.ExpandEnvironmentStrings("%ProgramFiles%\NetEase\CloudMusic\cloudmusic.exe"), _
        WshShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%\NetEase\CloudMusic\cloudmusic.exe"), _
        WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%\Programs\cloudmusic\cloudmusic.exe"), _
        WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%\Netease\CloudMusic\cloudmusic.exe"), _
        "C:\Program Files\NetEase\CloudMusic\cloudmusic.exe", _
        "C:\Program Files (x86)\NetEase\CloudMusic\cloudmusic.exe" _
    )

    For Each candidatePath In candidates
        If Fso.FileExists(candidatePath) Then
            TryKnownCandidates = candidatePath
            Exit Function
        End If
    Next
End Function

FoundPath = TryReadCache()
If FoundPath = "" Then
    FoundPath = TryResolveByPlugin()
End If
If FoundPath = "" Then
    FoundPath = TryKnownCandidates()
End If

If FoundPath <> "" Then
    SaveCache FoundPath
    WshShell.Run """" & FoundPath & """", 1, False
Else
    MsgBox "cloudmusic.exe not found. Auto path resolver failed on this machine.", vbExclamation, "CloudMusic launch failed"
End If
