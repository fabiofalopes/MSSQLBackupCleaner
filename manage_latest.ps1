# Import the environment variables module
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "Get-EnvVariable.psm1") -Force

# Read configuration from .env file
$backupPath = Get-EnvVariable -Key "BACKUP_PATH"
$targetUser = Get-EnvVariable -Key "TARGET_USER"

# Validate configuration
if (-not $backupPath) {
    Write-Error "BACKUP_PATH not found in .env file. Please check your configuration."
    exit 1
}

if (-not $targetUser) {
    Write-Error "TARGET_USER not found in .env file. Please check your configuration."
    exit 1
}

$backupPathLatest = Join-Path -Path $backupPath -ChildPath "latest"

# Create 'latest' folder if it doesn't exist
if (!(Test-Path -Path $backupPathLatest)) {
    New-Item -ItemType Directory -Path $backupPathLatest | Out-Null
}

# Set folder permissions
$acl = Get-Acl -Path $backupPathLatest
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($targetUser, "Read", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $backupPathLatest -AclObject $acl

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
    
    # Set file permissions for the moved file
    $fileAcl = Get-Acl -Path (Join-Path -Path $backupPathLatest -ChildPath $latestZipFile.File.Name)
    $fileAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($targetUser, "Read", "Allow")
    $fileAcl.SetAccessRule($fileAccessRule)
    Set-Acl -Path (Join-Path -Path $backupPathLatest -ChildPath $latestZipFile.File.Name) -AclObject $fileAcl
    
    Write-Host "Moved latest backup: $($latestZipFile.File.Name) to the 'latest' folder and set permissions."
} else {
    Write-Host "No zip files found in $backupPath to process."
}

Write-Host "`nScript execution completed."
