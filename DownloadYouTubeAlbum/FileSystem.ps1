Function CleanFolderIfEmpty($folder) {
    $numFilesInFolder = (Get-ChildItem -Recurse -File -Path $folder | Measure-Object).Count
    If ($numFilesInFolder -eq 0) {
        Remove-Item -Recurse -Force -Path $folder
    }
}

Function CreateNewFolder($folder) {
    If (-Not(Test-Path -Path $folder -PathType Container)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
}