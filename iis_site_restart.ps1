<# set logfile name and path $Logfile and date format for filename, create dir if not exist #>
$todaysdate=Get-Date -Format "MM-dd-yyyy"
$logDir = "C:\LOGS"
if (! (Test-Path $logDir)) {
    New-Item -ItemType "Directory" -Path $logDir | Out-Null
}
$Logfile = Join-Path $logDir "$todaysdate_siteRestart.log"

<# function takes $Stamp and incoming string variable $LogString to create $LogMessage, then write it to $LogFile #>
function WriteLog
{
    Param ([string]$LogString)
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $LogMessage = "$Stamp $LogString" 
    Add-content -Path $LogFile -value $LogMessage
}

<# import module WebAdministration to work with iis #>
Import-Module WebAdministration

<# set domain for checking $Site, set iis site name $iisSite, set $applicationPoolName #>
<# all checking work goes on server with iis. in my case, $Site = $iisSite by win hosts file inside server #>
$Site = "http://test.com"
$iisSite = "test.com"
$applicationPoolName = "test_site.pool"

<# function to get $iisSite state by iis and write it in $iisSiteState and log #>
function IISSiteState
{
    Param ([string]$iisSiteState)
    Clear-Variable -name iisSiteState
    [string]$iisSiteState = (Get-WebsiteState -Name $iisSite).Value
    WriteLog "Site state in IIS: $iisSiteState"
}

<# function to get state of pool $applicationPoolName and write it in $PoolState and log #>
function PoolState
{
    Param ([string]$PoolState)
    Clear-Variable -name PoolState
    [string]$PoolState = (Get-WebAppPoolState -Name $applicationPoolName).Value
    WriteLog "Pool state in IIS: $PoolState"
}

<# cleaning vars and starting script #>
WriteLog "Starting script"
WriteLog "Ideal Status: 200-299"
$statuserr = "0"
$status = "0"

<# request status code $Site and write it in $status #>
$status = Invoke-WebRequest -Uri $Site -UseBasicParsing | Select-Object -Expand StatusCode

<# try request status code $Site if error and write it in $statuserr #>
try
{
    $Response = Invoke-WebRequest -Uri $Site
    $statuserr = $Response.StatusCode
} catch {
    $statuserr = $_.Exception.Response.StatusCode.value__
}

WriteLog "Site status: $status"
WriteLog "Site status if err: $statuserr"

<# comparing values $status and $statuserr with ideal, if both non equal ideal then site and poll will be restarted #>
if ((($status -lt 200) -AND ($status -ge 300)) -AND (($statuserr -lt 200) -AND ($statuserr -ge 300))){

    WriteLog "Site is down"
    WriteLog "Starting stopping site/pool function"
    IISSiteState
    PoolState

<# check site and pool state then stop them then check again #>
if($iisSiteState -ne "Stopped" -Or $PoolState -ne "Stopped") {
    Stop-WebSite -Name $iisSite
    Stop-WebAppPool -Name $applicationPoolName
    WriteLog "Stopping site and pool"
    }
    while ((Get-WebAppPoolState -Name $applicationPoolName).Value -ne "Stopped") {
        WriteLog "Waiting 1 sec while pool stopping..."
        Start-Sleep -s 1
    }
    IISSiteState
    PoolState

<# check site and pool state then start them then check again #>
    WriteLog "Starting enabling site/pool function"
    if($iisSiteState -ne "Started" -Or $PoolState -ne "Started") {
        WriteLog "Starting site and pool"
        Start-WebAppPool -Name $applicationPoolName
        Start-WebSite -Name $iisSite
        IISSiteState
        PoolState
        WriteLog "Ending script, site and pool restarted"
    }
}
else {
    WriteLog "Stopping script, everything ok"
}
