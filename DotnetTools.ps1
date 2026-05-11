function Publish-BatchProgram {
    param(
        [string]$OutputBase = "D:/ISEM.ai/Releases/General/Batch Program/Batch Program 1.1.9.4-PR3115_mysql",
        [string[]]$Projects = @(
            "AgentDJWLUploadAuto",
            "AgentTxnMonitoring",
            "AgentRiskODD",
            "AgentRiskHistory",
            "AgentWLDeltaCustomerScreening",
            "AgentWLDeltaWatchlistScreening"
        ),
		[array]$FilesToDelete = @()
    )
	Write-Host "Checking if OutputBase exists..." -ForegroundColor Cyan
	
	if (Test-Path -path "$OutputBase") {
		Write-Host "$OutputBase already exists." -ForegroundColor Yellow
		Remove-Item -Path "$OutputBase" -Recurse -Force -Confirm
	}

    foreach ($project in $Projects) {
        Write-Host "Publishing $project..." -ForegroundColor Cyan
        dotnet publish ".\$project\$project.csproj" -c Release --output "$OutputBase/$project"

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to publish $project. Aborting."
            return
        }
    }
	
	foreach ($project in $Projects) {
		Write-Host "Moving $project to $OutputBase\BatchProgram..." -ForegroundColor Cyan
		
		robocopy "$OutputBase\$project" "$OutputBase\BatchProgram" /E

		if ($LASTEXITCODE -ge 8) {
			Write-Error "Failed to move $project. Aborting."
			return
		}

		Remove-Item -Path "$OutputBase\$project" -Recurse -Force
	}

    Write-Host "Copying Scripts and release notes..." -ForegroundColor Cyan
    robocopy .\Scripts "$OutputBase\Scripts" /E
	Copy-Item -Path ".\release-note.txt" -Destination "$OutputBase"
	
	if ($FilesToDelete.Count -gt 0) {
		Write-Host "Starting file cleanup process..."
		$FilesToDelete | ForEach-Object {
			Get-ChildItem -Path $OutputBase -Recurse -Filter $_ | Remove-Item -Force
		}
	}

    Write-Host "Done! Published to: $OutputBase" -ForegroundColor Green
}