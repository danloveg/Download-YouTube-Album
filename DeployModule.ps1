<#
 # Purpose: Allows the user's PowerShell modules to be up to date with the
 # current working contents of this repository.
 #
 # This script deploys the contents of the MODULE_NAME folder to the user's
 # PowerShell modules folder. It checks to see if file contents are different
 # before overwriting the outdated files.
 #
 # If you want to use this script for a different PowerShell module, you
 # simply would need to change $MODULE_NAME and put the script one level
 # above the module you are targeting.
 #>

$MODULE_NAME = "DownloadYouTubeAlbum"

If (-Not (Test-Path $Profile -ErrorAction SilentlyContinue)) {
    Write-Host "Create a PowerShell profile first before deploying." -ForegroundColor Red
    Exit
}

$profileFolder = (Get-Item $Profile).Directory
$destinationFolder = Join-Path -Path $profileFolder -ChildPath "Modules/$($MODULE_NAME)"
$sourceFolder = Join-Path (Get-Item $PSScriptRoot) -ChildPath $MODULE_NAME

If (-Not (Test-Path $destinationFolder -PathType Container)) {
    New-Item $destinationFolder -ItemType Directory -Force | Out-Null
}

$filesUpdated = 0
Write-Host "Deploying $($MODULE_NAME) module files to $($destinationFolder)"
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

$profileContents = Get-Content $Profile -Raw
If (-Not ($profileContents -Match $MODULE_NAME)) {
    Write-Host "`nWARNING: It appears that you have not imported $($MODULE_NAME) in your PowerShell profile." -ForegroundColor Yellow
    Write-Host "Add the following line to your PowerShell profile ($($Profile)):"
    Write-Host "Import-Module $($MODULE_NAME)"
}