param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDirectory
)

# Helper function for computing SHA512
function Get-SHA512Hash($filePath) {
    $sha512 = [System.Security.Cryptography.SHA512]::Create()
    $stream = [System.IO.File]::OpenRead($filePath)
    $hash = [BitConverter]::ToString($sha512.ComputeHash($stream)).Replace("-", "").ToLower()
    $stream.Close()
    return $hash
}

# Resolve full path
$TargetDirectory = (Resolve-Path $TargetDirectory).Path
Write-Host "Verifying SHA512 hash files under: $TargetDirectory" -ForegroundColor Cyan

# Counters for summary
$okCount = 0
$failCount = 0
$missingCount = 0

# Process all files except .sha512 files
Get-ChildItem -Path $TargetDirectory -File -Recurse | Where-Object { $_.Extension -ne ".sha512" } | ForEach-Object {
    $file = $_.FullName
    $shaFile = "$file.sha512"

    if (-not (Test-Path $shaFile)) {
        Write-Host "✗ No hash file found for: $($_.FullName)" -ForegroundColor Red
        $missingCount++
        return
    }

    try {
        # Read the hash from the .sha512 file
        $content = (Get-Content $shaFile -ErrorAction Stop | Select-String "^[0-9a-fA-F]{128}" -AllMatches).Matches.Value
        if (-not $content) {
            Write-Host "✗ Invalid or empty hash in: $shaFile" -ForegroundColor Red
            $failCount++
            return
        }

        $expectedHash = $content.Trim().Split(" ")[0]
        $actualHash = Get-SHA512Hash $file

        if ($actualHash -eq $expectedHash) {
            Write-Host "✓ OK: $($_.FullName)" -ForegroundColor Green
            $okCount++
        } else {
            Write-Host "✗ FAIL: $($_.FullName)" -ForegroundColor Red
            Write-Host "    Expected: $expectedHash" -ForegroundColor DarkGray
            Write-Host "    Found:    $actualHash" -ForegroundColor DarkGray
            $failCount++
        }
    }
    catch {
        Write-Host "✗ Error verifying file: $($_.FullName) — $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

# Summary
Write-Host ""
Write-Host "===== Verification Summary =====" -ForegroundColor Cyan
Write-Host ("OK:        {0}" -f $okCount) -ForegroundColor Green
Write-Host ("FAILED:    {0}" -f $failCount) -ForegroundColor Red
Write-Host ("MISSING:   {0}" -f $missingCount) -ForegroundColor Yellow

if ($failCount -eq 0 -and $missingCount -eq 0) {
    Write-Host "`nAll files verified successfully ✅" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome files failed or were missing hashes ⚠️" -ForegroundColor Red
    exit 1
}
