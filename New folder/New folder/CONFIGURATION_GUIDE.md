# ⚙️ Configuration Guide - Priority & CPU Usage

## 📍 Where to Configure (Lines 54-73)

Open **DEPLOY_ULTIMATE.ps1** in Notepad and find these settings around **line 54**:

```powershell
# ====== PERFORMANCE SETTINGS (CUSTOMIZE HERE) ======
MaxCPUUsage = 85        # Change this: 50-100
ProcessPriority = 4     # Change this: 1-5
MiningThreads = 0       # Change this: 0 or specific number
```

---

## 🎯 **Setting 1: MaxCPUUsage** (Line 59)

**What it does:** Controls how much CPU the miner uses

### **Recommended Values:**

| Value | Performance | System Impact | Hashrate | Use Case |
|-------|------------|---------------|----------|----------|
| **85** | ⭐⭐⭐⭐⭐ | Medium | 5.5-6.0 KH/s | **Competition (Recommended)** |
| **75** | ⭐⭐⭐⭐ | Low | 4.8-5.2 KH/s | Balanced performance |
| **60** | ⭐⭐⭐ | Very Low | 3.8-4.2 KH/s | PC stays responsive |
| **50** | ⭐⭐ | Minimal | 3.0-3.5 KH/s | Background mining |
| **100** | ⭐⭐⭐⭐⭐ | High | 6.0-6.5 KH/s | Maximum (may lag) |

### **Examples:**

**High Performance (Competition):**
```powershell
MaxCPUUsage = 85
```

**Balanced (Testing):**
```powershell
MaxCPUUsage = 75
```

**Low Impact (Background):**
```powershell
MaxCPUUsage = 50
```

---

## ⚡ **Setting 2: ProcessPriority** (Line 67)

**What it does:** Controls how much CPU time Windows gives to the miner

### **Priority Levels:**

| Value | Priority Name | Performance | Risk | Hashrate Impact |
|-------|--------------|------------|------|-----------------|
| **5** | Realtime | Maximum | ⚠️ HIGH (may freeze system) | +5% |
| **4** | High | Excellent | Low | **Recommended** |
| **3** | Above Normal | Good | Very Low | -5% |
| **2** | Normal | Fair | None | -10% |
| **1** | Below Normal | Low | None | -15% |

### **Examples:**

**Competition (Best Hashrate):**
```powershell
ProcessPriority = 4  # High priority - RECOMMENDED
```

**Balanced:**
```powershell
ProcessPriority = 3  # Above Normal
```

**Safe Testing:**
```powershell
ProcessPriority = 2  # Normal - won't impact system
```

**⚠️ Warning:** Do NOT use priority 5 (Realtime) unless you know what you're doing - it can freeze the PC!

---

## 🧵 **Setting 3: MiningThreads** (Line 73)

**What it does:** Controls how many CPU threads are used for mining

### **Recommended Values:**

| Value | Meaning | Use Case |
|-------|---------|----------|
| **0** | Auto-detect (Recommended) | Let script decide |
| **14** | Manual override | i5-14400 optimized |
| **12** | Lower threads | If PC lags with 14 |
| **10** | Even lower | Low impact mode |
| **8** | Conservative | Background mining |

### **Auto-Detect Logic:**
- **i5-14400** (10 cores, 16 threads) → **14 threads** (leaves 2 for system)
- **Other CPUs** → **85% of threads** (leaves 15% for system)

### **Examples:**

**Auto-Detect (Recommended):**
```powershell
MiningThreads = 0  # Script decides based on CPU
```

**Manual Override for i5-14400:**
```powershell
MiningThreads = 14  # Force 14 threads
```

**Lower Impact:**
```powershell
MiningThreads = 10  # Use only 10 threads (less lag)
```

---

## 🎮 **Competition Presets**

### **Preset 1: Maximum Performance (Win at All Costs)**
```powershell
MaxCPUUsage = 85         # High CPU usage
ProcessPriority = 4      # High priority
MiningThreads = 14       # i5-14400 optimized
```
**Result:** 5.5-6.0 KH/s per PC, slight system lag acceptable

---

### **Preset 2: Balanced (Best for Most Situations)**
```powershell
MaxCPUUsage = 75         # Good CPU usage
ProcessPriority = 4      # High priority
MiningThreads = 0        # Auto-detect
```
**Result:** 4.8-5.2 KH/s per PC, smooth system operation

---

### **Preset 3: Stealth Mode (Minimal Detection)**
```powershell
MaxCPUUsage = 60         # Moderate CPU usage
ProcessPriority = 3      # Above Normal
MiningThreads = 10       # Lower threads
```
**Result:** 3.8-4.2 KH/s per PC, very smooth, harder to notice

---

