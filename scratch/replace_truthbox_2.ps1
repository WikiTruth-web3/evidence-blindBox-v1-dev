$replacements = @(
    @{ Key = 'BlindBox'; Value = 'BlindBox' },
    @{ Key = 'blindBox'; Value = 'blindBox' },
    @{ Key = 'Blind Box'; Value = 'Blind Box' },
    @{ Key = 'blind Box'; Value = 'blind Box' },
    @{ Key = 'blind box'; Value = 'blind box' },
    @{ Key = 'BLIND_BOX'; Value = 'BLIND_BOX' },
    @{ Key = 'Blindbox'; Value = 'Blindbox' }
)

$excludeExts = @('.json', '.jsonl', '.lock', '.yaml', '.png', '.jpg', '.jpeg', '.gif', '.ico', '.pdf')
$excludeDirs = @('artifacts', 'cache', 'typechain-types', 'node_modules', '.git', 'deployments')

Get-ChildItem -Path . -Recurse -File | ForEach-Object {
    $file = $_
    $ext = [System.IO.Path]::GetExtension($file.FullName).ToLower()
    if ($excludeExts -notcontains $ext) {
        $skip = $false
        foreach ($exDir in $excludeDirs) {
            if ($file.FullName -match "[\/\\]$exDir[\/\\]" -or $file.FullName -match "[\/\\]$exDir$") { $skip = $true; break }
        }
        if (-not $skip) {
            try {
                $content = [System.IO.File]::ReadAllText($file.FullName)
                $newContent = $content
                $sortedReplacements = $replacements | Sort-Object { $_.Key.Length } -Descending
                foreach ($rep in $sortedReplacements) {
                    $newContent = $newContent.Replace($rep.Key, $rep.Value)
                }
                if ($newContent -ne $content) {
                    [System.IO.File]::WriteAllText($file.FullName, $newContent)
                    Write-Host "Updated: $($file.FullName)"
                }
            } catch {
                # Ignore
            }
        }
    }
}
