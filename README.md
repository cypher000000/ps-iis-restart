# Powershell script to restart IIS pool and site with log
Restart site and pool in IIS if site doesn't respond http code between 200-299 and log every step in file.

This code was written many years ago for a specific problem in specific stack in accordance technical requirements.
This code will work on Windows Server 2008r2/2012 with IIS6/7.

## How to make this work
- Download script.
- Create and setup task in task scheduler. by default task should run in task scheduler once in 5 min.
- Specify important attributes in task scheduler:
  - Task To Run х64: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
  - Arguments: -noprofile -ExecutionPolicy Bypass -File "C:\path\to\script.ps1"
  - Run As User: Local System (or use your service user for this task)
  - Run whether user is logged on or not: Yes


## Setup script
- By default logs will be in C:\LOGS\date_siteRestart.log, you can change it in $logDir and $Logfile variables.
- Setup variables before runinng script:
  - $Site = full site domain and protocol like "http://test.com"
  - $iisSite = site name in IIS like "test.com"
  - $applicationPoolName = pool with site name in IIS like "test_site.pool"
