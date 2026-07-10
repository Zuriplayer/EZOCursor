$projectRoot = (Get-Item -Path (Join-Path $PSScriptRoot "..")).FullName
$familyRoot = (Get-Item -Path (Join-Path $projectRoot "..")).FullName
$familyScript = Join-Path $familyRoot "EZOFamilyTools\bump-version.ps1"

if (-not (Test-Path -LiteralPath $familyScript)) {
    throw "Shared EZO version tool not found: $familyScript"
}

& $familyScript -ProjectRoot $projectRoot @args
exit $LASTEXITCODE
