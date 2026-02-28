param(
    [string]$TargetDir = "."
)

$TemplatePath = Join-Path $PSScriptRoot "..\resources\template.md"
$ContextPath = Join-Path $TargetDir "TASKS.md"

if (Test-Path $ContextPath) {
    Write-Host "TASKS.md already exists at $ContextPath"
}
else {
    Copy-Item $TemplatePath $ContextPath
    Write-Host "Created TASKS.md at $ContextPath"
}
