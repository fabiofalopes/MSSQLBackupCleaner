# Define the backup path
# $backupPath = "C:\Users\fabio\Desktop\backuptest\backup"
$backupPath = "D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup"

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

# Sort the files by date and keep only the 5 most recent
$filesToKeep = $zipFilesWithDate | Sort-Object -Property Date -Descending | Select-Object -First 5

# Get the files to delete
$filesToDelete = $zipFilesWithDate | Where-Object { $_.File -notin $filesToKeep.File }

# Delete the files
$filesToDelete | ForEach-Object { Remove-Item -Path $_.File.FullName -Force -Verbose }