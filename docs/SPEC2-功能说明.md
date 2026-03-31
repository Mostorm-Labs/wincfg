# SPEC2 - Windows 配置项功能说明

**日期:** 2026-03-31

本文档说明各配置项如何影响 Windows 功能，面向最终用户和运维人员。

---

## 1. 电源管理 (Power)

**目标场景:** 会议室设备、Zoom Room 等需要 24/7 运行的无人值守设备

### 配置项详情

#### 1.1 高性能电源计划
- **命令:** `powercfg /setactive SCHEME_MIN`
- **功能影响:** 启用 CPU 全速运行，禁用节能降频
- **适用场景:** 视频会议设备需要稳定性能

#### 1.2 禁用睡眠（AC 供电）
- **命令:** `powercfg /change standby-timeout-ac 0`
- **功能影响:** 插电时设备永不进入睡眠状态
- **适用场景:** 防止会议期间设备休眠

#### 1.3 禁用睡眠（DC 电池）
- **命令:** `powercfg /change standby-timeout-dc 0`
- **功能影响:** 电池供电时设备永不进入睡眠状态
- **适用场景:** 移动设备保持常开

#### 1.4 禁用显示器关闭（AC 供电）
- **命令:** `powercfg /change monitor-timeout-ac 0`
- **功能影响:** 插电时屏幕保持常亮
- **适用场景:** 会议室显示屏需要持续显示内容

#### 1.5 禁用显示器关闭（DC 电池）
- **命令:** `powercfg /change monitor-timeout-dc 0`
- **功能影响:** 电池供电时屏幕保持常亮
- **适用场景:** 移动设备屏幕常亮

#### 1.6 禁用休眠
- **命令:** `powercfg /hibernate off`
- **功能影响:** 关闭休眠文件，释放磁盘空间
- **适用场景:** 减少磁盘占用，加快启动速度

#### 1.7 禁用快速启动
- **注册表路径:** `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power`
- **键名:** `HiberbootEnabled`
- **值:** `0` (DWORD)
- **功能影响:** 关闭混合启动模式
- **适用场景:** 避免休眠残留导致的状态异常

### 用户体验变化
- ✅ 设备随时可用，无需唤醒
- ✅ 避免会议中断
- ⚠️ 功耗增加

---

## 2. 屏幕锁定 (ScreenLock)

**目标场景:** 公共区域设备，需要防止未授权访问但不能自动锁屏

### 配置项详情

#### 2.1 禁用屏幕保护程序
- **注册表路径:** `HKCU:\Control Panel\Desktop`
- **键名:** `ScreenSaveActive`
- **值:** `0` (String)
- **功能影响:** 不会触发屏保动画
- **适用场景:** 会议室设备不需要屏保

#### 2.2 屏保超时设为 0
- **注册表路径:** `HKCU:\Control Panel\Desktop`
- **键名:** `ScreenSaveTimeOut`
- **值:** `0` (String)
- **功能影响:** 永不启动屏保
- **适用场景:** 保持内容持续显示

#### 2.3 禁用恢复时锁定
- **注册表路径:** `HKCU:\Control Panel\Desktop`
- **键名:** `ScreenSaverIsSecure`
- **值:** `0` (String)
- **功能影响:** 从睡眠/屏保恢复时不要求密码
- **适用场景:** 无人值守设备快速恢复

#### 2.4 禁用空闲锁定 (GPO)
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`
- **键名:** `InactivityTimeoutSecs`
- **值:** `0` (DWORD)
- **功能影响:** 系统不会因空闲自动锁定
- **适用场景:** 避免会议期间锁屏

### 用户体验变化

- ✅ 设备不会自动锁定
- ⚠️ 降低安全性，仅适用于物理安全的环境

---

## 3. Windows 更新 (WindowsUpdate)

**目标场景:** 生产环境设备，需要手动控制更新时间窗口

### 配置项详情

#### 3.1 禁用自动更新
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`
- **键名:** `NoAutoUpdate`
- **值:** `1` (DWORD)
- **功能影响:** 系统不会自动下载和安装更新
- **适用场景:** 避免会议期间更新中断

