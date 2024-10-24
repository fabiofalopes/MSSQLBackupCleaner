# Set the specific backup directory path
# $backupPath = "C:\Users\fabio\Desktop\backuptest\backup"
$backupPath = "D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup"
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
            if (-not (Test-Archive -Path $zipFile.FullName)) {
                Write-Host "Warning: Zip file $($zipFile.Name) appears to be corrupt. Skipping cleanup for this date." -ForegroundColor Yellow
                continue
            }

            # Find corresponding .bak files
            $bakFiles = Get-ChildItem -Path $backupFolder -Filter "*.bak" | 
                       Where-Object { $_.Name -like "*$formattedDate*" }

            if ($bakFiles.Count -gt 0) {
                Write-Host "Found $($bakFiles.Count) .bak files to remove"
                
                # ... (rest of the code for removing files and logging)
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

# Run the cleanup
Remove-ProcessedBackups -backupFolder $backupPath

Write-Host "`nCleanup process completed." 

# Press any key to exit..."
# $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')