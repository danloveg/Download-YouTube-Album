Function AutoTagAlbum($albumDirectory) {
    beet import $albumDirectory
}

Function GetBeetConfigPath() {
    return [String] (beet config -p)
}

Function GetBeetsPlugFolder() {
    return Join-Path -Path $PSScriptRoot -ChildPath "beetsplug"
}


Function GetConfigTemplatePath() {
    $TemplateDir = Join-Path -Path $PSScriptRoot -ChildPath 'templates'
    return (Join-Path -Path $TemplateDir -ChildPath 'config.yaml')
}

Function GetDefaultBeetConfig($newBeetsDirectory) {
    <#
    Creates a beet config to reflect what the YouTube downloader requires. The
    main purpose is to tell beets to use the custom plugins written for it.
    #>
    If ([String]::IsNullOrEmpty($newBeetsDirectory)) {
        Throw [System.ArgumentException]::New('beets directory cannot be null or empty.')
    }

    $ConfigFile = GetConfigTemplatePath

    If (-Not(Test-Path $ConfigFile -PathType Leaf -ErrorAction SilentlyContinue)) {
        $Msg = 'config.yaml template was moved or deleted!'
        Throw [System.IO.FileNotFoundException]::New($Msg)
    }

    $ConfigTemplate = (Get-Content $ConfigFile -Raw)

    # Template variables - DO NOT REMOVE!
    $BeetsDirectory = $newBeetsDirectory
    $BeetsPluginpath = GetBeetsPlugFolder

    # Fill variables in template
    $ConfigContents = $ExecutionContext.InvokeCommand.ExpandString($ConfigTemplate)

    return $ConfigContents
}

Function UpdateBeetConfig([String] $newBeetsDirectory) {
    <#
    Overwrites beet's configuration file to activate the custom plugins. Returns
    the beets configuration file location and the original contents in a hash
    table.
    #>

    If ([String]::IsNullOrEmpty($newBeetsDirectory)) {
        Throw [System.ArgumentException]::new('Directory cannot be null or empty.')
    }

    $configLocation = GetBeetConfigPath
    $origContents = @()

    If (-Not (Test-Path -Path $configLocation -PathType Leaf)) {
        Write-Host ("Creating a new beets config file.")
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

Function RestoreBeetConfig([Hashtable] $configInfo) {
    If (-Not $configInfo.Contains('originalContents')) {
        Throw [System.Collections.Generic.KeyNotFoundException]::new('Could not find "originalContents" key in collection')
    }
    ElseIf (-Not $configInfo.Contains('configLocation')) {
        Throw [System.Collections.Generic.KeyNotFoundException]::new('Could not find "configLocation" key in collection')
    }
    ElseIf (-Not (Test-Path -Path $configInfo['configLocation'] -ErrorAction SilentlyContinue)) {
        $Location = $configInfo['configLocation']
        Throw [System.IO.FileNotFoundException]::new("Configuration file `"$Location`" does not exist")
    }

    Write-Host 'Restoring your beet config.'
    $configInfo['originalContents'] | Out-File -FilePath $configInfo['configLocation']
}