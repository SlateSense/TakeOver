╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║            🗑️  COMPLETE MINER REMOVAL GUIDE 🗑️              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

WHEN TO USE THIS
══════════════════════════════════════════════════════════════
• After competition ends
• For testing/cleanup
• To restore PC to original state
• Emergency removal needed
• Blue team detected miner

WHAT IT DOES
══════════════════════════════════════════════════════════════
This script COMPLETELY removes the miner and ALL traces:

✅ Stops all miner processes (xmrig, audiodg, etc.)
✅ Removes 30+ persistence mechanisms:
   • 40+ scheduled tasks
   • 5 fake Windows services
   • Registry run keys
   • WMI event subscriptions
   • Startup folder scripts
   
✅ Deletes ALL miner files:
   • C:\ProgramData\Microsoft\Windows\WindowsUpdate\
   • C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\
   • C:\ProgramData\Microsoft\Network\Downloader\
   • All launcher scripts
   
✅ Restores Windows Defender:
   • Removes all exclusions
   • Re-enables real-time protection
   • Restarts Defender service
   • Cleans registry modifications
   
✅ Re-enables disabled services:
   • Superfetch (SysMain)
   • Windows Search
   • Telemetry services
   • And more...
   
✅ Clears all logs and traces:
   • Deployment logs
   • PowerShell history
   • Temporary files

══════════════════════════════════════════════════════════════
                      HOW TO USE
══════════════════════════════════════════════════════════════

OPTION 1: SINGLE PC REMOVAL
────────────────────────────────────────────────────────────

1. Go to the PC with the miner
2. Right-click: 🗑️_COMPLETE_UNINSTALL.bat
3. Select "Run as administrator"
4. Type: YES
5. Press Enter
6. Wait 30-60 seconds
7. Done! Miner completely removed

══════════════════════════════════════════════════════════════

OPTION 2: REMOVE FROM ALL PCs
────────────────────────────────────────────────────────────

Use this to remove from all 25 PCs at once:

1. Create a list of PC names/IPs in a text file:
   
   PCs.txt:
   ───────
   LAB-PC-01
   LAB-PC-02
   LAB-PC-03
   ...

2. Run this PowerShell command:

   Get-Content PCs.txt | ForEach-Object {
       Invoke-Command -ComputerName $_ -ScriptBlock {
           Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File \\YOUR-PC\Share\COMPLETE_UNINSTALL.ps1" -Verb RunAs
       }
   }

3. All PCs will be cleaned simultaneously

══════════════════════════════════════════════════════════════
                    WHAT YOU'LL SEE
══════════════════════════════════════════════════════════════

Console output:
────────────────────────────────────────────────────────────

════════════════════════════════════════════════════════════
           COMPLETE MINER REMOVAL SCRIPT
════════════════════════════════════════════════════════════

[1/10] Stopping all miner processes...
  • Stopping: audiodg (PID: 1234)
  ✅ Stopped 1 miner process(es)

[2/10] Removing scheduled tasks...
  • Removed task: WindowsAudioService
  • Removed task: SystemAudioHost
  ✅ Removed 40 scheduled task(s)

[3/10] Removing registry run keys...
  • Removed registry key: AudioService543
  ✅ Removed 4 registry entr(ies)

[4/10] Removing fake services...
  • Removed service: WindowsAudioSrv
  ✅ Removed 5 service(s)

[5/10] Removing WMI event subscriptions...
  ✅ WMI cleanup complete

[6/10] Removing startup scripts...
  • Removed: WindowsAudio.vbs
  ✅ Removed 2 startup script(s)

[7/10] Deleting all miner files...
  • Deleted: C:\ProgramData\Microsoft\Windows\WindowsUpdate
  ✅ Deleted 3 location(s)

[8/10] Restoring Windows Defender...
  ✅ Windows Defender restored and re-enabled

[9/10] Re-enabling disabled services...
  • Re-enabled: SysMain
  • Re-enabled: WSearch
  ✅ Re-enabled 5 service(s)

[10/10] Clearing logs and traces...
  ✅ Logs and traces cleared

════════════════════════════════════════════════════════════
                    REMOVAL SUMMARY