#### 3.2 更新模式设为通知
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`
- **键名:** `AUOptions`
- **值:** `1` (DWORD)
- **功能影响:** 仅通知有更新，不自动安装
- **适用场景:** 管理员手动控制更新时机

#### 3.3 隐藏更新关机选项
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`
- **键名:** `NoAUShutdownOption`
- **值:** `1` (DWORD)
- **功能影响:** 关机菜单不显示"更新并关机"
- **适用场景:** 防止用户误触发更新

#### 3.4 禁用传统关机回退
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`
- **键名:** `NoAUAsDefaultShutdownOption`
- **值:** `1` (DWORD)
- **功能影响:** 关机时不默认选择更新选项
- **适用场景:** 确保快速关机

#### 3.5 禁用自动重启提示
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`
- **键名:** `NoAutoRebootWithLoggedOnUsers`
- **值:** `1` (DWORD)
- **功能影响:** 不弹出重启倒计时窗口
- **适用场景:** 避免会议期间弹窗干扰

#### 3.6 禁用重启通知
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- **键名:** `SetAutoRestartNotificationDisable`
- **值:** `1` (DWORD)
- **功能影响:** 不显示"需要重启"通知
- **适用场景:** 减少通知干扰

#### 3.7 通知抑制级别
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- **键名:** `SetUpdateNotificationLevel`
- **值:** `2` (DWORD)
- **功能影响:** 最小化更新相关通知
- **适用场景:** 保持界面清爽

#### 3.8 排除驱动更新
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- **键名:** `ExcludeWUDriversInQualityUpdate`
- **值:** `1` (DWORD)
- **功能影响:** 不通过 Windows Update 更新驱动
- **适用场景:** 避免驱动兼容性问题

#### 3.9 阻止系统升级
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- **键名:** `DisableOSUpgrade`
- **值:** `1` (DWORD)
- **功能影响:** 不升级到新的 Windows 大版本
- **适用场景:** 保持系统稳定性

#### 3.10 保留 Microsoft Store
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`
- **键名:** `RemoveWindowsStore`
- **值:** `0` (DWORD)
- **功能影响:** 允许 Store 应用更新
- **适用场景:** 保持应用商店可用

#### 3.11 Store 手动下载
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore`
- **键名:** `AutoDownload`
- **值:** `4` (DWORD)
- **功能影响:** Store 应用不自动下载更新
- **适用场景:** 管理员控制应用更新

#### 3.12 隐藏 Windows Update 设置页面
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`
- **键名:** `SettingsPageVisibility`
- **值:** `hide:windowsupdate-action` (String)
- **功能影响:** 设置中隐藏 Windows Update 页面
- **适用场景:** 防止用户误操作

#### 3.13 UX 重启通知
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings`
- **键名:** `RestartNotificationsAllowed2`
- **值:** `0` (DWORD)
- **功能影响:** 禁用新版 UX 重启通知
- **适用场景:** 减少通知干扰

#### 3.14 隐藏新版 UX 消息
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings`
- **键名:** `HideWUXMessages`
- **值:** `1` (DWORD)
- **功能影响:** 隐藏 Windows Update 体验消息
- **适用场景:** 保持界面清爽

#### 3.15 PolicyManager 自动更新
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update`
- **键名:** `AllowAutoUpdate`
- **值:** `0` (DWORD)
- **功能影响:** 通过 PolicyManager 禁用自动更新
- **适用场景:** 新版 Windows 策略兼容

#### 3.16 PolicyManager 通知
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update`
- **键名:** `DoNotShowUpdateNotifications`
- **值:** `1` (DWORD)
- **功能影响:** 不显示更新通知
- **适用场景:** 减少通知干扰

#### 3.17 PolicyManager 电源选项
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update`
- **键名:** `HideUpdatePowerOption`
- **值:** `1` (DWORD)
- **功能影响:** 隐藏电源菜单中的更新选项
- **适用场景:** 简化电源菜单

#### 3.18 PolicyManager 驱动阻止
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update`
- **键名:** `ExcludeWUDriversInQualityUpdate`
- **值:** `1` (DWORD)
- **功能影响:** 通过 PolicyManager 排除驱动更新
- **适用场景:** 新版 Windows 策略兼容

#### 3.19 PolicyManager Store 访问
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store`
- **键名:** `AllowStore`
- **值:** `1` (DWORD)
- **功能影响:** 允许访问 Microsoft Store
- **适用场景:** 保持应用商店可用