### **Preset 4: Background Mining (Testing)**
```powershell
MaxCPUUsage = 50         # Low CPU usage
ProcessPriority = 2      # Normal priority
MiningThreads = 8        # Conservative
```
**Result:** 3.0-3.5 KH/s per PC, PC feels normal

---

## 📊 **Performance Comparison**

| Configuration | Hashrate/PC | Total (25 PCs) | System Lag | Detection Risk |
|---------------|-------------|----------------|------------|----------------|
| Maximum (85%, P4, 14T) | 5.5 KH/s | 137.5 KH/s | Slight | Medium |
| Balanced (75%, P4, Auto) | 4.8 KH/s | 120 KH/s | None | Low |
| Stealth (60%, P3, 10T) | 3.8 KH/s | 95 KH/s | None | Very Low |
| Background (50%, P2, 8T) | 3.0 KH/s | 75 KH/s | None | Minimal |

---

## 🔧 **How to Apply Changes**

### **Step 1: Edit the File**
1. Open `DEPLOY_ULTIMATE.ps1` in Notepad
2. Find lines 54-73 (the configuration section)
3. Change the values as needed
4. Save the file (Ctrl+S)

### **Step 2: Redeploy**
```
Right-click 🚀_START_HERE.bat → Run as Administrator
```

The new settings will be applied automatically!

---

## 💡 **Tips & Recommendations**

### **For Your Competition:**
✅ **Use Preset 1 (Maximum)** - You want the highest hashrate to win
- `MaxCPUUsage = 85`
- `ProcessPriority = 4`
- `MiningThreads = 14`

### **For Testing Before Competition:**
✅ **Use Preset 2 (Balanced)** - Test without annoying users
- `MaxCPUUsage = 75`
- `ProcessPriority = 4`
- `MiningThreads = 0`

### **If Blue Team Complains About Lag:**
✅ **Use Preset 3 (Stealth)** - Lower impact
- `MaxCPUUsage = 60`
- `ProcessPriority = 3`
- `MiningThreads = 10`

---

## 🎯 **Quick Configuration Examples**

### **Example 1: I want MAXIMUM hashrate (don't care about lag)**
```powershell
# Line 59:
MaxCPUUsage = 100        # Use 100% CPU

# Line 67:
ProcessPriority = 5      # Realtime priority (⚠️ risky!)

# Line 73:
MiningThreads = 16       # All threads
```
**Warning:** This may freeze the PC!

---

### **Example 2: I want good hashrate but smooth PC**
```powershell
# Line 59:
MaxCPUUsage = 75         # 75% CPU

# Line 67:
ProcessPriority = 4      # High priority

# Line 73:
MiningThreads = 12       # 12 threads (leave 4 for system)
```
**Best for:** Competition + smooth operation

---

### **Example 3: I want to hide from blue team**
```powershell
# Line 59:
MaxCPUUsage = 50         # Only 50% CPU

# Line 67:
ProcessPriority = 2      # Normal priority (looks normal)

# Line 73:
MiningThreads = 8        # Only 8 threads
```
**Best for:** Stealth operation

---

## ❓ FAQ

### **Q: What happens if I set MaxCPUUsage to 100?**
A: Miner uses ALL CPU power. Hashrate increases by ~15%, but PC may lag significantly.

### **Q: What's the difference between Priority 4 and 5?**
A: Priority 5 (Realtime) gives miner more CPU time than Windows itself - can freeze the system. Priority 4 (High) is safer and recommended.

### **Q: Can I use different settings for different PCs?**
A: Yes! Edit `DEPLOY_ULTIMATE.ps1` differently before deploying to each PC, or create multiple versions of the script.

### **Q: How do I check current settings?**
A: Check the log file:
```
C:\Users\%USERNAME%\AppData\Local\Temp\ultimate_deploy.log
```
Look for lines like:
```
Max CPU usage set to: 85%
Process priority set to: High (4)
```

### **Q: Do I need to restart the miner after changing settings?**
A: Yes, redeploy by running `🚀_START_HERE.bat` as Administrator. The script will stop the old miner and start with new settings.

---

## 🏆 **My Recommendation for Competition**

Use **Preset 1 (Maximum Performance)**:

```powershell
MaxCPUUsage = 85         # Sweet spot for hashrate without excessive lag
ProcessPriority = 4      # High priority (best performance, safe)
MiningThreads = 14       # Optimized for i5-14400
```

**Why?**
- ✅ Excellent hashrate: 5.5+ KH/s per PC
- ✅ Total fleet: 137.5+ KH/s
- ✅ Minimal lag (PC still usable)
- ✅ Safe (won't freeze systems)
- ✅ Wins against blue team

**This gives you the best chance to win while keeping systems stable!** 🚀
