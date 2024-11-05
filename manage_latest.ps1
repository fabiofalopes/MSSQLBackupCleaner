# Paths
$backupPath = "D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup"
$backupPathLatest = Join-Path -Path $backupPath -ChildPath "latest"

# Create 'latest' folder if it doesn't exist
if (!(Test-Path -Path $backupPathLatest)) {
    New-Item -ItemType Directory -Path $backupPathLatest | Out-Null
}

# Get all zip files in the backup path
$zipFiles = Get-ChildItem -Path $backupPath -Filter "DatabaseBackups_*.zip"

# Parse the date from each file name and sort by date
$zipFilesWithDate = $zipFiles | ForEach-Object {
    $dateString = $_.Name -replace 'DatabaseBackups_', '' -replace '.zip', ''
    $date = [datetime]::ParseExact($dateString, 'yyyyMMdd', $null)
    [PSCustomObject]@{
        File = $_
        Date = $date
    }
} | Sort-Object -Property Date -Descending

# Identify the latest zip file
$latestZipFile = $zipFilesWithDate | Select-Object -First 1

# Check if there is already a file in the 'latest' folder
$currentLatestFile = Get-ChildItem -Path $backupPathLatest -Filter "DatabaseBackups_*.zip" | Select-Object -First 1

if ($currentLatestFile) {
    # Move the current latest file back to the main backup path
    Move-Item -Path $currentLatestFile.FullName -Destination $backupPath -Force -Verbose
}

# Move the identified latest zip file to the 'latest' folder
if ($latestZipFile) {
    Move-Item -Path $latestZipFile.File.FullName -Destination $backupPathLatest -Force -Verbose
    Write-Host "Moved latest backup: $($latestZipFile.File.Name) to the 'latest' folder."
} else {
    Write-Host "No zip files found in $backupPath to process."
}

Write-Host "`nScript execution completed."
