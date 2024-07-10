function Convert-TableToEFModel {
    param (
      [string] $server,
      [string] $database,
      [string] $username,
      [string] $password,
      [string] $tableName
    )
  
    # Build connection string
    $connectionString = "Server=$server;Database=$database;Trusted_Connection=false;User Id=$username;Password=$password;"
  
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
      [Parameter(Mandatory=$true)]
      [string]$DBName
  )

  # Replace with the appropriate values
  $serverName = "Nayeer-PC"
  $backupFolder = "D:\DatabaseBackup"
  $userName = "sa"
  $password = "123"
  $dataFilePath = "D:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA"
  $networkBackupPath = "\\192.168.2.70\isem10"

  # Find the latest backup file in the local folder
  $latestLocalBackup = Get-ChildItem -Path $backupFolder -Filter "*.bak" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

  # Find the latest backup file in the network folder
  $latestNetworkBackup = Get-ChildItem -Path $networkBackupPath -Filter "*.bak" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

  if ($null -eq $latestLocalBackup -and $null -eq $latestNetworkBackup) {
      Write-Error "No backup files found in $backupFolder or $networkBackupPath"
      return
  }

  # Compare the latest backups and copy if necessary
  if ($null -eq $latestLocalBackup -or ($null -ne $latestNetworkBackup -and $latestNetworkBackup.LastWriteTime -gt $latestLocalBackup.LastWriteTime)) {
      Write-Output "Copying latest backup from network share..."
      Copy-Item -Path $latestNetworkBackup.FullName -Destination $backupFolder -Force
      $latestBackupFile = Get-ChildItem -Path $backupFolder -Filter "*.bak" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  } else {
      $latestBackupFile = $latestLocalBackup
  }

  # Restore the database
  $dataFile = Join-Path $dataFilePath "$DBName.mdf"
  $logFile = Join-Path $dataFilePath "$DBName_log.ldf"
  $backupFile = $latestBackupFile.FullName

  $query = @"
IF EXISTS (SELECT * FROM sys.databases WHERE name = '$DBName')
BEGIN
ALTER DATABASE [$DBName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END
GO

RESTORE DATABASE [$DBName]
FROM DISK = N'$backupFile'
WITH REPLACE,
  MOVE N'ISEM_BANK_PANDA' TO N'$dataFile',
  MOVE N'ISEM_BANK_PANDA_log' TO N'$logFile',
  NOUNLOAD,
  STATS = 5
GO

ALTER DATABASE [$DBName] SET MULTI_USER
GO
"@

  & sqlcmd -S $serverName -U $userName -P $password -Q $query

  Write-Output "Database $DBName has been restored from $backupFile successfully."
}
