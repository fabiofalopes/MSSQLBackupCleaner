# Set the specific backup directory path
# $backupPath = "C:\Users\fabio\Desktop\backuptest\backup"
$backupPath = "D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup"

function Remove-ProcessedBackups {
    param (
        [string]$backupFolder = "C:\Users\fabio\Desktop\backuptest\backup"
    )

    Write-Host "Starting backup cleanup process..."
    Write-Host "Scanning folder: $backupFolder"

    # Get all zip files
    $zipFiles = Get-ChildItem -Path $backupFolder -Filter "DatabaseBackups_*.zip"
    Write-Host "Found $($zipFiles.Count) zip files"

    foreach ($zipFile in $zipFiles) {
        Write-Host "`nProcessing zip file: $($zipFile.Name)"
        
        # Extract date from zip filename (format: DatabaseBackups_20241004.zip)
        if ($zipFile.Name -match "DatabaseBackups_(\d{8})\.zip") {
            $dateString = $matches[1]
            # Convert to date format in .bak files (2024_10_04)
            $formattedDate = "{0}_{1}_{2}" -f $dateString.Substring(0,4), 
                                            $dateString.Substring(4,2), 
                                            $dateString.Substring(6,2)
            
            Write-Host "Looking for backup files from date: $formattedDate"

            # Verify zip file integrity
            try {
                $testResult = Test-Archive -Path $zipFile.FullName
                if (-not $testResult) {
                    Write-Host "Warning: Zip file $($zipFile.Name) appears to be corrupt. Skipping cleanup for this date." -ForegroundColor Yellow
                    continue
                }
            }
            catch {
                Write-Host "Error testing zip file $($zipFile.Name). Skipping cleanup for this date." -ForegroundColor Red
                Write-Host "Error: $_"
                continue
            }

            # Find corresponding .bak files
            $bakFiles = Get-ChildItem -Path $backupFolder -Filter "*.bak" | 
                       Where-Object { $_.Name -like "*$formattedDate*" }

            if ($bakFiles.Count -gt 0) {
                Write-Host "Found $($bakFiles.Count) .bak files to remove"
                
                # Create a backup log entry
                $logEntry = [PSCustomObject]@{
                    Date = Get-Date
                    ZipFile = $zipFile.Name
                    RemovedFiles = $bakFiles.Name -join ', '
                }

                # Log the files being removed
                $logFile = Join-Path $backupFolder "cleanup_log.json"
                if (Test-Path $logFile) {
                    $existingLog = Get-Content $logFile | ConvertFrom-Json
                    $existingLog = [array]$existingLog + [array]$logEntry
                    $existingLog | ConvertTo-Json -Depth 100 | Set-Content $logFile
                } else {
                    @($logEntry) | ConvertTo-Json -Depth 100 | Set-Content $logFile
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
                Write-Host "No matching .bak files found for date $formattedDate. They may have been already deleted." -ForegroundColor Yellow
                
                # Log that no files were found to remove
                $logEntry = [PSCustomObject]@{
                    Date = Get-Date
                    ZipFile = $zipFile.Name
                    RemovedFiles = "No .bak files found to remove"
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
            }
        } else {
            Write-Host "Warning: Zip file $($zipFile.Name) doesn't match expected naming pattern" -ForegroundColor Yellow
        }
    }
}

# Function to test zip file integrity
function Test-Archive {
    param (
        [string]$Path
    )
    
    try {
        # Try to expand (test) the archive without actually extracting files
        $null = Expand-Archive -Path $Path -DestinationPath "$env:TEMP\testextract" -Force -ErrorAction Stop
        Remove-Item "$env:TEMP\testextract" -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    }
    catch {
        return $false
    }
}

# Run the cleanup
Remove-ProcessedBackups -backupFolder $backupPath

Write-Host "`nCleanup process completed." 

# Press any key to exit..."
# $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')