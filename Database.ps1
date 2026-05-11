function Convert-TableToEFModel {
    param (
        [string] $connString,
        [string] $tableName
    )
  
    # Build connection string
    $connectionString = $connString
    try {
        # Connect to the database
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
  
        # Get table information
        $query = "SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tableName"
        $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
        $command.Parameters.AddWithValue("@tableName", $tableName)
        $reader = $command.ExecuteReader()
  
        # Loop through each column and build the model definition
        $model = ""
        while ($reader.Read()) {
            Write-Host $reader["COLUMN_NAME"]
            $dataType = $reader["DATA_TYPE"]
            $isNullable = $reader["IS_NULLABLE"] -eq "YES"
  
            # Map SQL data types to EF Core types (modify as needed)
            switch ($dataType) {
                "int" { $dataType = "int" }
                "varchar" { $dataType = "string" }
                "datetime" { $dataType = "DateTime" }
                "datetime2" { $dataType = "DateTime" }
                # Add more mappings for other data types
                default { $dataType = "object" }
            }
  
            Write-Host "public $dataType $reader['COLUMN_NAME'] { get; set; }" + "`n"
        }
  
        # Close resources
        $reader.Close()
        $command.Dispose()
        $connection.Close()
  
        # Return the generated model
        Write-Host $model
    }
    catch {
        Write-Error $_.Exception
        return ""
    }
}

function RestoreDBBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DBName,
        [Parameter(Mandatory = $true)]
        [string]$ContainerPath
    )
  
    # Error handling function
    function Write-ErrorAndReturn {
        param([string]$ErrorMessage)
        Write-Error $ErrorMessage
        return $false
    }
  
    # Split ContainerPath into container ID and path
    $containerInfo = $ContainerPath -split ':'
    if ($containerInfo.Length -ne 2) {
        return Write-ErrorAndReturn "ContainerPath must be in format 'containerId:path/to/folder'"
    }
    $containerId = $containerInfo[0]
    $containerBackupPath = $containerInfo[1]

    # Verify container exists and is running
    $containerExists = docker ps -q -f "name=$containerId"
    if (-not $containerExists) {
        return Write-ErrorAndReturn "Container $containerId does not exist or is not running"
    }

    # Replace with the appropriate values
    $serverName = "Nayeer-PC"
    $backupFolder = "D:\DatabaseBackup"
    $userName = "sa"
    $password = "Tess@1234#"
    $networkBackupPath = "\\192.168.2.70\isem10"

    # Find the latest backup file in the local folder
    $latestLocalBackup = Get-ChildItem -Path $backupFolder -Filter "*.bak" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1
  
    # Find the latest backup file in the network folder
    $latestNetworkBackup = Get-ChildItem -Path $networkBackupPath -Filter "*.bak" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

    if ($null -eq $latestLocalBackup -and $null -eq $latestNetworkBackup) {
        return Write-ErrorAndReturn "No backup files found in $backupFolder or $networkBackupPath"
    }

    # Compare the latest backups and copy if necessary
    if ($null -eq $latestLocalBackup -or ($null -ne $latestNetworkBackup -and $latestNetworkBackup.LastWriteTime -gt $latestLocalBackup.LastWriteTime)) {
        Write-Output "Copying latest backup from network share..."
      
        $source = $latestNetworkBackup.FullName
        $destination = Join-Path $backupFolder $latestNetworkBackup.Name
      
        try {
            # Start BITS transfer
            $job = Start-BitsTransfer -Source $source -Destination $destination -DisplayName "Backup Transfer" -Description "Transferring database backup" -Asynchronous
          
            # Monitor and display progress
            while (($job.JobState -eq "Transferring") -or ($job.JobState -eq "Connecting")) {
                $progress = [Math]::Round(($job.BytesTransferred / $job.BytesTotal) * 100, 2)
                Write-Progress -Activity "Transferring Backup" -Status "$progress% Complete" -PercentComplete $progress
                Start-Sleep -Seconds 1
            }

            # Check for completion or errors
            switch ($job.JobState) {
                "Transferred" {
                    Complete-BitsTransfer -BitsJob $job
                    Write-Output "Backup file transfer completed successfully."
                    $latestBackupFile = Get-Item $destination
                }
                "Error" {
                    $job | Format-List
                    return Write-ErrorAndReturn "An error occurred during file transfer."
                }
            }
        }
        catch {
            return Write-ErrorAndReturn "Failed to transfer backup file: $_"
        }
    }
    else {
        $latestBackupFile = $latestLocalBackup
    }

    # Copy the backup file to the Docker container
    $backupFileName = $latestBackupFile.Name
    $containerBackupFile = "$containerBackupPath/$backupFileName"
  
    Write-Output "Copying backup file to Docker container..."
    try {
        docker cp $latestBackupFile.FullName "${containerId}:${containerBackupFile}"
    }
    catch {
        return Write-ErrorAndReturn "Failed to copy backup file to container: $_"
    }

    # Restore the database inside the container
    $query = @"
IF EXISTS (SELECT * FROM sys.databases WHERE name = '$DBName')
BEGIN
  ALTER DATABASE [$DBName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END
GO
RESTORE DATABASE [$DBName]
FROM DISK = N'$containerBackupFile'
WITH REPLACE,
  MOVE N'ISEM_BANK_PANDA' TO N'/var/opt/mssql/data/$DBName.mdf',
  MOVE N'ISEM_BANK_PANDA_log' TO N'/var/opt/mssql/data/$DBName_log.ldf',
  NOUNLOAD,
  STATS = 5
GO
ALTER DATABASE [$DBName] SET MULTI_USER
GO
"@

    # Execute the restore command inside the container
    $queryFile = [System.IO.Path]::GetTempFileName()
    $query | Out-File -FilePath $queryFile -Encoding UTF8

    Write-Output "Restoring database inside container..."
    try {
        $restoreOutput = docker exec $containerId /opt/mssql-tools18/bin/sqlcmd -S localhost -U $userName -P $password -C -Q $query
        Write-Output $restoreOutput
    }
    catch {
        Remove-Item $queryFile
        return Write-ErrorAndReturn "Failed to restore database inside container: $_"
    }

    # Cleanup
    Remove-Item $queryFile

    # Delete the backup file from the container
    Write-Output "Cleaning up: Removing backup file from container..."
    try {
        docker exec $containerId rm $containerBackupFile
        Write-Output "Backup file removed from container successfully."
    }
    catch {
        Write-Warning "Failed to remove backup file from container: $_"
    }

    Write-Output "Database $DBName has been restored successfully inside the container."
    return $true
}