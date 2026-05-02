param(
    [Parameter(Mandatory = $true)]
    [string] $Version,

    [Parameter(Mandatory = $true)]
    [int] $AddOnVersion,

    [string] $ApiVersion
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).ProviderPath
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Update-File {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [scriptblock] $Updater
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $content = [System.IO.File]::ReadAllText($Path, $utf8)
    $updated = & $Updater $content

    if ($updated -ne $content) {
        [System.IO.File]::WriteAllText($Path, $updated, $utf8)
        Write-Host "updated $Path"
    }
}

function Replace-WithGroupPrefix {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,

        [Parameter(Mandatory = $true)]
        [string] $Pattern,

        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    return [regex]::Replace($Content, $Pattern, {
        param($match)
        return $match.Groups[1].Value + $Value
    })
}

function Replace-WithTwoGroups {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Content,

        [Parameter(Mandatory = $true)]
        [string] $Pattern,

        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    return [regex]::Replace($Content, $Pattern, {
        param($match)
        return $match.Groups[1].Value + $Value + $match.Groups[2].Value
    })
}

$manifest = Get-ChildItem -LiteralPath $root -Filter "*.txt" -File | Select-Object -First 1
if (-not $manifest) {
    throw "No addon manifest (*.txt) found in $root"
}

Update-File $manifest.FullName {
    param($content)
    $content = Replace-WithGroupPrefix $content '(?m)^(## Version:\s*).+$' $Version
    $content = Replace-WithGroupPrefix $content '(?m)^(## AddOnVersion:\s*)\d+\s*$' ([string]$AddOnVersion)
    if ($ApiVersion) {
        $content = Replace-WithGroupPrefix $content '(?m)^(## APIVersion:\s*).+$' $ApiVersion
    }
    return $content
}

Get-ChildItem -LiteralPath $root -Filter "*.lua" -File -Recurse |
    Where-Object { $_.FullName -notmatch '\\.git\\' } |
    ForEach-Object {
        Update-File $_.FullName {
            param($content)
            $content = Replace-WithTwoGroups $content '(?m)^(\s*[\w_]+\.version\s*=\s*")[^"]*(")' $Version
            $content = Replace-WithTwoGroups $content '(?m)^(\s*[\w_]+\.ADDON_VERSION\s*=\s*")[^"]*(")' $Version
            $content = Replace-WithGroupPrefix $content '(?m)^(\s*[\w_]+\.addOnVersion\s*=\s*)\d+\s*$' ([string]$AddOnVersion)
            return $content
        }
    }

$handoff = Join-Path $root "docs\CODEX_HANDOFF.md"
Update-File $handoff {
    param($content)
    $content = Replace-WithGroupPrefix $content '(?m)^(Version:\s*).+$' $Version
    $content = Replace-WithGroupPrefix $content '(?m)^(AddOnVersion:\s*)\d+\s*$' ([string]$AddOnVersion)
    return $content
}

Write-Host "Version updated to $Version / $AddOnVersion"
Write-Host "Review with: git diff --check; git diff"
