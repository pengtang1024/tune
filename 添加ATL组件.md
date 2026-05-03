# 添加 ATL 组件到 Visual Studio Build Tools

## 方法：使用 vs_buildtools.exe 命令行安装

### 步骤 1：找到安装程序

如果您之前安装时保存了安装程序：
```
vs_buildtools.exe
```

如果没有，可以重新下载：
- 访问 https://visualstudio.microsoft.com/downloads/
- 向下滚动 → Tools for Visual Studio 2022 → Build Tools 2022

### 步骤 2：添加 ATL 组件

运行以下命令（以管理员身份）：

```powershell
vs_buildtools.exe --add Microsoft.VisualStudio.Component.VC.ATL
```

或者使用完整的工作负载：

```powershell
vs_buildtools.exe --modify --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.ATL
```

### 步骤 3：验证安装

安装完成后，运行：
```powershell
flutter doctor
```

应该看到：
```
[√] Visual Studio - develop for Windows apps
```

---

## 或者：通过 GUI 修改（如果还能打开安装程序）

1. 打开 **Visual Studio Installer**
2. 点击 Build Tools 2022 的「修改」
3. 勾选：
   - **「Windows 10/11 SDK」** （如果还没勾选）
   - 确保包含 **ATL** 组件
4. 点击「修改」

---

## 如果上述都不行：尝试修复

有时候可以尝试修复安装：
```powershell
vs_buildtools.exe --repair
```

这会检查并修复缺少的组件。