#### 3.20 PolicyManager Store 下载
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store`
- **键名:** `AutoDownload`
- **值:** `4` (DWORD)
- **功能影响:** Store 应用手动下载
- **适用场景:** 管理员控制应用更新

#### 3.21 PolicyManager 页面可见性
- **注册表路径:** `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Settings`
- **键名:** `SettingsPageVisibility`
- **值:** `hide:windowsupdate-action` (String)
- **功能影响:** 隐藏 Windows Update 设置页面
- **适用场景:** 防止用户误操作

### 用户体验变化

- ✅ 系统不会意外重启
- ✅ 会议期间无更新干扰
- ⚠️ 需要管理员定期手动更新
- ⚠️ 安全补丁延迟安装

### 重要说明

- 不会禁用 Windows Update 服务，Microsoft Store 仍可用
- 需要定期执行 `gpupdate /force` 使策略生效

---

## 4. Windows 恢复 (WindowsRestore)

**目标场景:** 防止用户通过恢复功能重置设备配置

### 配置项详情

#### 4.1 禁用恢复环境
- **命令:** `reagentc /disable`
- **功能影响:** 无法进入 WinRE 恢复模式
- **适用场景:** 防止用户重置系统

#### 4.2 启用恢复环境
- **命令:** `reagentc /enable`
- **功能影响:** 恢复 WinRE 可用性
- **适用场景:** 恢复默认行为

### 用户体验变化

- ✅ 防止误操作重置系统
- ⚠️ 系统故障时无法使用恢复功能

---

## 5. Cortana 和搜索 (Cortana)

**目标场景:** 简化界面，移除不必要的智能助手功能

### 配置项详情

#### 5.1 禁用 Cortana
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search`
- **键名:** `AllowCortana`
- **值:** `0` (DWORD)
- **功能影响:** 关闭语音助手功能
- **适用场景:** 会议室设备不需要语音助手

#### 5.2 禁用网络搜索建议
- **注册表路径:** `HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer`
- **键名:** `DisableSearchBoxSuggestions`
- **值:** `1` (DWORD)
- **功能影响:** 搜索框不显示网络结果
- **适用场景:** 减少干扰，提升隐私

#### 5.3 隐藏任务栏按钮
- **注册表路径:** `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
- **键名:** `ShowCortanaButton`
- **值:** `0` (DWORD)
- **功能影响:** 任务栏不显示 Cortana 图标
- **适用场景:** 简化界面

### 用户体验变化

- ✅ 任务栏更简洁
- ✅ 搜索更快速（仅本地）
- ⚠️ 无法使用语音助手

---

## 6. 通知 (Notifications)

**目标场景:** 会议演示设备，需要零干扰环境

### 配置项详情

#### 6.1 禁用操作中心
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer`
- **键名:** `DisableNotificationCenter`
- **值:** `1` (DWORD)
- **功能影响:** 无法打开通知面板
- **适用场景:** 避免通知干扰

#### 6.2 禁用 Toast 通知
- **注册表路径:** `HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications`
- **键名:** `NoToastApplicationNotification`
- **值:** `1` (DWORD)
- **功能影响:** 不显示弹出式通知
- **适用场景:** 会议期间零弹窗

#### 6.3 禁用锁屏通知
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`
- **键名:** `DisableLockScreenAppNotifications`
- **值:** `1` (DWORD)
- **功能影响:** 锁屏界面不显示通知
- **适用场景:** 保护隐私

### 用户体验变化

- ✅ 会议期间无弹窗干扰
- ⚠️ 无法接收系统通知

---

## 7. 隐私和遥测 (Privacy)

**目标场景:** 企业环境，需要最小化数据收集

### 配置项详情

#### 7.1 遥测级别设为 0
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`
- **键名:** `AllowTelemetry`
- **值:** `0` (DWORD)
- **功能影响:** 仅发送必需的诊断数据
- **适用场景:** 最小化数据上传

#### 7.2 禁用活动历史记录
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`
- **键名:** `PublishUserActivities`
- **值:** `0` (DWORD)
- **功能影响:** 不记录应用使用历史
- **适用场景:** 保护隐私

#### 7.3 禁用活动上传
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System`
- **键名:** `UploadUserActivities`
- **值:** `0` (DWORD)
- **功能影响:** 不上传活动数据到云端
- **适用场景:** 减少网络流量

