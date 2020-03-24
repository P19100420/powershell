$cred = Get-Credential #"Bitte berechtigte User UPN eingeben."
Connect-VIServer -Server $VIServer -Credential $cred

$server = Read-Host "Servername eingeben"
$state = (Get-VM -Name $server).PowerState
if($state -eq 'PoweredOn') {
    Stop-VM -VM $server -Confirm:$true
}
Remove-VM $server -DeletePermanently -Confirm:$true


Disconnect-VIServer -Server $VIServer -Force -Confirm