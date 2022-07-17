# On my test box I ran through the installer. When asked if I would like to
# install I checkmarked "Always trust software", and clicked install.
#
# Once the install was done I ran certmgr.msc. Under certmgr.msc I navigated
# to Trusted Publishers>Certificates>"name of new cert". Right click the cert
# and export it. I left all questions at default.
#
# From there I added the below into my command line. Followed by my installer.

Write-Host Install virtio

$url="https://iso.wugi.info/redhat.cer"
(New-Object System.Net.WebClient).DownloadFile($url, "$env:TEMP\redhat.cer")
certutil.exe -addstore "TrustedPublisher" "$env:TEMP\redhat.cer"
rm "$env:TEMP\redhat.cer"

. E:\virtio-win-guest-tools.exe /quiet /passive
