using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("WinConf")]
[assembly: AssemblyDescription("Windows configuration center")]
[assembly: AssemblyCompany("Mostorm Labs")]
[assembly: AssemblyProduct("WinConf")]
[assembly: AssemblyVersion("1.1.0.0")]
[assembly: AssemblyFileVersion("1.1.0.0")]

internal static class Program
{
    private const string ScriptResourcePrefix = "WinConf.Script.";

    [STAThread]
    private static int Main()
    {
        string extractionRoot = null;

        try
        {
            extractionRoot = ExtractScripts();
            string script = Path.Combine(extractionRoot, "scripts", "WinConf.Gui.ps1");
            if (!File.Exists(script))
                throw new InvalidDataException("The embedded GUI entry script is missing.");

            var startInfo = new ProcessStartInfo
            {
                FileName = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.System),
                    @"WindowsPowerShell\v1.0\powershell.exe"),
                Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File \"" + script + "\"",
                WorkingDirectory = extractionRoot,
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            };

            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception exception)
        {
            MessageBox.Show(
                "Unable to start WinConf:\r\n" + exception.Message +
                "\r\n\r\n无法启动 WinConf。",
                "WinConf startup failed / 启动失败",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
        finally
        {
            DeleteExtractionDirectory(extractionRoot);
        }
    }

    private static string ExtractScripts()
    {
        string root = Path.Combine(Path.GetTempPath(), "WinConf", Guid.NewGuid().ToString("N"));
        string normalizedRoot = Path.GetFullPath(root + Path.DirectorySeparatorChar);
        Assembly assembly = Assembly.GetExecutingAssembly();
        int extractedCount = 0;

        try
        {
            foreach (string resourceName in assembly.GetManifestResourceNames())
            {
                if (!resourceName.StartsWith(ScriptResourcePrefix, StringComparison.Ordinal))
                    continue;

                string relativePath = DecodeHexPath(resourceName.Substring(ScriptResourcePrefix.Length));
                string targetPath = Path.GetFullPath(Path.Combine(root, relativePath.Replace('/', Path.DirectorySeparatorChar)));
                if (!targetPath.StartsWith(normalizedRoot, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("Invalid embedded script path: " + relativePath);

                string directory = Path.GetDirectoryName(targetPath);
                Directory.CreateDirectory(directory);
                using (Stream source = assembly.GetManifestResourceStream(resourceName))
                {
                    if (source == null)
                        throw new InvalidDataException("Unable to read embedded resource: " + resourceName);
                    using (FileStream target = new FileStream(targetPath, FileMode.CreateNew, FileAccess.Write, FileShare.Read))
                        source.CopyTo(target);
                }
                extractedCount++;
            }

            if (extractedCount == 0)
                throw new InvalidDataException("No embedded PowerShell scripts were found.");
            return root;
        }
        catch
        {
            DeleteExtractionDirectory(root);
            throw;
        }
    }

    private static string DecodeHexPath(string hex)
    {
        if (hex.Length == 0 || (hex.Length % 2) != 0)
            throw new InvalidDataException("Invalid embedded script resource name.");

        byte[] bytes = new byte[hex.Length / 2];
        for (int i = 0; i < bytes.Length; i++)
            bytes[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16);
        return Encoding.UTF8.GetString(bytes);
    }

    private static void DeleteExtractionDirectory(string path)
    {
        if (String.IsNullOrEmpty(path))
            return;

        for (int attempt = 0; attempt < 5; attempt++)
        {
            try
            {
                if (Directory.Exists(path))
                    Directory.Delete(path, true);
                return;
            }
            catch (IOException)
            {
                Thread.Sleep(100);
            }
            catch (UnauthorizedAccessException)
            {
                Thread.Sleep(100);
            }
        }
    }
}
