# build.ps1 - Compile the WinConf desktop launcher with the Windows C# compiler.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$source = Join-Path $root 'build\WinConf.Launcher.cs'
$manifest = Join-Path $root 'build\WinConf.exe.manifest'
$output = Join-Path $root 'WinConf.exe'
$scriptRoot = Join-Path $root 'scripts'

$embeddedScripts = @(Get-ChildItem -Path $scriptRoot -Recurse -File -Filter '*.ps1' | Sort-Object FullName | ForEach-Object {
    $relativePath = $_.FullName.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
    $pathBytes = [Text.Encoding]::UTF8.GetBytes($relativePath)
    $pathHex = ([BitConverter]::ToString($pathBytes)).Replace('-', '')
    [PSCustomObject]@{
        FullName     = $_.FullName
        RelativePath = $relativePath
        ResourceName = "WinConf.Script.$pathHex"
    }
})

if ($embeddedScripts.Count -eq 0) {
    throw '没有找到需要嵌入的运行时 PowerShell 脚本。'
}

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
    $compilerArguments = @(
        '/nologo', '/target:winexe', '/optimize+', '/platform:x64',
        '/reference:System.dll', '/reference:System.Windows.Forms.dll',
        "/win32manifest:$manifest", "/out:$output", $source
    )
    foreach ($script in $embeddedScripts) {
        $compilerArguments += "/resource:$($script.FullName),$($script.ResourceName)"
    }
    & $compiler @compilerArguments
} finally {
    $env:LIB = $previousLib
}

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $output)) {
    throw "WinConf.exe 构建失败，编译器退出代码：$LASTEXITCODE"
}

$compiledAssembly = [Reflection.Assembly]::Load([IO.File]::ReadAllBytes($output))
$resourceNames = @($compiledAssembly.GetManifestResourceNames() | Where-Object { $_ -like 'WinConf.Script.*' })
if ($resourceNames.Count -ne $embeddedScripts.Count) {
    throw "WinConf.exe 嵌入脚本数量错误：expected=$($embeddedScripts.Count), actual=$($resourceNames.Count)"
}

$programType = $compiledAssembly.GetType('Program', $true)
$bindingFlags = [Reflection.BindingFlags]::Static -bor [Reflection.BindingFlags]::NonPublic
$extractMethod = $programType.GetMethod('ExtractScripts', $bindingFlags)
$deleteMethod = $programType.GetMethod('DeleteExtractionDirectory', $bindingFlags)
$verificationRoot = $null
try {
    $verificationRoot = [string]$extractMethod.Invoke($null, @())
    foreach ($script in $embeddedScripts) {
        $extractedPath = Join-Path $verificationRoot ($script.RelativePath -replace '/', '\')
        if (-not (Test-Path -LiteralPath $extractedPath)) {
            throw "WinConf.exe 未能释放嵌入脚本：$($script.RelativePath)"
        }
        $sourceHash = (Get-FileHash -LiteralPath $script.FullName -Algorithm SHA256).Hash
        $extractedHash = (Get-FileHash -LiteralPath $extractedPath -Algorithm SHA256).Hash
        if ($sourceHash -ne $extractedHash) {
            throw "WinConf.exe 嵌入脚本内容校验失败：$($script.RelativePath)"
        }
    }
    $extractedGui = Join-Path $verificationRoot 'scripts\WinConf.Gui.ps1'
    $smokeOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $extractedGui -SmokeTest 2>&1)
    if ($LASTEXITCODE -ne 0 -or (($smokeOutput -join "`n") -notmatch 'WinConf GUI smoke test passed')) {
        throw "WinConf.exe 单文件 GUI 冒烟验证失败：$($smokeOutput -join ' ')"
    }
} finally {
    if ($deleteMethod -and $verificationRoot) {
        $deleteMethod.Invoke($null, @($verificationRoot)) | Out-Null
    }
}

if ($verificationRoot -and (Test-Path -LiteralPath $verificationRoot)) {
    throw "WinConf.exe 临时目录清理验证失败：$verificationRoot"
}

$file = Get-Item $output
$hash = (Get-FileHash -Path $output -Algorithm SHA256).Hash
Write-Output "Built: $($file.FullName)"
Write-Output "Size:  $($file.Length) bytes"
Write-Output "Scripts: $($embeddedScripts.Count) embedded"
Write-Output 'Standalone extraction: verified'
Write-Output 'Standalone GUI smoke: verified'
Write-Output "SHA256: $hash"