#### 7.4 禁用 DiagTrack 服务
- **服务名称:** `DiagTrack`
- **启动类型:** `Disabled`
- **功能影响:** 关闭诊断跟踪服务
- **适用场景:** 减少后台进程

### 用户体验变化

- ✅ 减少数据上传
- ✅ 提升隐私保护
- ⚠️ 时间线功能不可用

---

## 8. 界面优化 (UI)

**目标场景:** 简化任务栏，移除不必要的界面元素

### 配置项详情

#### 8.1 隐藏任务视图按钮
- **注册表路径:** `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
- **键名:** `ShowTaskViewButton`
- **值:** `0` (DWORD)
- **功能影响:** 任务栏不显示多任务按钮
- **适用场景:** 简化界面

#### 8.2 禁用资讯和兴趣（策略路径）
- **注册表路径:** `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds`
- **键名:** `EnableFeeds`
- **值:** `0` (DWORD)
- **功能影响:** 任务栏不显示新闻天气
- **适用场景:** 减少干扰

#### 8.3 禁用资讯和兴趣（用户路径，版本相关）
- **注册表路径:** `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds`
- **键名:** `ShellFeedsTaskbarViewMode`
- **值:** `2` (DWORD)
- **功能影响:** 任务栏不显示新闻天气（用户级别）
- **适用场景:** 减少干扰
- **版本兼容性:** Windows 版本相关

#### 8.4 隐藏小组件/聊天式任务栏条目（版本相关）
- **注册表路径:** `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
- **键名:** `TaskbarDa`
- **值:** `0` (DWORD)
- **功能影响:** 任务栏不显示小组件图标
- **适用场景:** 简化界面
- **版本兼容性:** Windows 版本相关

#### 8.5 隐藏立即开会
- **注册表路径:** `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`
- **键名:** `HideMeetNow`
- **值:** `1` (DWORD)
- **功能影响:** 任务栏不显示 Teams 快捷入口
- **适用场景:** 使用专用会议软件

#### 8.6 禁用边缘手势
- **注册表路径:** `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell\EdgeUI`
- **键名:** `DisabledEdgeSwipe`
- **值:** `1` (DWORD)
- **功能影响:** 屏幕边缘滑动不触发系统功能
- **适用场景:** 避免触摸屏误操作

### 用户体验变化

- ✅ 任务栏更简洁
- ✅ 减少误触发
- ⚠️ 部分快捷功能不可用

### 版本兼容性说明

- 部分设置仅在特定 Windows 版本有效
- 不支持的设置会记录警告并跳过

---

## 9. 后台服务 (winconf-agent)

**功能:** 持续监控配置项，自动修复被篡改的设置

| 属性 | 说明 |
|------|------|
| 检查间隔 | 每 5 分钟检查一次 |
| 监控范围 | 由 `agent-watch.json` 定义 |
| 修复行为 | 检测到偏差时自动恢复 |
| 日志记录 | 写入 Windows 事件日志 |

**适用场景:**
- 防止用户或其他程序修改配置
- 确保设备始终处于预期状态

---

## 10. 回滚和恢复

### 10.1 历史回滚 (`-Rollback`)

**功能:** 恢复到执行配置前的原始状态

- 基于快照数据 (`snapshot.json`)
- 记录每次修改前的原始值
- 按时间倒序恢复

**使用场景:**
- 测试后恢复原始配置
- 配置出现问题需要撤销

### 10.2 预定义配置恢复 (`-RestoreProfile`)

**功能:** 恢复到预定义的标准配置

**当前支持的模块:**
- `WindowsUpdate -RestoreProfile Default`: 恢复 Windows Update 默认行为
- `WindowsRestore -RestoreProfile Default`: 重新启用恢复环境

**使用场景:**
- 设备退役前恢复标准配置
- 切换到不同的使用场景

---

## 11. 使用建议

### 适用场景
✅ **推荐使用:**
- 会议室 Zoom Room 设备
- 数字标牌显示设备
- 无人值守信息亭
- 生产环境固定用途设备

❌ **不推荐使用:**
- 个人办公电脑
- 移动办公笔记本
- 需要频繁更新的开发环境

