using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("WinConf")]
[assembly: AssemblyDescription("Windows configuration center")]
[assembly: AssemblyCompany("Mostorm Labs")]
[assembly: AssemblyProduct("WinConf")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

internal static class Program
{
    [STAThread]
    private static int Main()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string script = Path.Combine(root, "scripts", "WinConf.Gui.ps1");

        if (!File.Exists(script))
        {
            MessageBox.Show(
                "未找到界面脚本：\r\n" + script + "\r\n\r\n请将 WinConf.exe 保留在项目根目录中。",
                "WinConf 启动失败",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 2;
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.System),
                @"WindowsPowerShell\v1.0\powershell.exe"),
            Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File \"" + script + "\"",
            WorkingDirectory = root,
            UseShellExecute = false,
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden
        };

        try
        {
            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception exception)
        {
            MessageBox.Show(
                "无法启动 WinConf：\r\n" + exception.Message,
                "WinConf 启动失败",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
    }
}
