Set WshShell = CreateObject("WScript.Shell")

' Get the directory where this script is located
scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)

' Run PowerShell completely invisible
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& '" & scriptDir & "\single_instance_manager.ps1' -Startup""", 0, False
