$ModuleName = "DownloadYouTubeAlbum"

If (-Not (Test-Path $Profile -ErrorAction SilentlyContinue)) {
    Write-Host "Create a PowerShell profile first before deploying." -ForegroundColor Red
    Exit
}

$profileFolder = (Get-Item $Profile).Directory
$destinationFolder = Join-Path -Path $profileFolder -ChildPath "Modules/$($ModuleName)"
$sourceFolder = Join-Path (Get-Item $PSScriptRoot) -ChildPath "DownloadYouTubeAlbum"

$filesUpdated = 0
Write-Host "Deploying module files to $($destinationFolder)"
$sourceFiles = Get-ChildItem -Recurse -File -Path $sourceFolder -Exclude "*.pyc"
ForEach ($sourceFile in $sourceFiles) {
    $destinationFile = $sourceFile.FullName.Replace($sourceFolder, $destinationFolder)

    If (-Not(Test-Path $destinationFile -PathType Leaf)) {
        New-Item -ItemType File -Path $destinationFile -Force | Out-Null
    }

    $destinationFileHash = Get-FileHash -Path $destinationFile -Algorithm SHA1
    $sourceFileHash = Get-FileHash -Path $sourceFile -Algorithm SHA1

    If ($destinationFileHash.Hash -ne $sourceFileHash.Hash) {
        Write-Host "Updating $($destinationFile)"
        Copy-Item -Path $sourceFile.FullName -Destination $destinationFile -Force
        $filesUpdated += 1
    }
}

Write-Host "All changes deployed."
Write-Host "$($filesUpdated) Files updated."
