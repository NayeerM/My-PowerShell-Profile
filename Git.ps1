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

function Get-Branch-Description() {
  # Get the current branch name
  $current = git rev-parse --abbrev-ref HEAD
  $desc = git config branch.$current.description
  Write-Host "$current $($desc | Out-String )" -ForegroundColor Cyan
}

function New-BranchWithDescription {
  param (
    [Parameter(Mandatory = $true)]
    [string] $BranchName,
    [Parameter(Mandatory = $false)]
    [string] $Description
  )

  # Validate branch name
  if (!(Test-Path -Path "refs/heads/$BranchName")) {

    # Create the branch
    git checkout -b $BranchName

    # Add description if provided
    if ($Description) {
      git config branch.$BranchName.description $Description
      Write-Host "Branch '$BranchName' created with description."
    } else {
      Write-Host "Branch '$BranchName' created."
    }
  } else {
    Write-Warning "Branch '$BranchName' already exists."
  }
}

function StashLintRules {
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
        & git stash --include-untracked -m "Excluded Files" -- .eslintrc.js
    }
}
