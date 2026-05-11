oh-my-posh init pwsh --config 'C:\Users\nayeer\AppData\Local\Programs\oh-my-posh\themes\powerlevel10k_rainbow.omp.json' | Invoke-Expression
# Import modules
 . 'D:\MyPowerShellProfile\Git.ps1'
 . 'D:\MyPowerShellProfile\Database.ps1'
 . 'D:\MyPowerShellProfile\DotnetTools.ps1'

# Import Terminal Icons
Import-Module -Name Terminal-Icons
Import-Module posh-docker
Import-Module PSFzf

# Find out if the current user identity is elevated (has admin rights)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Invoke-Expression (& { (& "C:\Users\nayeer\scoop\apps\zoxide\current\zoxide.exe" init powershell | Out-String) })

# PSReadline Settings
Set-PSReadlineOption -EditMode Windows
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -Colors @{
    Command = [ConsoleColor]::Green
    Parameter = [ConsoleColor]::Cyan
    String = [ConsoleColor]::Yellow
    Comment = [ConsoleColor]::DarkGray
}

# PSFzf settings
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

function Set-Folder {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("f", "b", "batch", "logstash")]
        [string]$Target
    )
    
    if ($Target -eq "f") {
        Set-Location 'D:\ISEM10 v2\CORAL iSEM10 v2'
    }
    elseif ($Target -eq "b") {
        Set-Location 'D:\ISEM10 v2\CORAL-iSEM-BE'
    }
	elseif ($Target -eq "batch") {
        Set-Location 'D:\ISEM10 v2\ISEM-EOD-BATCH-TEST'
    }
    elseif ($Target -eq "logstash") {
        Set-Location 'D:\ISEM10 v2\ES_API\elasticsearch-8.5.1\logstash-7.17.1'
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


# If so and the current host is a command line, then change to red color 
# as warning to user that they are operating in an elevated context
# Useful shortcuts for traversing directories
function cd...  { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }

# Compute file hashes - useful for checking successful downloads 
function md5    { Get-FileHash -Algorithm MD5 $args }
function sha1   { Get-FileHash -Algorithm SHA1 $args }
function sha256 { Get-FileHash -Algorithm SHA256 $args }

# Quick shortcut to start notepad
function n      { notepad $args }

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command
# with elevated rights. 
Set-Alias -Name su -Value admin
Set-Alias -Name sudo -Value admin


function ll { Get-ChildItem -Path $pwd -File }
function g { Set-Location $HOME\Documents\Github }
function gcom
{
	git add .
	git commit -m "$args"
}
function lazyg
{
	git add .
	git commit -m "$args"
	git push
}
Function Get-PubIP {
 (Invoke-WebRequest http://ifconfig.me/ip ).Content
}
function uptime {
        #Windows Powershell    
        Get-WmiObject win32_operatingsystem | Select-Object csname, @{LABEL='LastBootUpTime';
        EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}

        #Powershell Core / Powershell 7+ (Uncomment the below section and comment out the above portion)

        <#
        $bootUpTime = Get-WmiObject win32_operatingsystem | Select-Object lastbootuptime
        $plusMinus = $bootUpTime.lastbootuptime.SubString(21,1)
        $plusMinusMinutes = $bootUpTime.lastbootuptime.SubString(22, 3)
        $hourOffset = [int]$plusMinusMinutes/60
        $minuteOffset = 00
        if ($hourOffset -contains '.') { $minuteOffset = [int](60*[decimal]('.' + $hourOffset.ToString().Split('.')[1]))}       
          if ([int]$hourOffset -lt 10 ) { $hourOffset = "0" + $hourOffset + $minuteOffset.ToString().PadLeft(2,'0') } else { $hourOffset = $hourOffset + $minuteOffset.ToString().PadLeft(2,'0') }
        $leftSplit = $bootUpTime.lastbootuptime.Split($plusMinus)[0]
        $upSince = [datetime]::ParseExact(($leftSplit + $plusMinus + $hourOffset), 'yyyyMMddHHmmss.ffffffzzz', $null)
        Get-WmiObject win32_operatingsystem | Select-Object @{LABEL='Machine Name'; EXPRESSION={$_.csname}}, @{LABEL='Last Boot Up Time'; EXPRESSION={$upsince}}
        #>


        #Works for Both (Just outputs the DateTime instead of that and the machine name)
        # net statistics workstation | Select-String "since" | foreach-object {$_.ToString().Replace('Statistics since ', '')}
        
}
function reload-profile {
        & $profile
}
function find-file($name) {
        Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
                $place_path = $_.directory
                Write-Output "${place_path}\${_}"
        }
}
function unzip ($file) {
        Write-Output("Extracting", $file, "to", $pwd)
	$fullFile = Get-ChildItem -Path $pwd -Filter .\cove.zip | ForEach-Object{$_.FullName}
        Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function grep($regex, $dir) {
        if ( $dir ) {
                Get-ChildItem $dir | select-string $regex
                return
        }
        $input | select-string $regex
}
function touch($file) {
        "" | Out-File $file -Encoding ASCII
}
function df {
        get-volume
}
function sed($file, $find, $replace){
        (Get-Content $file).replace("$find", $replace) | Set-Content $file
}
function which($name) {
        Get-Command $name | Select-Object -ExpandProperty Definition
}
function export($name, $value) {
        set-item -force -path "env:$name" -value $value;
}
function pkill($name) {
        Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}
function pgrep($name) {
        Get-Process $name
}

function goodnight(){
    shutdown /s /t 0
}

function hg($searchTerm) {
    Get-Content (Get-PSReadLineOption).HistorySavePath | Where-Object { $_ -like "*$searchTerm*" }
}
