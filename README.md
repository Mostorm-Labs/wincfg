# WinConf

用于会议室、展示终端和其他无人值守 Windows 设备的系统配置工具。

## 图形界面

双击项目根目录中的 `WinConf.exe`，允许管理员权限后即可：

- 查看 8 个配置模块及其用途和风险提示；
- 读取每项配置的当前值与目标值；
- 单独运行某个模块，或先用“仅预演”查看流程；
- 在表格中比较运行前后的真实系统状态；
- 在运行成功后恢复到运行前快照，并再次查看恢复前后对比；
- 查看最近的脚本运行日志。

界面默认使用 English，可通过右上角语言选择切换为中文。

`WinConf.exe` 需要与 `scripts` 目录保持相对位置。它是项目交付物，已通过 `.gitignore` 例外规则明确保留在版本控制中。

## 命令行

```powershell
# 预览全部配置，不写入系统
.\scripts\winconf.ps1 -DryRun -Verbose

# 应用单个模块
.\scripts\winconf.ps1 -Module Power

# 回滚最近快照中的配置
.\scripts\winconf.ps1 -Rollback
```

## 重新构建界面程序

Windows 10/11 自带的 .NET Framework 编译器即可完成构建，无需下载第三方依赖：

```powershell
.\build.ps1
```

构建结果会写入项目根目录的 `WinConf.exe`。
