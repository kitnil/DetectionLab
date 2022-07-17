Write-Host Install Looking Glass Host
$url="https://looking-glass.io/artifact/B5/host"
(New-Object System.Net.WebClient).DownloadFile($url, "$env:TEMP\looking-glass.zip")
Expand-Archive -Path $env:TEMP\looking-glass.zip -DestinationPath $env:TEMP\looking-glass -Force
rm "$env:TEMP\looking-glass.zip"
. $env:TEMP\looking-glass\looking-glass-host-setup.exe /S
rm -recurse "$env:TEMP\looking-glass"
