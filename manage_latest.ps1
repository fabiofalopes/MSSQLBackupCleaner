# Path configurations
$backupPath = "D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup"
$backupPathLatest = Join-Path -Path $backupPath -ChildPath "latest"

# Ensure 'latest' folder exists
if (!(Test-Path -Path $backupPathLatest)) {
    New-Item -ItemType Directory -Path $backupPathLatest -Force | Out-Null
    Write-Host "'latest' folder created at $backupPathLatest"
} else {
    Write-Host "'latest' folder already exists at $backupPathLatest"
}

# Get the list of zip files, sorted by date (most recent first)
$zipFiles = Get-ChildItem -Path $backupPath -Filter "*.zip" | Sort-Object LastWriteTime -Descending

if ($zipFiles.Count -eq 0) {
    Write-Host "No zip files found in $backupPath"
    return
}

# Move the latest zip file to the 'latest' folder
$latestZipFile = $zipFiles[0]
$destinationPath = Join-Path -Path $backupPathLatest -ChildPath $latestZipFile.Name

# Move any existing files from 'latest' back to $backupPath before moving the new latest zip
$existingFilesInLatest = Get-ChildItem -Path $backupPathLatest -Filter "*.zip"

foreach ($file in $existingFilesInLatest) {
    Move-Item -Path $file.FullName -Destination $backupPath -Force
    Write-Host "Moved old file $($file.Name) from 'latest' back to $backupPath"
}

# Now move the newest zip file into 'latest'
Move-Item -Path $latestZipFile.FullName -Destination $destinationPath -Force
Write-Host "Moved latest zip file $($latestZipFile.Name) to 'latest' folder at $backupPathLatest"

Write-Host "Script execution completed. The latest backup file is now in the 'latest' folder."
