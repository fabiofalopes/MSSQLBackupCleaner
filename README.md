# MSSQLBackupCleaner

Nightly full backup of one SQL Server database (Express works fine), keeping
the newest few `.bak` files. It runs unattended from Task Scheduler and logs
to a text file. No zip archives, no email, no config files.

The job is `backup.ps1`. `Register-Task.ps1` is a one-time setup script. The
scripts hold no server-specific values: database, instance and paths are
passed when you register the task, and the scheduled task remembers them.

## Setup

1. Copy `backup.ps1` and `Register-Task.ps1` to `C:\Scripts`.
2. Register the daily task (it prompts for the account's password):

       powershell -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Register-Task.ps1 `
           -Account <local admin account> `
           -Database <database> `
           -Instance "<server\instance>" `
           -BackupDir "C:\Program Files\Microsoft SQL Server\MSSQL16.<INSTANCE>\MSSQL\Backup"

   Default run time is 02:00; pass `-RunTime "03:30"` to change it.
3. Test it once by hand:

       powershell -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\backup.ps1 `
           -Database <database> -Instance "<server\instance>" `
           -BackupDir "C:\Program Files\Microsoft SQL Server\MSSQL16.<INSTANCE>\MSSQL\Backup"

   then check the log and the backup folder as described below.

The task runs with the highest privileges, stops itself after 3 hours, and if
the server was off at the run time it starts as soon as the server is back.
To change the time, account or anything else about the task, re-run
`Register-Task.ps1` instead of editing the task by hand.

## Backup folder and permissions

The default choice is the instance's own backup folder,
`C:\Program Files\Microsoft SQL Server\MSSQL16.<INSTANCE>\MSSQL\Backup`
(`MSSQL16` is SQL Server 2022; older versions use smaller numbers). The SQL
Server service account already has write access there, so no folder
permissions need to be set. To see which account that is:

    Get-CimInstance Win32_Service -Filter "Name='MSSQL$<INSTANCE>'" | Select-Object StartName

If the backups go to any other folder, that account needs Modify access or
every backup fails with "Operating system error 5":

    icacls "C:\Some\Folder" /grant "NT SERVICE\MSSQL$<INSTANCE>:(OI)(CI)M"

## Reading the log

The log is `C:\Scripts\backup-log.txt`, one line per event. A healthy run:

    [2026-09-28 02:00:01] backup started: appdb
    [2026-09-28 02:16:40] backup ok: C:\...\appdb_2026-09-28_020001.bak
    [2026-09-28 02:16:41] removing appdb_2026-09-25_020003.bak
    [2026-09-28 02:16:41] done

The last line of a run must be `done`. A `removing` line only appears once
there are more backups than `-Keep` (default 3). If the newest
`backup started` is more than a day old, the job is not running and nobody
will tell you.

## Lessons learned

- The task action must be `powershell.exe` with `-NoProfile -ExecutionPolicy
  Bypass -File "C:\Scripts\backup.ps1"`. Putting the `.ps1` itself in
  "Program/script" makes Windows open it in Notepad instead of running it —
  quietly, every night. That cost us three nights of backups.
- The task has a 3 hour execution limit. The default is 72 hours, so one hung
  run would block every run after it for days.
- On one of our servers, the task setting for overlapping runs only accepts
  `Parallel`, `Queue` or `IgnoreNew`; `StopExisting` is not available from
  PowerShell. The time limit is what clears a stuck run.
- The SQL Server service account writes the `.bak`, not the account the task
  runs as. The instance default backup folder already belongs to it; any other
  folder needs the icacls grant shown above.
- Old backups are deleted only after a successful backup, by count, not by
  age. A streak of failures can never delete the last good backups, and a
  failed run deletes its own partial `.bak`.
- Editing a scheduled task that stores a password requires passing the account
  and password again, or it fails with "user name or password is incorrect".
  That is why `Register-Task.ps1` replaces the task instead of editing it.
