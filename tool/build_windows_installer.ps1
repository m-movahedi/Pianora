[CmdletBinding()]
param(
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$installerScript = Join-Path $projectRoot 'installer\pianora.iss'
$releaseExe = Join-Path $projectRoot 'build\windows\x64\runner\Release\pianora.exe'

$versionLine = Select-String -LiteralPath $pubspecPath -Pattern '^version:\s*([^\s]+)\s*$' | Select-Object -First 1
if (-not $versionLine) {
    throw 'No version entry was found in pubspec.yaml.'
}

$fullVersion = $versionLine.Matches[0].Groups[1].Value
if ($fullVersion -notmatch '^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$') {
    throw "The pubspec version '$fullVersion' must use major.minor.patch+build format."
}

$major = $Matches[1]
$minor = $Matches[2]
$patch = $Matches[3]
$build = if ($Matches[4]) { $Matches[4] } else { '0' }
$versionInfoVersion = "$major.$minor.$patch.$build"
$packageVersion = "$major.$minor.$patch-build$build"

Push-Location $projectRoot
try {
    if (-not $SkipFlutterBuild) {
        & flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }

        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw 'The Flutter Windows release build failed.' }
    }

    if (-not (Test-Path -LiteralPath $releaseExe)) {
        throw "The release executable was not found at '$releaseExe'. Run without -SkipFlutterBuild."
    }

    $isccCandidates = @(
        (Get-Command ISCC.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    $iscc = $isccCandidates | Select-Object -First 1
    if (-not $iscc) {
        throw 'Inno Setup 6 was not found. Install it with: winget install --id JRSoftware.InnoSetup --exact'
    }

    & $iscc "/DMyAppVersion=$fullVersion" "/DMyVersionInfoVersion=$versionInfoVersion" "/DMyPackageVersion=$packageVersion" $installerScript
    if ($LASTEXITCODE -ne 0) { throw 'The installer compilation failed.' }

    $outputPath = Join-Path $projectRoot "installer\output\Pianora-Piano-tranier-Setup-$packageVersion.exe"
    if (-not (Test-Path -LiteralPath $outputPath)) {
        throw "The installer compiler completed, but '$outputPath' was not found."
    }

    Write-Host "Installer ready: $outputPath"
}
finally {
    Pop-Location
}
