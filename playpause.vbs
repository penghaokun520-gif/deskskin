Option Explicit

Dim WshShell, CnTitle
Set WshShell = WScript.CreateObject("WScript.Shell")

CnTitle = ChrW(&H7F51) & ChrW(&H6613) & ChrW(&H4E91) & ChrW(&H97F3) & ChrW(&H4E50)

WshShell.AppActivate "CloudMusic"
WshShell.AppActivate CnTitle
WScript.Sleep 50

' Try CloudMusic global shortcut first.
WshShell.SendKeys "^%p"
WScript.Sleep 40

' Local fallback for some builds.
WshShell.SendKeys " "
