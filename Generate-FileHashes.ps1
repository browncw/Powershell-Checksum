param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDirectory
)

$TargetDirectory = (Resolve-Path $TargetDirectory).Path

Write-Host "Generating SHA512 hash files under: $TargetDirectory" -ForegroundColor Cyan

# Recurse through all files
Get-ChildItem -Path $TargetDirectory -File -Recurse | Where-Object { ($_.Extension -ne ".sha512") -or  (![System.IO.File]::Exists($_.FullName + ".sha512")) } | ForEach-Object {
    try {
        $file = $_.FullName
        $hash = (Get-FileHash -Algorithm SHA512 -Path $file).Hash
        $shaFile = "$file.sha512"

        # Write the hash in standard format: "<hash>  <filename>"
        "$hash  $($_.Name)" | Out-File -FilePath $shaFile -Encoding ascii -Force

        Write-Host "✓ $($_.FullName)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to hash file: $($_.FullName) — $($_.Exception.Message)"
    }
}

Write-Host "All SHA512 hash files generated successfully." -ForegroundColor Cyan
