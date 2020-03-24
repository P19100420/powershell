$cred = Get-Credential #"Bitte berechtigte User UPN eingeben."
Connect-VIServer -Server $VIServer -Credential $cred

#$spec = "w2016x64"
$spec = Read-Host "OSCustomizationSpec eingeben"
#$template = "w2k16-en"

$template = Read-Host "VMTemplate eingeben"
#$server = "srv-pstest"
$server = Read-Host "Servername eingeben"

$vmHost = Read-Host "VMHost eingeben"

$datastore = Read-Host "Datastore eingeben"

$OSSpec = Get-OSCustomizationSpec -Name $spec
$VMTemplate = Get-Template -Name $template
New-VM -Name $server -Template $VMTemplate -OSCustomizationSpec $OSSpec -VMHost $vmHost -Datastore $datastore
Start-VM -VM $server
Disconnect-VIServer -Server $VIServer -Force -Confirm