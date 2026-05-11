function Stash {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("pop", "push")]
        [string]$Config,

        [Parameter(Mandatory=$false, Position=1, ValueFromRemainingArguments=$true)]
        [string[]]$Files
    )

    if ($Config -eq "pop") {
        if ($Files.Count -eq 0) {
            Write-Host "Please specify files to pop from the stash."
            return
        }

        $fileList = $Files -join ", "
        $stashList = git stash list
        $stashToApply = $stashList | Select-String "Stashed files: $fileList"

        if ($stashToApply) {
            $stashIndex = $stashToApply[0].Line.Split(':')[0]
            git stash pop $stashIndex
            Write-Host "Popped stash: $($stashToApply[0].Line)"
        } else {
            Write-Host "No stash found with the specified files: $fileList"
        }
    }
    elseif ($Config -eq "push") {
        if ($Files.Count -eq 0) {
            Write-Host "No files specified for stashing."
            return
        }

        $fileList = $Files -join ", "
        $stashMessage = "Stashed files: $fileList"
        $stashCommand = "git stash push --include-untracked -m `"$stashMessage`" -- $($Files -join ' ')"
        Invoke-Expression $stashCommand
        Write-Host "Stashed files: $fileList"
    }
}