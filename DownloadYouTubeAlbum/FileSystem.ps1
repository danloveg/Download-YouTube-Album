Function CleanFolderIfEmpty($artistFolderName) {
    $numFilesInArtistFolder = (Get-ChildItem -Recurse -File -Path $artistFolderName | Measure-Object).Count
    If ($numFilesInArtistFolder -eq 0) {
        Remove-Item -Recurse -Force $artistFolderName
    }
}

Function CreateNewFolder($folderName) {
    If (-Not(Test-Path -Path $folderName -PathType Container)) {
        New-Item -ItemType Directory -Path $folderName | Out-Null
    }
}