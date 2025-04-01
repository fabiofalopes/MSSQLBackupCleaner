# Import the environment variables module
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "Get-EnvVariable.psm1") -Force

# Read configuration from .env file
$backupPath = Get-EnvVariable -Key "BACKUP_PATH"
$keepLatestZips = [int](Get-EnvVariable -Key "KEEP_LATEST_ZIPS")

# Validate configuration
if (-not $backupPath) {
    Write-Error "BACKUP_PATH not found in .env file. Please check your configuration."
    exit 1
}

if (-not $keepLatestZips) {
    Write-Error "KEEP_LATEST_ZIPS not found in .env file. Please check your configuration."
    exit 1
}

# Get all zip files in the backup path
$zipFiles = Get-ChildItem -Path $backupPath -Filter *.zip

# Parse the date from the file name
$zipFilesWithDate = $zipFiles | ForEach-Object {
    $dateString = $_.Name -replace 'DatabaseBackups_', '' -replace '.zip', ''
    $date = [datetime]::ParseExact($dateString, 'yyyyMMdd', $null)
    [PSCustomObject]@{
        File = $_
        Date = $date
    }
}

# Sort the files by date and keep only the most recent ones
$filesToKeep = $zipFilesWithDate | Sort-Object -Property Date -Descending | Select-Object -First $keepLatestZips

# Get the files to delete
$filesToDelete = $zipFilesWithDate | Where-Object { $_.File -notin $filesToKeep.File }

# Delete the files
$filesToDelete | ForEach-Object { Remove-Item -Path $_.File.FullName -Force -Verbose }