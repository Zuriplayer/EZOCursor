param(
    [Parameter(Position = 0)]
    [string]$Version,

    [switch]$Patch
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "EZOCursor.txt"
$corePath = Join-Path $repoRoot "modules\core.lua"

if (-not (Test-Path $manifestPath)) {
    throw "Manifest not found: $manifestPath"
}

if (-not (Test-Path $corePath)) {
    throw "Core file not found: $corePath"
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$manifestContent = [System.IO.File]::ReadAllText($manifestPath, $utf8)
$coreContent = [System.IO.File]::ReadAllText($corePath, $utf8)

$manifestMatch = [regex]::Match($manifestContent, '(?m)^## Version:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$')
$coreMatch = [regex]::Match($coreContent, '(?m)^EZOCursor\.ADDON_VERSION\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+)"\s*$')

if (-not $manifestMatch.Success) {
    throw "Could not read version from EZOCursor.txt"
}

if (-not $coreMatch.Success) {
    throw "Could not read version from modules/core.lua"
}

$currentManifestVersion = $manifestMatch.Groups[1].Value
$currentCoreVersion = $coreMatch.Groups[1].Value

if ($currentManifestVersion -ne $currentCoreVersion) {
    throw "Version mismatch between manifest ($currentManifestVersion) and core.lua ($currentCoreVersion)"
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    if (-not $Patch) {
        throw "Provide a version like 0.1.1 or use -Patch"
    }

    $parts = $currentManifestVersion.Split(".")
    if ($parts.Count -ne 3) {
        throw "Current version format is not supported: $currentManifestVersion"
    }

    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patchNumber = [int]$parts[2] + 1
    $Version = "$major.$minor.$patchNumber"
}

if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
    throw "Version must use semantic format major.minor.patch"
}

$updatedManifest = [regex]::Replace(
    $manifestContent,
    '(?m)^## Version:\s*[0-9]+\.[0-9]+\.[0-9]+\s*$',
    "## Version: $Version",
    1
)

$updatedCore = [regex]::Replace(
    $coreContent,
    '(?m)^EZOCursor\.ADDON_VERSION\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"\s*$',
    "EZOCursor.ADDON_VERSION = `"$Version`"",
    1
)

[System.IO.File]::WriteAllText($manifestPath, $updatedManifest, $utf8)
[System.IO.File]::WriteAllText($corePath, $updatedCore, $utf8)

Write-Host "Version updated: $currentManifestVersion -> $Version"
