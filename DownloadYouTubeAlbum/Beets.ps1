Function AutoTagAlbum($albumDirectory) {
    beet import $albumDirectory
}

Function GetBeetsPlugFolder() {
    return Join-Path -Path $PSScriptRoot -ChildPath "beetsplug"
}

Function GetDefaultBeetConfig($newBeetsDirectory) {
    <#
    Creates a beet config to reflect what the YouTube downloader requires. The
    main purpose is to tell beets to use the custom plugins written for it.
    #>
    $beetsPlugFolder = GetBeetsPlugFolder

    return @(
        "directory: $($beetsDirectory)",
        "import:",
        "    move: yes",
        "match:",
        "    strong_rec_thresh: 0.10", # Automatically accept over 90% similar
        "    max_rec:",
        "        missing_tracks: strong", # Don't worry so much about missing tracks
        "",
        "pluginpath: $($beetsPlugFolder)",
        "plugins: fromdirname fromyoutubetitle fetchart embedart zero",
        "embedart:",
        "    remove_art_file: yes",
        "fetchart:",
        "    maxwidth: 512",
        "zero:",
        "    fields: day month genre"
    )
}

Function UpdateBeetConfig($newBeetsDirectory) {
    <#
    Overwrites beet's configuration file to activate the custom plugins. Returns
    the beets configuration file location and the original contents in a hash
    table.
    #>
    $configLocation = [String](beet config -p)
    $origContents = @()

    If (-Not (Test-Path -Path $configLocation -PathType Leaf)) {
        Write-Host ("Creating a new beet default config file.")
        New-Item -ItemType File -Path $configLocation | Out-Null
    }
    Else {
        Write-Host ("Overwriting beet config, to be restored after processing.")
        $origContents = (Get-Content $configLocation)
    }

    GetDefaultBeetConfig $newBeetsDirectory | Out-File $configLocation

    $configInfo = @{}
    $configInfo.Add("configLocation", $configLocation)
    $configInfo.Add("originalContents", $origContents)
    return $configInfo
}

Function RestoreBeetConfig($configInfo) {
    Write-Host "Restoring your beet config."
    $configInfo["originalContents"] | Out-File $configInfo["configLocation"]
}