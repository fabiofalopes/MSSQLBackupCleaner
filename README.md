# MSSQLBackupCleaner

We are managing backups from an instance of a Microsoft SQL Server database.
We utilize a scheduled maintenance plan within Microsoft SQL Server Management Studio to generate all necessary backup files.

# Steps

The idea is to run the scripts in sequence. So 'main.ps1' does that.

1. zip backup files ('zip.ps1') with 7z;
2. delete just zipped .bak files of the same date ('delete_bak_files_after_zip.ps1');
3. keep only the 5 latest zip files ('clean_old_zip_files.ps1');

# Schedule

Create a schedule for 'main.ps1' script.

# Requirements

- Create a `.env` file in the same directory as the scripts:
  1. Copy `.env.example` to `.env`
  2. Update the values in `.env` with your actual configuration:
     ```
     BACKUP_PATH=D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup
     TARGET_USER=DOMAIN\Username
     SEVEN_ZIP_PATH=C:\Program Files\7-Zip\7z.exe
     KEEP_LATEST_ZIPS=5
     ```
     Configuration options:
     - `BACKUP_PATH`: Path to your backup directory
     - `TARGET_USER`: User account that needs read access to the latest backups
     - `SEVEN_ZIP_PATH`: Path to the 7-Zip executable
     - `KEEP_LATEST_ZIPS`: Number of latest zip files to keep (default: 5)
- Check [How to allow scripts to run](https://learn.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)?redirectedfrom=MSDN) if can't run .ps1 scripts.

# Project Structure

- `Get-EnvVariable.psm1`: Shared PowerShell module for reading environment variables
- `manage_latest.ps1`: Script to manage the latest backup file
- `.env`: Configuration file containing environment variables (not tracked in git)
- `.env.example`: Example configuration file (tracked in git)
- Other scripts as mentioned in the Steps section

## TODO 

- [x] Read the '$backupPath' from the 'main.ps1' script or from a .env file.
