# HPSIA v3
# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # If not running as admin, restart the script with elevated privileges
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath'`""
    exit
}

# Define the URL for HP Image Assistant download
$url = 'https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.1.exe'

# Set the output path for the downloaded file
$output = Join-Path $PWD 'HPImageAssistant.exe'

# Download HP Image Assistant
Write-Host "Downloading HP Image Assistant..."
(New-Object System.Net.WebClient).DownloadFile($url, $output)

# First, analyze system for available updates
Write-Host "Analyzing system for available updates..."
Start-Process -FilePath $output -ArgumentList "/Operation:Analyze /Selection:Critical,UpdateRecommended /Category:BIOS,Drivers,Software /Silent /SoftpaqDownloadFolder:`"$PWD\HPIA_Softpaqs`" /ReportFolder:`"$PWD\HPIA_Reports`"" -Wait

# Check if analysis report exists and display available updates
$latestReport = Get-ChildItem -Path "$PWD\HPIA_Reports" -Filter "HPImageAssistant.html" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($latestReport) {
    Write-Host "`nAvailable updates found in report: $($latestReport.FullName)"
    # You could parse the HTML report here to display specific updates
    # For now, we'll just notify the user to check the report
    Write-Host "Please check the HTML report for detailed update information."
} else {
    Write-Host "No analysis report found."
}

# Prompt user to continue with installation
$continue = Read-Host "`nDo you want to proceed with installing the updates? (Y/N)"

if ($continue -eq 'Y' -or $continue -eq 'y') {
    # Proceed with installation
    Write-Host "`nInstalling updates..."
    Start-Process -FilePath $output -ArgumentList "/Operation:Deploy /Action:Install /Selection:Critical,UpdateRecommended /Category:BIOS,Drivers,Software /Silent /SoftpaqDownloadFolder:`"$PWD\HPIA_Softpaqs`" /ReportFolder:`"$PWD\HPIA_Reports`" /AutoCleanup" -Wait

    # Prompt user for system restart
    $reboot = Read-Host "`nUpdates have been installed. Do you want to restart your computer now? (Y/N)"

    # Handle restart decision
    if ($reboot -eq 'Y' -or $reboot -eq 'y') {
        # Restart computer if user confirms
        Restart-Computer -Force
    } else {
        # Display reminder message if user declines restart
        Write-Host "Please remember to restart your computer to complete the update process."
    }
} else {
    Write-Host "Update installation cancelled by user."
}

# Clean up downloaded file
Remove-Item $output -ErrorAction SilentlyContinue
