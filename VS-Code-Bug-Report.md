# 🐛 VS Code Memory Spike & UI Freeze Bug Report

**Submitted to:** Microsoft VS Code Team  
**Date:** July 28, 2025  
**Reporter:** David B. (Enterprise Development Environment)  
**Severity:** High - Blocks development productivity

**🔄 CRITICAL UPDATE**: Microsoft correctly identified that the memory spikes occur in **Node.js Service processes** (--type=utility --utility-sub-type=node.mojom.NodeService), NOT renderer processes. Live monitoring revealed **DUAL-PROCESS MEMORY SPIKES** - both Renderer and Utility processes spike simultaneously (Renderer +328MB, Utility 1000+MB) during UI freezes, indicating a synchronized memory management issue affecting multiple VS Code processes.

---

## 📋 **Executive Summary**

VS Code experiences massive memory spikes (400-1500MB) causing complete UI freezes lasting 15-20 seconds with keyboard input buffering. **Critical finding**: Issue persists with ALL extensions disabled and affects MULTIPLE processes simultaneously - both Renderer and Node.js Service processes spike in coordination, indicating core VS Code inter-process communication or memory management issue.

## 🔍 **Issue Details**

### **Primary Symptoms**

- **Memory Spikes**: 400-1500MB sudden increases in renderer process
- **UI Freezes**: Complete interface lock for 15-20 seconds
- **Keyboard Buffering**: Keystrokes queue during freeze, execute after UI unfreezes
- **Frequency**: Every 1-5 minutes of active development
- **Persistence**: Occurs even with all extensions disabled

### **Critical Evidence**

**With Extensions Enabled:**

- Spike Pattern: 994MB → 1218MB (224MB increase)
- Primary Process: PID varies (renderer process)

**WITH ALL EXTENSIONS DISABLED:**

- Spike Pattern: 815MB → 1242MB (427MB increase) - **LARGER SPIKES**
- Primary Process: PID 28968 (new renderer process)
- **Conclusion**: Extensions are NOT the root cause

**WORKSPACE-SPECIFIC BEHAVIOR:**

- **Empty Workspace**: No memory spikes or UI freezes observed
- **Current Workspace**: Consistent reproduction of memory issues
- **Conclusion**: Issue is tied to workspace content/configuration, not VS Code installation

## 💻 **Environment Details**

### **System Configuration**

- **OS**: Windows 11 Professional
- **VS Code Version**: [Current Stable]
- **RAM**: 32GB DDR4
- **Storage**: NVMe SSD
- **CPU**: Snapdragon X 12-core X1E80100 @ 3.40 GHz (ARM-based)

### **Workspace Details**

- **Project Type**: .NET 9.0 Monorepo
- **Structure**: Multiple C# projects (API + MCP server)
- **Size**: ~500 files across multiple projects
- **Git Repository**: Active with frequent commits
- **Repository URL**: https://github.com/davebirr/Fabrikam-Project.git

### **Performance Optimizations Already Applied**

```json
// .vscode/settings.json - Comprehensive exclusions
{
  "files.exclude": {
    "**/bin": true,
    "**/obj": true,
    "**/.vs": true
  },
  "files.watcherExclude": {
    "**/bin/**": true,
    "**/obj/**": true,
    "**/.vs/**": true,
    "**/node_modules/**": true,
    "**/.git/**": true
  },
  "search.exclude": {
    "**/bin": true,
    "**/obj": true,
    "**/.vs": true,
    "**/node_modules": true
  }
}
```

### **Windows Defender Exclusions**

```powershell
# Development folders excluded
C:\Dev
%USERPROFILE%\.nuget
%PROGRAMFILES%\dotnet

# Processes excluded
dotnet.exe
MSBuild.exe
VBCSCompiler.exe
Code.exe
```

## 🔬 **Detailed Investigation**

### **Memory Monitoring Script Used**

```powershell
# Real-time monitoring during freezes
while ($true) {
    $time = Get-Date -Format "HH:mm:ss"
    $vscode = Get-Process Code -ErrorAction SilentlyContinue
    if ($vscode) {
        $sortedProcs = $vscode | Sort-Object WorkingSet64 -Descending
        $maxProc = $sortedProcs[0]
        $maxMem = [math]::Round($maxProc.WorkingSet64 / 1MB, 1)
        $totalMem = [math]::Round(($vscode | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 1)

        if ($maxMem -gt 800) {
            Write-Host "$time - PID:$($maxProc.Id) ${maxMem}MB (Total:${totalMem}MB)" -ForegroundColor Red
        }
    }
    Start-Sleep -Milliseconds 500
}
```

