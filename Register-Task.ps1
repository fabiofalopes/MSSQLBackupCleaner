param(
    [string]$TaskName   = "Nightly database backup",
    [string]$ScriptPath = "C:\Scripts\backup.ps1",
    [string]$RunTime    = "02:00",
    [string]$LogDir     = "C:\Scripts",
    [int]$Keep          = 3,
    [Parameter(Mandatory)][string]$Account,
    [Parameter(Mandatory)][string]$Database,
    [Parameter(Mandatory)][string]$Instance,
    [Parameter(Mandatory)][string]$BackupDir
)

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script not found: $ScriptPath"
    exit 1
}

$secure = Read-Host -Prompt "Password for $Account" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

# The action must be powershell.exe with -File. The .ps1 path alone makes
# Task Scheduler open the script in Notepad instead of running it.
# Database, instance and paths are passed as arguments, so the scripts in
# git hold no server-specific values.
$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" +
    " -Database $Database -Instance $Instance -Keep $Keep" +
    " -BackupDir `"$BackupDir`" -LogDir `"$LogDir`""
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Daily -At $RunTime
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 3) -MultipleInstances IgnoreNew -StartWhenAvailable

# Replaces an existing task. Set-ScheduledTask would need the password passed
# again anyway, so re-registering is simpler and avoids that failure mode.
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$register = @{
    TaskName = $TaskName
    Action   = $action
    Trigger  = $trigger
    Settings = $settings
    User     = $Account
    Password = $password
    RunLevel = "Highest"
}
Register-ScheduledTask @register | Out-Null

Write-Host "Task '$TaskName' registered: daily at $RunTime, limit 3h, as $Account."
Write-Host "Backing up $Database from $Instance to $BackupDir."
