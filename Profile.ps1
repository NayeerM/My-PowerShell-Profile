

oh-my-posh init pwsh --config 'C:\Users\nayeer\AppData\Local\Programs\oh-my-posh\themes\m365princess.omp.json' | Invoke-Expression
# Import modules
 . 'D:\MyPowerShellProfile\Git.ps1'

# PSReadline Settings
Set-PSReadlineOption -TokenKind Command -ForegroundColor Green
Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineOption -EditMode Windows

function Set-Folder {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("f", "b")]
        [string]$Target
    )
    
    if ($Target -eq "f") {
        Set-Location 'D:\ISEM10 v2\CORAL iSEM10 v2'
    }
    elseif ($Target -eq "b") {
        Set-Location 'D:\ISEM10 v2\CORAL-iSEM-BE'
    }
}

function Touch {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        New-Item $Path -ItemType File
    }
    else {
        (Get-ChildItem $Path).LastWriteTime = Get-Date
    }
}

