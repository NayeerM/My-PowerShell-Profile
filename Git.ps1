function Stash {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("pop", "push")]
        [string]$Config
    )

    if ($Config -eq "pop") {
        $stashList = git stash list
        $stashToApply = $stashList | Select-String "Excluded Files"
        $stashIndex = $stashToApply.Line.Split(':')[0]

        git stash pop $stashIndex
    }
    elseif ($Config -eq "push") {
        & git stash push -m "Excluded Files" -- CORAL-iSEM-v10-BE/appsettings.json
    }
}