# PowerShell script to split large CSV file into chunks
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [int]$ChunkSize = 100000,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = ".\chunks"
)

# Create output directory if it doesn't exist
if (!(Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force
}

Write-Host "Starting to split $InputFile into chunks of $ChunkSize rows..."
Write-Host "Output directory: $OutputDirectory"

# Read the header line first
$header = Get-Content $InputFile -First 1
Write-Host "Header: $header"

# Initialize variables
$chunkNumber = 1
$lineCount = 0
$currentChunk = @()
$currentChunk += $header  # Add header to first chunk

# Process the file line by line (skip header)
Get-Content $InputFile | Select-Object -Skip 1 | ForEach-Object {
    $currentChunk += $_
    $lineCount++
    
    # When chunk size is reached, write to file
    if ($lineCount -eq $ChunkSize) {
        $outputFile = Join-Path $OutputDirectory "customer_data_chunk_$('{0:D3}' -f $chunkNumber).csv"
        $currentChunk | Out-File -FilePath $outputFile -Encoding UTF8
        Write-Host "Created chunk $chunkNumber with $lineCount rows: $outputFile"
        
        # Reset for next chunk
        $chunkNumber++
        $lineCount = 0
        $currentChunk = @()
        $currentChunk += $header  # Add header to each chunk
    }
}

# Write remaining lines if any
if ($lineCount -gt 0) {
    $outputFile = Join-Path $OutputDirectory "customer_data_chunk_$('{0:D3}' -f $chunkNumber).csv"
    $currentChunk | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "Created final chunk $chunkNumber with $lineCount rows: $outputFile"
}

Write-Host "Splitting completed! Created $chunkNumber chunk files."
Write-Host "Total rows processed: $((($chunkNumber - 1) * $ChunkSize) + $lineCount)"