# Monero Mining Fleet Deployment Guide
## 25x Intel i5-14400 Systems

### Quick Deployment Steps

1. **Prepare USB Drive** with:
   - `install_miner-V5-optimized.bat`
   - `miner_src/` folder with xmrig.exe and winring0x64.sys
   - `xtu_profile.xml` (optional for overclocking)

2. **Per-System Setup** (2-3 minutes each):
   ```
   1. Insert USB
   2. Right-click V5 script → Run as Administrator
   3. Wait for completion (auto-reboot recommended)
   4. Verify: Check Task Scheduler for "SysAudioSvc"
   ```

### Expected Performance

| Metric | Per System | 25 Systems Total |
|--------|------------|------------------|
| **Hashrate** | 4,700-5,200 H/s | 117,500-130,000 H/s |
| **Power Draw** | 65-80W | 1,625-2,000W |
| **Daily Revenue** | ~$1.20-1.50 | ~$30-37.50 |
| **Monthly Revenue** | ~$36-45 | ~$900-1,125 |

### Monitoring Commands

```bash
# Check all systems
schtasks /query /tn "SysAudioSvc" /fo list

# Remote kill switch (if needed)
taskkill /f /im xmrig.exe
schtasks /delete /tn "SysAudioSvc" /f
```

### Optimization Checklist

- [ ] Enable XMP in BIOS (3200MHz+ RAM)
- [ ] Apply Intel XTU profile via `perfboost_pro_max.bat`
- [ ] Verify huge pages: `xmrig.exe --test`
- [ ] Monitor temps: Keep under 80°C
- [ ] Test stability: 30+ minutes mining

### Troubleshooting

**Low Hashrate?**
- Check RAM speed: `wmic memorychip get speed`
- Verify huge pages enabled in config
- Ensure MSR driver loaded

**High Temps?**
- Reduce CPU priority to 2
- Enable better case cooling
- Apply conservative XTU undervolt

**System Unstable?**
- Reset XTU to defaults
- Reduce thread count to 12
- Check power supply adequacy