### 安全注意事项
- 禁用自动更新后需要定期手动更新
- 禁用屏幕锁定仅适用于物理安全的环境
- 建议配合网络隔离和访问控制使用

### 测试流程

1. 使用 `-DryRun` 预览变更
2. 在测试设备上完整执行
3. 验证功能是否符合预期
4. 生产环境部署前创建系统还原点

---

## 12. Windows 版本注册表原始键值对照表

本节提供 Windows 10/11 不同版本下的注册表默认值，供技术人员对照检查。

**版本说明:**
- **23H2**: Windows 11 23H2 (Build 22631)
- **24H2**: Windows 11 24H2 (Build 26100)
- **25H2**: Windows 11 25H2 (Build 27xxx，预览版)

**符号说明:**
- `不存在` - 该键或值在默认安装中不存在
- `N/A` - 不适用于该版本
- `(用户相关)` - 值因用户配置而异

---

### 12.1 电源管理 (Power)

#### HiberbootEnabled - 快速启动

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power` | `HiberbootEnabled` | `1` (DWORD) | `1` (DWORD) | `1` (DWORD) |

**说明:** 所有版本默认启用快速启动

---

### 12.2 屏幕锁定 (ScreenLock)

#### 屏幕保护程序设置

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKCU:\Control Panel\Desktop` | `ScreenSaveActive` | `1` (String) | `1` (String) | `1` (String) |
| `HKCU:\Control Panel\Desktop` | `ScreenSaveTimeOut` | `900` (String) | `900` (String) | `900` (String) |
| `HKCU:\Control Panel\Desktop` | `ScreenSaverIsSecure` | `0` (String) | `0` (String) | `0` (String) |
| `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` | `InactivityTimeoutSecs` | 不存在 | 不存在 | 不存在 |

**说明:**
- 默认屏保超时 900 秒（15 分钟）
- 默认不要求屏保恢复时输入密码
- GPO 空闲锁定默认未配置

---

### 12.3 Windows 更新 (WindowsUpdate)

#### 自动更新策略

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` | `NoAutoUpdate` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` | `AUOptions` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` | `NoAUShutdownOption` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` | `NoAUAsDefaultShutdownOption` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU` | `NoAutoRebootWithLoggedOnUsers` | 不存在 | 不存在 | 不存在 |

**说明:** 默认情况下，所有策略键不存在，表示未配置（使用系统默认行为）

#### 更新通知和重启

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` | `SetAutoRestartNotificationDisable` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` | `SetUpdateNotificationLevel` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` | `ExcludeWUDriversInQualityUpdate` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` | `DisableOSUpgrade` | 不存在 | 不存在 | 不存在 |

#### Microsoft Store 策略

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore` | `RemoveWindowsStore` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore` | `AutoDownload` | 不存在 | 不存在 | 不存在 |

#### 设置页面可见性

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` | `SettingsPageVisibility` | 不存在 | 不存在 | 不存在 |

#### UX 设置

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` | `RestartNotificationsAllowed2` | `1` (DWORD) | `1` (DWORD) | `1` (DWORD) |
| `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` | `HideWUXMessages` | 不存在 | 不存在 | 不存在 |

**说明:** 默认允许重启通知

#### PolicyManager 策略（MDM/Intune）

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update` | `AllowAutoUpdate` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update` | `DoNotShowUpdateNotifications` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update` | `HideUpdatePowerOption` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update` | `ExcludeWUDriversInQualityUpdate` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store` | `AllowStore` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Store` | `AutoDownload` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Settings` | `SettingsPageVisibility` | 不存在 | 不存在 | 不存在 |

**说明:** PolicyManager 路径通常由 MDM/Intune 管理，默认不存在

---

### 12.4 Cortana 和搜索 (Cortana)

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search` | `AllowCortana` | 不存在 | 不存在 | 不存在 |
| `HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer` | `DisableSearchBoxSuggestions` | 不存在 | 不存在 | 不存在 |
| `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `ShowCortanaButton` | `0` (DWORD) | `0` (DWORD) | `0` (DWORD) |

**说明:**
- Windows 11 默认不显示 Cortana 按钮
- 策略键默认不存在（未配置）

---

### 12.5 通知 (Notifications)

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer` | `DisableNotificationCenter` | 不存在 | 不存在 | 不存在 |
| `HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications` | `NoToastApplicationNotification` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System` | `DisableLockScreenAppNotifications` | 不存在 | 不存在 | 不存在 |

