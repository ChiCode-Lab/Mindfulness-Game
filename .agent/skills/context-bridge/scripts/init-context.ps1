param(
    [string]$TargetDir = "."
)

$TemplatePath = Join-Path $PSScriptRoot "..\resources\template.md"
$ContextPath = Join-Path $TargetDir "CONTEXT.md"

if (Test-Path $ContextPath) {
    Write-Host "CONTEXT.md already exists at $ContextPath"
} else {
    Copy-Item $TemplatePath $ContextPath
    Write-Host "Created CONTEXT.md at $ContextPath"
}
