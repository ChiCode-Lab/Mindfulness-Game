param(
    [Parameter(Mandatory = $true)]
    [int]$iterations
)

if ($iterations -le 0) {
    Write-Host "Please provide a positive number of iterations." -ForegroundColor Red
    return
}

# Ensure we're in the right directory
$rootPath = $PSScriptRoot
if (-not $rootPath) { $rootPath = $PWD }

$promptPath = Join-Path $rootPath "PROMPT.md"
if (-not (Test-Path $promptPath)) {
    Write-Host "Error: Could not find PROMPT.md at $promptPath" -ForegroundColor Red
    return
}

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "Iteration $i of $iterations" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    $promptContent = Get-Content -Path $promptPath -Raw
    
    # Execute opencode using the 'run' subcommand with the prompt content
    Write-Host "Running opencode..." -ForegroundColor Gray
    
    $result = & opencode run "$promptContent" 2>&1
    
    # Process the result (it might be an array of objects/strings in PowerShell)
    $resultString = $result -join "`r`n"
    Write-Output $resultString

    if ($resultString -match "<promise>COMPLETE</promise>") {
        Write-Host "`n[SUCCESS] All tasks reported complete after $i iterations." -ForegroundColor Green
        break
    }
    
    Write-Host "`n--- End of iteration $i ---" -ForegroundColor Gray
}

Write-Host "`nAutomation finished." -ForegroundColor Cyan
