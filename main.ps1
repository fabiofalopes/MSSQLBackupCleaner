# main.ps1

# Define the script files to run in sequence
$scripts = @(
    ".\zip.ps1",
    ".\delete_bak_files_after_zip.ps1",
    ".\clean_old_zip_files.ps1"
)

# Run each script in sequence
foreach ($script in $scripts) {
    Write-Host "Running $script..."
    & $script
    Write-Host "$script completed."
}

Write-Host "All scripts completed."

Pause # Keeps the window open until you press a key