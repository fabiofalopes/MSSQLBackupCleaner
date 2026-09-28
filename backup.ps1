param(
    [Parameter(Mandatory)][string]$Database,
    [Parameter(Mandatory)][string]$Instance,
    [Parameter(Mandatory)][string]$BackupDir,
    [string]$LogDir = "C:\Scripts",
    [int]$Keep      = 3
)

$logFile = Join-Path $LogDir "backup-log.txt"
$bakFile = Join-Path $BackupDir ("{0}_{1:yyyy-MM-dd_HHmmss}.bak" -f $Database, (Get-Date))

function Log($msg) {
    $line = "[{0:yyyy-MM-dd HH:mm:ss}] {1}" -f (Get-Date), $msg
    Add-Content $logFile $line
    Write-Host $line
}

New-Item -ItemType Directory -Force $BackupDir, $LogDir | Out-Null

Log "backup started: $Database"

# Express has no COMPRESSION, so it's left out on purpose
sqlcmd -S $Instance -E -b -Q "BACKUP DATABASE [$Database] TO DISK = N'$bakFile' WITH INIT, CHECKSUM, STATS = 10"

if ($LASTEXITCODE -ne 0) {
    Log "backup FAILED (sqlcmd exit code $LASTEXITCODE)"
    Remove-Item $bakFile -Force -ErrorAction SilentlyContinue
    exit 1
}
Log "backup ok: $bakFile"

# only prune after a good backup, keep the newest $Keep
Get-ChildItem $BackupDir -Filter "${Database}_*.bak" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $Keep |
    ForEach-Object {
        Log "removing $($_.Name)"
        Remove-Item $_.FullName -Force
    }

Log "done"
