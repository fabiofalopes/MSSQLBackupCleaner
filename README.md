# MSSQLBackupCleaner

We are managing backups from an instance of a Microsoft SQL Server database.
We utilize a scheduled maintenance plan within Microsoft SQL Server Management Studio to generate all necessary backup files.

# Steps

The idea is to run the scripts in sequence. So 'main.ps1' does that.

1. zip backup files ('zip.ps1');
    - using [PS7Zip](https://github.com/GavinEke/PS7Zip)
2. delete just zipped .bak files of the same date ('delete_bak_files_after_zip.ps1');
3. keep only the 5 latest zip files ('clean_old_zip_files.ps1');

# Schedule

Create a schedule for 'main.ps1' script.

# Requirements

- Change the '$backupPath' inside each script.
- Check [How to allow scripts to run](https://learn.microsoft.com/en-us/previous-versions//bb613481(v=vs.85)?redirectedfrom=MSDN) if can't run .ps1 scripts.

## TODO 

- [ ] Read the '$backupPath' from the 'main.ps1' script or from a .env file.