### **Process Analysis During Freeze**

**CORRECTED ANALYSIS** (per Microsoft feedback):

```
Time: 23:15:xx - During 10-second UI freeze
BEFORE freeze: PID 9508 ~760-840MB
AFTER freeze:  PID 9508 935.8MB (significant spike detected)

Process Type: NODE.JS SERVICE (NOT renderer as initially reported)
Command: "C:\Users\davidb\AppData\Local\Programs\Microsoft VS Code\Code.exe"
         --type=utility --utility-sub-type=node.mojom.NodeService
         --lang=en-US --service-sandbox-type=none

Critical Correction: Microsoft identified that --ms-enable-electron-run-as-node
indicates Node.js extension host process, not renderer process.
Renderer processes are sandboxed and never have this flag.
```

**CONFIRMED CORRELATION:**

- **Freeze Event 1**: User reported 10-second UI freeze at approximately 23:15:xx

  - PID 9508 (Node.js Service) memory increased from ~840MB to 935.8MB
  - Memory spike timing correlates with reported UI freeze
  - Process is **node.mojom.NodeService** utility process

- **Freeze Event 2** [BREAKING DISCOVERY]: 18-second UI freeze at 23:22:45-23:23:08

  - **Dual Process Issue**: Both Renderer AND Utility processes spike simultaneously
  - **23:22:50 (Freeze Begins)**:
    - PID 8280 (Renderer): **1139 MB** (+328 MB spike from 811 MB!)
    - PID 9508 (Utility): **1033 MB** (maintaining high)
  - **During Freeze**: Both processes sustain elevated memory
    - PID 8280: 1140+ MB sustained
    - PID 9508: 952+ MB sustained
  - **23:23:08 (Recovery)**: Memory drops, UI becomes responsive
  - **User Experience**: Complete UI lockup, keyboard buffering ("esdfsfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdfsdsdf"), 18-second duration

- **Freeze Event 3** [ESCALATING SEVERITY]: 37-second UI freeze at 23:23:45-23:24:22

  - **User Clock Time**: "11:24" (matches monitoring timestamp)
  - **23:23:50 (Spike)**: PID 8280 (Renderer) **1188 MB** (+364 MB from 824 MB!)
  - **Sustained High**: Renderer 1188-1191MB, Utility 1099-1108MB for 37 seconds
  - **Keyboard Buffer**: "asdfadfasdfadsfadsfadfasdfasdfafdasdfasdfasdfasdfasdfasdfadfsasdfasdfasdfasdfadfasdfasdfasdfasdfasdfasdfadfadsfadfadsfadfadf"

- **Freeze Event 4** [MASSIVE 73-SECOND FREEZE]: 23:24:45-23:25:58
  - **User Clock Time**: "11:25" (perfect timestamp match)
  - **23:24:49 (Spike)**: PID 8280 (Renderer) **1150 MB** (+441 MB from 709 MB!)
  - **Sustained**: Dual processes elevated for **73 seconds** (Renderer 1150-1188MB, Utility 1062-1073MB)
  - **Keyboard Buffer**: "asasdfadsfadfadsfadsfasdfasdfadsfafdadsfadsfasdfadfasdfasdfasdfasdfasdfasdfasdfasdfasdfadsfasdfasdf"

**CRITICAL FINDING**: This is NOT just a Node.js service issue - it's a **synchronized dual-process memory spike** affecting both Renderer and Utility processes simultaneously. **SEVERITY ESCALATES** - freezes getting progressively longer (18s → 37s → 73s) with larger memory spikes.

### **Timeline of Investigation**

1. **Initial Assumption**: Extension conflict (gitlens, errorlens, python)
2. **Extension Elimination**: Disabled all extensions systematically
3. **Build Artifacts Theory**: Cleaned bin/obj folders, added watcher exclusions
4. **Process Misidentification**: Initially misidentified Node service as renderer process
5. **Microsoft Correction**: MS identified --ms-enable-electron-run-as-node indicates Node.js service
6. **Live Correlation**: Confirmed PID 9508 (Node service) memory spike during 10-second UI freeze
7. **Current Status**: Node.js service memory management issue in utility process

## 🧪 **Reproduction Steps**

### **Reliable Reproduction**

1. Open large .NET monorepo workspace in VS Code
2. Disable ALL extensions (`code --disable-extensions`)
3. Perform normal editing activities:
   - Edit .cs files
   - Navigate between files
   - Use IntelliSense
   - Build project (`dotnet build`)
