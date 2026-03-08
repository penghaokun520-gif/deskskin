Option Explicit

Dim sh, fso, curPath, ps1Path, cmd

Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

curPath = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path = fso.BuildPath(curPath, "update.ps1")

cmd = "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1Path & """"
sh.Run cmd, 0, False
