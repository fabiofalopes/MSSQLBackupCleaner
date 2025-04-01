# Import the environment variables module
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "Get-EnvVariable.psm1") -Force

# Read configuration from .env file
$backupPath = Get-EnvVariable -Key "BACKUP_PATH"

# Validate configuration
if (-not $backupPath) {
    Write-Error "BACKUP_PATH not found in .env file. Please check your configuration."
    exit 1
}

function Test-Archive {
    param (
        [string]$Path
    )
    
    try {
        # Use System.IO.Compression.ZipFile to quickly check the zip file
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $zip.Dispose()
        return $true
    }
    catch {
        Write-Host "Error testing zip file: $_" -ForegroundColor Red
        return $false
    }
}

function Remove-ProcessedBackups {
    param (
        [string]$backupFolder = $backupPath
    )

    Write-Host "Starting backup cleanup process..."
    Write-Host "Scanning folder: $backupFolder"

    # Get all zip files
    $zipFiles = Get-ChildItem -Path $backupFolder -Filter "DatabaseBackups_*.zip" | Sort-Object LastWriteTime -Descending
    Write-Host "Found $($zipFiles.Count) zip files"

    # Get the most recent zip file date
    $mostRecentZipDate = ($zipFiles | Select-Object -First 1).BaseName -replace 'DatabaseBackups_', ''
    $mostRecentDate = [DateTime]::ParseExact($mostRecentZipDate, 'yyyyMMdd', $null)

    foreach ($zipFile in $zipFiles) {
        Write-Host "`nProcessing zip file: $($zipFile.Name)"
        
        if ($zipFile.Name -match "DatabaseBackups_(\d{8})\.zip") {
            $dateString = $matches[1]
            $zipDate = [DateTime]::ParseExact($dateString, 'yyyyMMdd', $null)
            
            Write-Host "Looking for backup files from date: $($zipDate.ToString('yyyy_MM_dd'))"

            if (-not (Test-Archive -Path $zipFile.FullName)) {
                Write-Host "Warning: Zip file $($zipFile.Name) appears to be corrupt. Skipping cleanup for this date." -ForegroundColor Yellow
                continue
            }

            # Find corresponding .bak files
            $bakFiles = if ($zipDate -eq $mostRecentDate) {
                # For the most recent date, get all .bak files created on or after this date
                Get-ChildItem -Path $backupFolder -Filter "*.bak" | 
                Where-Object { $_.LastWriteTime -ge $zipDate.Date }
            } else {
                # For older dates, use the exact date match
                Get-ChildItem -Path $backupFolder -Filter "*.bak" | 
                Where-Object { $_.Name -like "*$($zipDate.ToString('yyyy_MM_dd'))*" }
            }

            if ($bakFiles.Count -gt 0) {
                Write-Host "Found $($bakFiles.Count) .bak files to remove"
                
                # Create a backup log entry
                $logEntry = [PSCustomObject]@{
                    Date = Get-Date
                    ZipFile = $zipFile.Name
                    RemovedFiles = $bakFiles.Name -join ', '
                }

                # Remove the .bak files
                foreach ($bakFile in $bakFiles) {
                    try {
                        Remove-Item $bakFile.FullName -Force
                        Write-Host "Removed: $($bakFile.Name)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Error removing $($bakFile.Name): $_" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "No matching .bak files found for date $($zipDate.ToString('yyyy_MM_dd')). They may have been already deleted." -ForegroundColor Yellow
                
                # Log that no files were found to remove
                $logEntry = [PSCustomObject]@{
                    Date = Get-Date
                    ZipFile = $zipFile.Name
                    RemovedFiles = "No .bak files found to remove"
                }
            }
            
            # Update the log file
            $logFile = Join-Path $backupFolder "cleanup_log.json"
            if (Test-Path $logFile) {
                $existingLog = Get-Content $logFile | ConvertFrom-Json
                $existingLog = [array]$existingLog + [array]$logEntry
                $existingLog | ConvertTo-Json -Depth 100 | Set-Content $logFile
            } else {
                @($logEntry) | ConvertTo-Json -Depth 100 | Set-Content $logFile
            }
        } else {
            Write-Host "Warning: Zip file $($zipFile.Name) doesn't match expected naming pattern" -ForegroundColor Yellow
        }
    }
}

# Run the cleanup
Remove-ProcessedBackups -backupFolder $backupPath

Write-Host "`nCleanup process completed." 

# Press any key to exit..."
# $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')