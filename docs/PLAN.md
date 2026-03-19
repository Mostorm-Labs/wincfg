# PLAN.md — Implementation Plan

## Phases

### Phase 1 — 基础库 `scripts/lib/`

- [ ] **Logger.ps1**
  - `Write-Log -Level -Module -Message`
  - 写入 `C:\ProgramData\WinConf\winconf.log`，格式 `[YYYY-MM-DD HH:MM:SS] [MODULE] [LEVEL] message`
  - `-Verbose` 时同步输出到控制台

- [ ] **Registry.ps1**
  - `Get-RegValue -Path -Name`
  - `Set-RegValue -Path -Name -Value -Type` （DryRun 时只打印，不写入）
  - 每次操作调用 `Write-Log`

- [ ] **Service.ps1**
  - `Set-ServiceStartType -Name -StartType`
  - `Stop-ServiceIfRunning -Name`
  - 每次操作调用 `Write-Log`

- [ ] **Snapshot.ps1**
  - `Save-Snapshot -Module -Key -CurrentValue` — 变更前保存原值到 `snapshot.json`
  - `Restore-Snapshot` — 按逆序还原所有已保存的值

---

### Phase 2 — 配置模块 `scripts/modules/`

每个模块暴露统一入口 `Invoke-<ModuleName> [-DryRun]`，内部调用 lib 函数。

- [ ] **Power.ps1** — 电源管理（高性能计划、禁止睡眠、禁止休眠、禁止显示器关闭、禁用快速启动）
- [ ] **ScreenLock.ps1** — 屏幕锁定（禁用屏保、超时为0、禁用恢复时锁定、禁用空闲锁）
- [ ] **WindowsUpdate.ps1** — Windows 更新（禁用自动更新、禁用 wuauserv、禁用 UsoSvc、禁用 DO）
- [ ] **Cortana.ps1** — Cortana & 搜索（禁用 Cortana、禁用 Web 搜索、隐藏任务栏按钮）
- [ ] **Notifications.ps1** — 通知（禁用操作中心、禁用 Toast、禁用锁屏通知）
- [ ] **Privacy.ps1** — 隐私与遥测（遥测级别0、禁用 DiagTrack、禁用活动历史）
- [ ] **UI.ps1** — UI 清理（隐藏任务视图、禁用新闻、隐藏 Meet Now、可选自动隐藏任务栏）

---

### Phase 3 — 主入口 `scripts/winconf.ps1`

- [ ] 参数声明：`-DryRun`、`-Verbose`、`-Rollback`、`-Module <string>`
- [ ] 管理员权限检查，非管理员时提示提权或退出
- [ ] 初始化日志目录和 snapshot 文件路径
- [ ] `-Rollback` 分支：调用 `Restore-Snapshot` 后退出
- [ ] 正常分支：dot-source 所有 lib 和 modules，按顺序或按 `-Module` 参数调用

---

### Phase 4 — 背景服务（可选）`service/winconf-agent/`

- [x] 评估实现方式：选用 PowerShell + NSSM（比 C++ 易维护，可复用现有 lib）
- [x] **winconf-agent.ps1** — 服务主体，每 5 分钟轮询 watch list，检测并修复漂移
  - watch list 从 `agent-watch.json` 加载，缺省使用内置默认值
  - 漂移时写 WARN 日志并重新应用
- [x] **Install-Service.ps1** — 安装/卸载服务（`-Install` / `-Remove`）
  - 依赖 NSSM，自动配置日志轮转（5 MB）
- [x] **agent-watch.example.json** — watch list 示例配置
- [x] 写入 Windows Event Log（source: `WinConf`，自动注册）

---

## 结构决策

| 决策 | 选择 | 原因 |
| --- | --- | --- |
| 模块化方式 | 独立 `.ps1` + dot-source | 便于单独测试 |
| 模块接口 | 统一 `Invoke-<Name>` | 主入口可循环调用 |
| 快照格式 | JSON | 易读易解析 |
| 服务管理 | 封装为 lib | 避免各模块重复调用 |
| 背景服务 | Phase 4 暂缓 | 优先核心脚本可用 |

---

## 文件结构

```text
├── scripts/
│   ├── winconf.ps1
│   ├── modules/
│   │   ├── Power.ps1
│   │   ├── ScreenLock.ps1
│   │   ├── WindowsUpdate.ps1
│   │   ├── Cortana.ps1
│   │   ├── Notifications.ps1
│   │   ├── Privacy.ps1
│   │   └── UI.ps1
│   └── lib/
│       ├── Logger.ps1
│       ├── Registry.ps1
│       ├── Service.ps1
│       └── Snapshot.ps1
├── service/
│   └── winconf-agent/
├── docs/
│   ├── SPEC.md
│   └── PLAN.md
├── CLAUDE.md
└── README.md
```
