# WinConf.Catalog.ps1 - Localized user-facing metadata for the desktop interface.

function New-WinConfCatalogItem {
    param(
        [string] $Name,
        [string] $DisplayNameEn,
        [string] $DisplayNameZh,
        [string] $DescriptionEn,
        [string] $DescriptionZh,
        [string] $NoticeEn,
        [string] $NoticeZh,
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    return [PSCustomObject]@{
        Name          = $Name
        DisplayName   = if ($Language -eq 'zh-CN') { $DisplayNameZh } else { $DisplayNameEn }
        Description   = if ($Language -eq 'zh-CN') { $DescriptionZh } else { $DescriptionEn }
        Notice        = if ($Language -eq 'zh-CN') { $NoticeZh } else { $NoticeEn }
        DisplayNameEn = $DisplayNameEn
        DisplayNameZh = $DisplayNameZh
        DescriptionEn = $DescriptionEn
        DescriptionZh = $DescriptionZh
        NoticeEn      = $NoticeEn
        NoticeZh      = $NoticeZh
    }
}

function Get-WinConfModuleCatalog {
    param(
        [ValidateSet('en-US', 'zh-CN')]
        [string] $Language = 'en-US'
    )

    return @(
        (New-WinConfCatalogItem -Name 'Power' -Language $Language `
            -DisplayNameEn 'Power Management' -DisplayNameZh '电源管理' `
            -DescriptionEn 'Enables the High Performance plan and disables AC sleep, display timeout, hibernation, and Fast Startup for always-on room and kiosk devices.' `
            -DescriptionZh '启用高性能电源方案，并关闭交流供电时的睡眠、屏幕超时、休眠和快速启动。适合需要持续在线的会议室与自助终端。' `
            -NoticeEn 'Power consumption will increase. Use with care on laptops or devices that rely on hibernation.' `
            -NoticeZh '会增加设备能耗；笔记本或依赖休眠的设备请谨慎使用。'),
        (New-WinConfCatalogItem -Name 'ScreenLock' -Language $Language `
            -DisplayNameEn 'Screen Lock' -DisplayNameZh '屏幕锁定' `
            -DescriptionEn 'Disables the screen saver, password-on-resume, and idle lock so unattended devices remain available.' `
            -DescriptionZh '关闭屏幕保护程序、屏保恢复密码和系统空闲锁定，避免无人值守设备在使用中自动进入锁屏。' `
            -NoticeEn 'The device will no longer lock after inactivity. Confirm that the physical security policy permits this.' `
            -NoticeZh '设备不会因长时间无人操作而自动锁定，请确认现场安全要求允许。'),
        (New-WinConfCatalogItem -Name 'WindowsUpdate' -Language $Language `
            -DisplayNameEn 'Windows Update' -DisplayNameZh 'Windows 更新' `
            -DescriptionEn 'Disables automatic updates, update prompts, driver updates, and update power options through policy while keeping Microsoft Store available.' `
            -DescriptionZh '通过系统策略关闭自动更新、更新提醒、驱动更新与更新电源选项，同时保留 Microsoft Store 的可用性。' `
            -NoticeEn 'Policy refresh can take time. Security updates must be handled through a separate maintenance process.' `
            -NoticeZh '策略刷新可能需要一些时间；安全更新需要由运维流程另行安排。'),
        (New-WinConfCatalogItem -Name 'WindowsRestore' -Language $Language `
            -DisplayNameEn 'Windows Recovery' -DisplayNameZh 'Windows 恢复环境' `
            -DescriptionEn 'Disables the Windows Recovery Environment (Windows RE) to prevent the terminal from entering local recovery workflows.' `
            -DescriptionZh '关闭 Windows 恢复环境（Windows RE），避免终端进入本地恢复流程。' `
            -NoticeEn 'Windows advanced-startup recovery tools will be unavailable until this configuration is restored.' `
            -NoticeZh '关闭后将无法直接使用 Windows 高级启动中的本地恢复工具。'),
        (New-WinConfCatalogItem -Name 'Cortana' -Language $Language `
            -DisplayNameEn 'Search and Cortana' -DisplayNameZh '搜索与 Cortana' `
            -DescriptionEn 'Disables Cortana, web suggestions in search, and the Cortana taskbar button while preserving local search.' `
            -DescriptionZh '关闭 Cortana、搜索框中的在线建议和任务栏 Cortana 按钮，减少无关的联网搜索入口。' `
            -NoticeEn 'Local file and app search remains available. OS-protected settings may be skipped on some Windows versions.' `
            -NoticeZh '本地文件和应用搜索仍可使用，部分设置受 Windows 版本保护时会自动跳过。'),
        (New-WinConfCatalogItem -Name 'Notifications' -Language $Language `
            -DisplayNameEn 'System Notifications' -DisplayNameZh '系统通知' `
            -DescriptionEn 'Disables Notification Center, application toast notifications, and lock-screen notifications to avoid interruptions.' `
            -DescriptionZh '关闭通知中心、应用横幅通知和锁屏通知，避免无人值守界面被系统消息打断。' `
            -NoticeEn 'Normal system and application notifications will be hidden. Ensure critical alerts have another delivery channel.' `
            -NoticeZh '用户将看不到常规系统和应用通知，请确保重要告警有其他通道。'),
        (New-WinConfCatalogItem -Name 'Privacy' -Language $Language `
            -DisplayNameEn 'Privacy and Telemetry' -DisplayNameZh '隐私与遥测' `
            -DescriptionEn 'Reduces telemetry, disables the telemetry service, and prevents activity history from being published or uploaded.' `
            -DescriptionZh '降低系统遥测级别、停用遥测服务，并关闭活动历史的发布和上传。' `
            -NoticeEn 'Some diagnostic capabilities will be limited, and enterprise policy may override these settings.' `
            -NoticeZh '部分诊断能力会受限，企业管理策略可能覆盖这些设置。'),
        (New-WinConfCatalogItem -Name 'UI' -Language $Language `
            -DisplayNameEn 'Desktop Interface' -DisplayNameZh '桌面界面' `
            -DescriptionEn 'Hides Task View, news, widgets, and Meet Now taskbar entry points to keep the terminal desktop clean.' `
            -DescriptionZh '隐藏任务视图、资讯、小组件和“立即开会”等任务栏入口，保持终端桌面简洁。' `
            -NoticeEn 'Available settings vary by Windows version. Unsupported settings are shown as not applicable.' `
            -NoticeZh '不同 Windows 版本支持的项目不同，不适用项会在状态表中标明。')
    )
}
