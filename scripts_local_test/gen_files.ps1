# Set the path to the backup directory
$backupDir = "C:\Users\fabio\Desktop\backuptest\backup"

# Create the backup directory if it doesn't exist
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir
}

# Define hardcoded dates, times, and random numbers
$hardcodedData = @(
    @{Date = "2024_10_05"; Time = "020004"; RandomNumber = "7272362"},
    @{Date = "2024_10_06"; Time = "020004"; RandomNumber = "9064521"},
    @{Date = "2024_10_07"; Time = "020004"; RandomNumber = "9999021"},
    @{Date = "2024_10_08"; Time = "020004"; RandomNumber = "9962021"},
    @{Date = "2024_10_09"; Time = "020004"; RandomNumber = "1232021"},
    @{Date = "2024_10_10"; Time = "020004"; RandomNumber = "9083021"},
    @{Date = "2024_10_11"; Time = "020004"; RandomNumber = "9062021"},
    @{Date = "2024_10_12"; Time = "130015"; RandomNumber = "9511209"},
    @{Date = "2024_10_13"; Time = "092530"; RandomNumber = "9399063"},
    @{Date = "2024_10_14"; Time = "153045"; RandomNumber = "9536601"},
    @{Date = "2024_10_15"; Time = "113020"; RandomNumber = "9616881"},
    @{Date = "2024_10_16"; Time = "173055"; RandomNumber = "9273034"},
    @{Date = "2024_10_17"; Time = "220040"; RandomNumber = "9172077"}
)

# Helper function to update file metadata
function Update-FileMetadata {
    param(
        [string]$filePath,
        [string]$date,
        [string]$time
    )
    # Parse date string (format: YYYY_MM_DD) into a proper DateTime object
    $dateParts = $date -split "_"
    $timeParts = $time -split "(?<=\G.{2})(?!$)"  # Split into hours, minutes, seconds

    # Create a DateTime object using date and time
    $creationDate = [datetime]::new($dateParts[0], $dateParts[1], $dateParts[2], $timeParts[0], $timeParts[1], $timeParts[2])

    # Set CreationTime, LastWriteTime, and LastAccessTime
    Set-ItemProperty -Path $filePath -Name CreationTime -Value $creationDate
    Set-ItemProperty -Path $filePath -Name LastWriteTime -Value $creationDate
    Set-ItemProperty -Path $filePath -Name LastAccessTime -Value $creationDate
    Write-Host "Updated metadata for: $filePath to $creationDate"
}

# Generate dummy backup files for each hardcoded entry
foreach ($entry in $hardcodedData) {
    $dateString = $entry["Date"]
    $timeString = $entry["Time"]
    $randomNumber = $entry["RandomNumber"]

    # Define backup types
    $backupTypes = @("EDEIALAB_backup", "EDEIALAB_DOC_backup", "master_backup", "model_backup", "msdb_backup")
    
    # Create files for each backup type
    foreach ($backupType in $backupTypes) {
        $fileName = "${backupType}_${dateString}_${timeString}_${randomNumber}.bak"
        $filePath = Join-Path $backupDir $fileName
        
        try {
            # Create the file
            New-Item -ItemType File -Path $filePath -Force -Value "Dummy data"
            Write-Host "Created file: $fileName"
            
            # Update the metadata to reflect the hardcoded date and time
            Update-FileMetadata -filePath $filePath -date $dateString -time $timeString
        } catch {
            Write-Host "Error creating or updating file: $fileName"
            Write-Host "Error details: $($_.Exception.Message)"
        }
    }
}