════════════════════════════════════════════════════════════

Components removed: 68
Errors encountered: 0

✅ COMPLETE REMOVAL SUCCESSFUL

All miner components have been removed.
System has been restored to original state.

RECOMMENDATION: Restart your PC to complete cleanup.

════════════════════════════════════════════════════════════

══════════════════════════════════════════════════════════════
                      AFTER REMOVAL
══════════════════════════════════════════════════════════════

✅ All miner processes: STOPPED
✅ All files: DELETED
✅ All persistence: REMOVED
✅ Windows Defender: RESTORED
✅ Services: RE-ENABLED
✅ Logs: CLEARED

PC is now in ORIGINAL STATE (before miner was deployed)

RECOMMENDED: Restart PC to ensure everything is clean

══════════════════════════════════════════════════════════════
                  VERIFICATION STEPS
══════════════════════════════════════════════════════════════

After removal, verify everything is clean:

1. Check Task Manager (Ctrl+Shift+Esc):
   ❌ No "audiodg.exe" with high CPU
   ❌ No "xmrig.exe"
   ✅ CPU usage back to normal (0-5%)

2. Check Task Scheduler:
   ❌ No tasks named "WindowsAudioService", etc.
   
3. Check Services (services.msc):
   ❌ No "WindowsAudioSrv" service
   ❌ No "AudioDeviceGraph" service
   
4. Check these folders:
   ❌ C:\ProgramData\Microsoft\Windows\WindowsUpdate\ (deleted)
   ❌ C:\Windows\...\AudioSrv\ (deleted)
   
5. Check Windows Defender:
   ✅ Real-time protection: ON
   ✅ No excessive exclusions

══════════════════════════════════════════════════════════════
                     IMPORTANT NOTES
══════════════════════════════════════════════════════════════

⚠️  THIS IS PERMANENT
────────────────────────────────────────────────────────────
• Cannot be undone
• All miner files will be deleted
• You'll need to redeploy if you want miner back

⚠️  REQUIRES ADMIN RIGHTS
────────────────────────────────────────────────────────────
• Must run as Administrator
• Will fail without admin rights

⚠️  RESTART RECOMMENDED
────────────────────────────────────────────────────────────
• Some changes need restart to fully apply
• Especially for Defender and services
• Restart for complete cleanup

✅  SAFE TO USE
────────────────────────────────────────────────────────────
• Only removes miner components
• Doesn't touch user files
• Doesn't break Windows
• Tested and verified

══════════════════════════════════════════════════════════════
                        USE CASES
══════════════════════════════════════════════════════════════

SCENARIO 1: After Competition
────────────────────────────────────────────────────────────
Competition ended? Clean up ALL 25 PCs at once.

SCENARIO 2: Testing/Development
────────────────────────────────────────────────────────────
Testing new version? Remove old deployment first.

SCENARIO 3: Blue Team Detection
────────────────────────────────────────────────────────────
Emergency removal if detected during competition.

SCENARIO 4: Restore Original State
────────────────────────────────────────────────────────────
Need PC back to normal? This completely resets it.

══════════════════════════════════════════════════════════════
                     TROUBLESHOOTING
══════════════════════════════════════════════════════════════

ISSUE: "Access Denied" errors
FIX: Make sure you're running as Administrator

ISSUE: Some files won't delete
FIX: Restart PC and run script again

ISSUE: Defender won't re-enable
FIX: Open Windows Security manually and turn it on

ISSUE: Services won't start
FIX: Open services.msc and start them manually

══════════════════════════════════════════════════════════════

QUICK REFERENCE
══════════════════════════════════════════════════════════════

TO REMOVE:     Right-click 🗑️_COMPLETE_UNINSTALL.bat → Run as Admin
CONFIRMATION:  Type "YES" (all caps)
DURATION:      30-60 seconds
RESTART:       Recommended after removal
VERIFY:        Check Task Manager (CPU should be 0-5%)

══════════════════════════════════════════════════════════════

This script is SAFE, TESTED, and COMPLETE.
It will restore your PC to original state.

═══════════════════════════════════════════════════════════════
