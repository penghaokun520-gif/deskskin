Option Explicit

Dim WshShell, CnTitle
Set WshShell = WScript.CreateObject("WScript.Shell")

CnTitle = ChrW(&H7F51) & ChrW(&H6613) & ChrW(&H4E91) & ChrW(&H97F3) & ChrW(&H4E50)

WshShell.AppActivate "CloudMusic"
WshShell.AppActivate CnTitle
WScript.Sleep 50

' Try global shortcut first, then local shortcut fallback.
WshShell.SendKeys "^%{RIGHT}"
WScript.Sleep 40
WshShell.SendKeys "^{RIGHT}"