**说明:** 默认启用所有通知功能

---

### 12.6 隐私和遥测 (Privacy)

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection` | `AllowTelemetry` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System` | `PublishUserActivities` | 不存在 | 不存在 | 不存在 |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\System` | `UploadUserActivities` | 不存在 | 不存在 | 不存在 |

**说明:**
- 默认遥测级别：家庭版 = 完整，专业版/企业版 = 完整（可配置）
- 策略键不存在表示使用系统默认行为

#### DiagTrack 服务

| 服务名称 | 23H2 默认启动类型 | 24H2 默认启动类型 | 25H2 默认启动类型 |
|---------|-----------------|-----------------|-----------------|
| `DiagTrack` | Automatic | Automatic | Automatic |

---

### 12.7 界面优化 (UI)

#### 任务栏按钮

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `ShowTaskViewButton` | `1` (DWORD) | `1` (DWORD) | `1` (DWORD) |

**说明:** 默认显示任务视图按钮

#### 资讯和兴趣 / Widgets

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds` | `EnableFeeds` | 不存在 | 不存在 | 不存在 |
| `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds` | `ShellFeedsTaskbarViewMode` | `2` (DWORD) | `2` (DWORD) | `2` (DWORD) |
| `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced` | `TaskbarDa` | `1` (DWORD) | `1` (DWORD) | `1` (DWORD) |

**说明:**
- `ShellFeedsTaskbarViewMode`: `0`=显示图标和文本, `1`=仅图标, `2`=隐藏
- `TaskbarDa`: `0`=隐藏小组件, `1`=显示小组件
- Windows 11 默认显示小组件按钮

#### Meet Now / Teams

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer` | `HideMeetNow` | 不存在 | 不存在 | 不存在 |

**说明:** Windows 11 已移除 Meet Now 功能，该设置不再适用

#### 边缘手势

| 注册表路径 | 键名 | 23H2 默认值 | 24H2 默认值 | 25H2 默认值 |
|-----------|------|------------|------------|------------|
| `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell\EdgeUI` | `DisabledEdgeSwipe` | 不存在 | 不存在 | 不存在 |

**说明:** 默认启用边缘手势（值不存在或为 `0`）

---

### 12.8 版本差异说明

#### Windows 11 23H2 vs 24H2 主要差异

1. **Windows Update 策略层:**
   - 24H2 增强了 PolicyManager 策略支持
   - 部分 UX 设置路径在 24H2 中有调整

2. **UI 元素:**
   - 24H2 对小组件面板进行了重新设计
   - 任务栏布局选项有所变化

3. **遥测和隐私:**
   - 24H2 增加了更细粒度的隐私控制选项
   - 诊断数据收集机制有优化

#### 检查当前系统版本

```powershell
# 查看 Windows 版本
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber

# 或使用
[System.Environment]::OSVersion.Version
```

#### 验证注册表键值

```powershell
# 检查键是否存在
Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

# 读取键值
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue

# 列出路径下所有值
Get-ItemProperty -Path "HKCU:\Control Panel\Desktop"
```

---

### 12.9 技术人员检查清单

使用以下 PowerShell 脚本快速检查关键配置项：

```powershell
# 检查脚本 - 保存为 Check-WinConfSettings.ps1

$checks = @(
    @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Name="HiberbootEnabled"; Expected=0},
    @{Path="HKCU:\Control Panel\Desktop"; Name="ScreenSaveActive"; Expected="0"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"; Name="NoAutoUpdate"; Expected=1},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Expected=0}
)

foreach ($check in $checks) {
    $value = Get-ItemProperty -Path $check.Path -Name $check.Name -ErrorAction SilentlyContinue
    if ($value) {
        $actual = $value.($check.Name)
        $status = if ($actual -eq $check.Expected) { "✓ 正确" } else { "✗ 不匹配" }
        Write-Host "$status - $($check.Path)\$($check.Name) = $actual (期望: $($check.Expected))"
    } else {
        Write-Host "✗ 不存在 - $($check.Path)\$($check.Name)"
    }
}
```

**使用方法:**
```powershell
.\Check-WinConfSettings.ps1
```
