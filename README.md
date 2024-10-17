# MySQL backup cleanup

We are managing backups from an instance of a Microsoft SQL Server database.
We utilize a scheduled maintenance plan within Microsoft SQL Server Management Studio (SSMS) to generate all necessary backup files.

# Steps

The idea is to run the scripts in sequence. So 'main.ps1' does that.

1. zip backup files ('zip.ps1')
2. delete just zipped .bak files of the same date ('delete_bak_files_after_zip.ps1')
3. keep only the 5 latest zip files ('clean_old_zip_files.ps1')

# Schedule

Create a schedule for 'main.ps1' script.

# Change the '$backupPath' inside each script

## TODO 
Read the '$backupPath' from the 'main.ps1' script or from a .env file.
