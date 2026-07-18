# build.ps1 - Compile the WinConf desktop launcher with the Windows C# compiler.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$source = Join-Path $root 'build\WinConf.Launcher.cs'
$manifest = Join-Path $root 'build\WinConf.exe.manifest'
$output = Join-Path $root 'WinConf.exe'

$compilerCandidates = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$compiler = $compilerCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $compiler) {
    throw '未找到 .NET Framework C# 编译器（csc.exe）。'
}

$previousLib = $env:LIB
try {
    # An unrelated invalid LIB entry can make the legacy compiler treat a
    # search-path warning as an Add-Type/Pester error. The launcher has no
    # native library dependency, so isolate the build from that environment.
    $env:LIB = $null
    & $compiler /nologo /target:winexe /optimize+ /platform:x64 `
        /reference:System.dll /reference:System.Windows.Forms.dll `
        "/win32manifest:$manifest" "/out:$output" $source
} finally {
    $env:LIB = $previousLib
}

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $output)) {
    throw "WinConf.exe 构建失败，编译器退出代码：$LASTEXITCODE"
}

$file = Get-Item $output
$hash = (Get-FileHash -Path $output -Algorithm SHA256).Hash
Write-Output "Built: $($file.FullName)"
Write-Output "Size:  $($file.Length) bytes"
Write-Output "SHA256: $hash"
