function Get-EnvVariable {
    param (
        [string]$Key
    )
    
    $envPath = Join-Path -Path $PSScriptRoot -ChildPath ".env"
    if (Test-Path $envPath) {
        $content = Get-Content $envPath
        $line = $content | Where-Object { $_ -match "^$Key=" }
        if ($line) {
            return $line -replace "^$Key=", ""
        }
    }
    return $null
}

Export-ModuleMember -Function Get-EnvVariable 