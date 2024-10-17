# Set the specific backup directory path
$backupPath = "C:\Users\fabio\Desktop\backuptest\backup"
$destinationPath = $backupPath

function Compress-AllBackupFiles {
    param (
        [string]$sourceFolder = "C:\Users\fabio\Desktop\backuptest\backup",
        [string]$destinationFolder = $sourceFolder
    )

    Write-Host "Looking for backup files in: $sourceFolder"
    Write-Host "Zip files will be created in: $destinationFolder"

    # Get all .bak files in the source folder
    $allBackupFiles = Get-ChildItem -Path $sourceFolder -Filter "*.bak"
    Write-Host "Found $($allBackupFiles.Count) total .bak files"

    # Group files by date using a more robust approach
    $groupedFiles = @{}
    
    foreach ($file in $allBackupFiles) {
        # Match pattern "2024_10_04" in filename
        if ($file.Name -match "(\d{4}_\d{2}_\d{2})") {
            $dateFound = $matches[1]
            Write-Host "Processing file: $($file.Name) - Found date: $dateFound"
            
            if (-not $groupedFiles.ContainsKey($dateFound)) {
                $groupedFiles[$dateFound] = [System.Collections.ArrayList]::new()
            }
            [void]$groupedFiles[$dateFound].Add($file)
        } else {
            Write-Host "Warning: No date pattern found in file: $($file.Name)"
        }
    }

    Write-Host "`nFound backups for $($groupedFiles.Count) different dates"

    foreach ($date in $groupedFiles.Keys) {
        $files = $groupedFiles[$date]
        Write-Host "`nProcessing backups for date: $date"
        Write-Host "Found $($files.Count) files for this date"

        # Format date for the required patterns (using the same format as in files)
        $requiredPatterns = @(
            "EDEIALAB_backup_$date",
            "EDEIALAB_DOC_backup_$date",
            "master_backup_$date",
            "model_backup_$date",
            "msdb_backup_$date"
        )

        $missingFiles = $requiredPatterns | Where-Object {
            $pattern = $_
            -not ($files | Where-Object { $_.Name -like "*$pattern*" })
        }

        if ($missingFiles) {
            Write-Host "Warning: Incomplete backup set for date $date. Missing files:"
            $missingFiles | ForEach-Object { Write-Host "  - $_" }
            continue
        }

        # Create zip file for this date's backups
        # Convert date format from "2024_10_04" to "20241004" for zip filename
        $zipDate = $date.Replace("_", "")
        $zipFileName = Join-Path $destinationFolder "DatabaseBackups_$zipDate.zip"

        try {
            Write-Host "Creating zip file: $zipFileName"
            
            # Create a zip file containing all backup files for this date
            Compress-Archive -Path $files.FullName -DestinationPath $zipFileName -Force
            
            Write-Host "Successfully created zip file for $date"
            Write-Host "Files included:"
            $files | ForEach-Object { Write-Host "  - $($_.Name)" }
            
            # Calculate and display zip file size
            $zipSize = (Get-Item $zipFileName).Length / 1MB
            Write-Host "Zip file size: $([math]::Round($zipSize, 2)) MB"
        }
        catch {
            Write-Host "Error creating zip file for $date`: $_"
        }
    }
}

# Run the function with the specified path
Compress-AllBackupFiles -sourceFolder $backupPath -destinationFolder $destinationPath

#Write-Host "`nScript execution completed. Press any key to exit..."
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')