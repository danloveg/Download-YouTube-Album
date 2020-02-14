
. $PSScriptRoot\Exceptions.ps1

Function VerifyToolsInstalled {
    If (-Not(Get-Command python -ErrorAction SilentlyContinue)) {
        Throw ([DependencyException]::new("Could not find Python installation. Go to python.org to install."))
    }
    If (-Not(Get-Command ffmpeg -ErrorAction SilentlyContinue) -And -Not(Get-Command avconv -ErrorAction SilentlyContinue)) {
        Throw ([DependencyException]::new("Could not find FFmpeg or avconv installation, please install either of these tools."))
    }
    If (-Not(Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
        Write-Warning "Could not find youtube-dl, attemtpting to install with pip."

        Write-Host "pip install youtube-dl" -ForegroundColor Green
        pip install youtube-dl

        If (-Not(Get-Command youtube-dl -ErrorAction SilentlyContinue)) {
            Throw ([DependencyException]::new("Something went wrong installing youtube-dl. See above output"))
        }
    }
    If (-Not(Get-Command beet -ErrorAction SilentlyContinue)) {
        Write-Warning "Could not find beets, attempting to install with pip."

        Write-Host "pip install beets" -ForegroundColor Green
        pip install beets
        pip install requests

        If (-Not(Get-Command beet -ErrorAction SilentlyContinue)) {
            Throw ([DependencyException]::new("Something went wrong installing beets. See above output."))
        }
    }
}