#Requires -RunAsAdministrator
# $ErrorActionPreference = 'Stop'
# CCU.ps1 (Chocolatey Continuous Upgrader) Copyleft 2023 by Bill Curran AKA BCURRAN3
# LICENSE: GNU GPL v3 - https://www.gnu.org/licenses/gpl.html
# Open a GitHub issue at https://github.com/bcurran3/ChocolateyPackages/issues if you have suggestions for improvement.

param (
    [switch]$Foreground,
	[Alias("?")][switch]$Help,
	[switch]$DoNotNotify,
	[Alias("NotifyOnly")][switch]$OnlyNotify,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
	$WaitTime
 )

Write-Host "CCU.ps1 v0.1.0-alpha (2023/11/15) - (unofficial) Chocolatey Continuous Upgrader" -Foreground White
Write-Host "Copyleft 2023 Bill Curran (bcurran3@yahoo.com) - free for personal and commercial use`n" -Foreground White


if (!$Start -and !$Stop -and !$Status -and !$Help -and !$OnlyNotify -and !$Foreground -and !$DoNotNotify ) {
	Write-Host "  ** Please run 'CCU -?' or 'CCU -help' for help menu." -Foreground White
	return
}

if ( $Help ) {
	Write-Host "OPTIONS AND SWITCHES:" -Foreground Magenta
	Write-Host " -Start"
	Write-Host "    Start checking for and install upgrades."
	Write-Host " -Stop"
	Write-Host "    Stop checking for upgrades."
	Write-Host " -Status"
	Write-Host "    Show status of CCU background job."
	Write-Host " -DoNotNotify"
	Write-Host "    Don't send notifications about upgrades."
	Write-Host " -OnlyNotify"
	Write-Host "    Start checking for upgrades but do not install them."
	Write-Host " -Foreground"
    Write-Host "    Run in foreground instead of background."
	Write-Host " #"
	Write-Host "    Number of minutes to wait between checks (default 30)."
	Write-Host " -Help, -?"
	Write-Host "    This menu."
	Write-Host 
	Write-Host "EXAMPLE:" -Foreground Magenta
	Write-Host " CCU -Start 60`n"
	return
}

if ($Foreground) {$env:Notify=$False} else {$env:Notify=$True}
if ($OnlyNotify){$env:AutoUpgrade=$False;$env:Notify=$True} else {$env:AutoUpgrade=$True}
if ($DoNotNotify) {$env:Notify=$False} else {$env:Notify=$True}
if (Get-Module -ListAvailable -Name BurntToast) {$env:ToastAvailable=$True} else {$env:ToastAvailable=$False}
$env:WaitTime=$WaitTime
$toolsdir=(Split-Path -parent $MyInvocation.MyCommand.Definition)
$CheckJob=Get-Job | Where-Object {$_.Name -eq "CCU"}
$CheckForeground=Test-Path "$env:chocolateyToolsLocation\BCURRAN3\CCUprocesshandle.xml"

if ($Status){
	if ($CheckForeground){
	    Write-Host "  ** CCU foreground process is running!." -Foreground Yellow
	} else {
		Write-Host "  ** CCU foreground process is not running" -Foreground Yellow
	}
	if ($CheckJob){
		Write-Host "  ** CCU background job is running!`n" -Foreground Yellow
		Receive-Job -Name CCU
		return
		} else {
			Write-Host "  ** CCU background job is not running.`n" -Foreground Yellow
			return
		}
}

if ($Start -or $OnlyNotify) {
	if ($CheckJob){ 
	Write-Host "  ** CCU background job already running!" -Foreground Yellow
	return
	}
	if ($Foreground){
		$CCUProcess = Start-Process PowerShell -ArgumentList '$host.ui.RawUI.WindowTitle = “Chocolatey Continuous Updater”; Import-Module ./CCU.psm1; Write-Host "  ** Control-C to stop." -Foreground Yellow; for (;;) {keep_checking}' -WindowStyle Normal -WorkingDirectory "$toolsDir" -PassThru
		$CCUProcess | Export-Clixml -Path "$env:chocolateyToolsLocation\BCURRAN3\CCUprocesshandle.xml"
		return
		} else {
			Start-Job -Name CCU -InitializationScript { Import-Module S:\dev\GitHub\ChocolateyPackages\choco-continuous-upgrader\ccu.psm1 } {for (;;) {keep_checking}} | Out-Null
			Write-Host "  ** Started CCU background job." -Foreground Yellow
			if (!($OnlyNotify)) {Write-Host "  ** Automatic upgrades ENABLED" -Foreground Yellow} else {Write-Host "  ** Automatic upgrades are DISABLED." -Foreground Yellow}
			Write-Host "  ** Upgrades will be checked for every $WaitTime minutes." -Foreground Yellow
		}
		return
}

if ($Stop){
	if ($CheckForeground)
	{
		$CCUProcess = Import-Clixml -Path "$env:chocolateyToolsLocation\BCURRAN3\CCUprocesshandle.xml"
        $CCUProcess | Stop-Process
		Remove-Item "$env:chocolateyToolsLocation\BCURRAN3\CCUprocesshandle.xml"
		Write-Host "  ** STOPPED CCU foreground process." -Foreground Yellow
	} else {
		Write-Host "  ** CCU foreground process not running." -Foreground Yellow
	}
	if ($CheckJob){
		Stop-Job -Name CCU
	    Remove-Job -Name CCU
		Write-Host "  ** STOPPED CCU background job." -Foreground Yellow
		} else {
			Write-Host "  ** CCU background job not running.`n" -Foreground Yellow
			}
	return
}

# EXAMPLE: Remove-Item Function:send_msg

Write-Host "`nFound CCU.ps1 useful?" -ForegroundColor White
Write-Host "Buy me a beer at https://www.paypal.me/bcurran3donations" -ForegroundColor White
Write-Host "Become a patron at https://www.patreon.com/bcurran3" -ForegroundColor White
#Start-Sleep -s 10