4. Monitor memory usage via Task Manager or PowerShell script
5. **Result**: Memory spikes and UI freezes occur within 15-20 minutes

**Note**: Issue does NOT occur with empty workspace - problem is specific to this workspace configuration.

### **Workspace-Specific Testing**

- **Empty VS Code Window**: No memory issues observed over extended periods
- **Different Small Projects**: No reproduction of memory spikes
- **Current .NET Monorepo**: Consistent memory spike reproduction
- **Conclusion**: Issue is workspace-dependent, not a general VS Code installation problem

### **Consistent Triggers**

- File navigation in large workspace
- IntelliSense operations
- Git status operations (even with .git excluded from watcher)
- Project build operations

## 🎯 **Expected vs Actual Behavior**

### **Expected**

- VS Code memory usage remains stable during normal operations
- UI remains responsive during background processing
- Memory usage < 2GB total across all processes

### **Actual**

- Sudden 400-1500MB memory spikes in renderer process
- Complete UI freeze lasting 15-20 seconds
- Keyboard input buffers and executes after freeze
- Total memory usage reaches 3-4GB during spikes

## 🔧 **Workarounds Attempted**

### **Failed Solutions**

- ❌ Disable all extensions
- ❌ Clean workspace cache (`%APPDATA%\Code\User\workspaceStorage`)
- ❌ Windows Defender exclusions
- ❌ Disable Windows Search service
- ❌ Git repository optimization
- ❌ Workspace file exclusions

### **Partial Mitigations**

- ⚠️ Frequent VS Code restarts (temporary relief)
- ⚠️ Work in smaller file subsets (not practical)
- ⚠️ Use alternative editors for large operations

## 📊 **Performance Data**

### **Memory Usage Patterns**

```
Baseline (Fresh Start): 400-600MB
Normal Operation: 800-1200MB
During Spike: 1200-2700MB
Post-Freeze: Returns to ~1000MB
```

### **System Impact**

- **CPU Usage**: Spikes to 80-90% during freeze
- **Disk I/O**: Minimal during freeze (rules out disk bottleneck)
- **System Memory**: Overall usage increases during spike
- **Other Applications**: Remain responsive (VS Code-specific issue)

## 🚨 **Business Impact**

### **Development Productivity**

- **Interruptions**: Every 15-20 minutes during active development
- **Context Loss**: UI freezes break flow state
- **Workaround Time**: 2-3 minutes per restart
- **Daily Impact**: 20-30 minutes lost productivity

### **Team Considerations**

- Multiple developers experiencing similar issues
- Forced to use alternative editors for certain tasks
- Affects code review and collaboration workflows

## 🔍 **Debugging Information Requests**

### **Logs We Can Provide**

- VS Code process memory dumps during spikes
- Windows Performance Toolkit traces
- VS Code output logs with timestamp correlation
- Detailed system performance counters

### **Additional Testing**

- Test with VS Code Insiders builds
- Enable VS Code developer tools during freeze
- Provide heap dumps of renderer process
- Test with minimal workspace configurations

## 🎯 **Requested Investigation**

### **Core Questions**

1. **Node.js Service Memory Management**: Why do memory spikes occur in the node.mojom.NodeService utility process?
2. **Extension Host vs Node Service**: What triggers memory allocation in Node services when extensions are disabled?
3. **Workspace File Processing**: Is the Node service processing workspace files causing memory leaks?
4. **Background Operations**: What background tasks run in Node services that could cause 100MB+ memory spikes?
5. **Workspace-Specific Memory Issues**: What workspace characteristics trigger Node service memory spikes?

### **Specific Areas for MS Investigation**

- Node.js service process memory allocation patterns
- Workspace indexing and language service operations in Node processes
- Background file processing and watching in Node services
- Extension host communication even when extensions are disabled
- ARM64 architecture specific issues (Snapdragon X processor)

## 📞 **Contact Information**

**Primary Contact**: David B.  
**Environment**: Enterprise Development  
**Availability**: Weekdays 9am-5pm EST  
**Debugging Cooperation**: Available for remote debugging sessions

---

## 📎 **Attachments Available**

- Complete performance troubleshooting documentation (465 lines)
- VS Code settings.json with optimizations
- PowerShell monitoring scripts
- Memory usage graphs and process dumps
- Timeline of investigation attempts

**Priority Request**: This issue significantly impacts development productivity and appears to be a core VS Code renderer process issue that persists regardless of extension configuration.
