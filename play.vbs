Option Explicit

Dim WshShell, Fso, CnFolder, Candidates, FoundPath, CandidatePath

Set WshShell = WScript.CreateObject("WScript.Shell")
Set Fso = CreateObject("Scripting.FileSystemObject")

' Build the Chinese folder name using Unicode code points.
CnFolder = ChrW(&H7F51) & ChrW(&H6613) & ChrW(&H4E91)

Candidates = Array( _
    "D:\" & CnFolder & "\CloudMusic\cloudmusic.exe", _
    "D:\" & CnFolder & "\cloudmusic.exe", _
    WshShell.ExpandEnvironmentStrings("%ProgramFiles%\NetEase\CloudMusic\cloudmusic.exe"), _
    WshShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%\NetEase\CloudMusic\cloudmusic.exe"), _
    WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%\Programs\cloudmusic\cloudmusic.exe"), _
    "C:\Program Files\NetEase\CloudMusic\cloudmusic.exe", _
    "C:\Program Files (x86)\NetEase\CloudMusic\cloudmusic.exe" _
)

FoundPath = ""
For Each CandidatePath In Candidates
    If Fso.FileExists(CandidatePath) Then
        FoundPath = CandidatePath
        Exit For
    End If
Next

If FoundPath <> "" Then
    WshShell.Run """" & FoundPath & """", 1, False
Else
    MsgBox "cloudmusic.exe not found. Please update candidate paths in play.vbs.", vbExclamation, "CloudMusic launch failed"
End If
