Function CleanFolderIfEmpty($folder) {
    $numFilesInFolder = (Get-ChildItem -Recurse -File -Path $folder | Measure-Object).Count
    If ($numFilesInFolder -eq 0) {
        Remove-Item -Recurse -Force -Path $folder
    }
}

Function CreateNewFolder($Folder) {
    $CleanFolder = CleanInvalidFilenameChars -Filename $Folder
    If (-Not(Test-Path -Path $CleanFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $CleanFolder | Out-Null
    }
}

Function CleanInvalidFilenameChars {
    Param(
        [Parameter(Mandatory=$True)]
        [String]
        $Filename
    )
    $CleanName = ([String] $Filename)
    $InvalidChars = ([System.IO.Path]::GetInvalidFileNameChars())
    $CleanName = $CleanName.Split($InvalidChars) -Join '_'
    Return $CleanName
}
