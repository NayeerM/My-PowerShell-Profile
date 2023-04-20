

oh-my-posh init pwsh --config 'C:\Users\nayeer\AppData\Local\Programs\oh-my-posh\themes\m365princess.omp.json' | Invoke-Expression

# Import modules
 . Get-Location\Git.ps1

function ChangeBackend {
    Set-Location 'D:\ISEM10 v2\CORAL-iSEM-BE'
}

function ChangeFrontend{
    Set-Location 'D:\ISEM10 v2\CORAL iSEM10 v2'
}
