#$computer = Read-Host "Servername eingeben"
$computer = "srv-pstest"
$domainGrp = "weko\adm_" + $computer

#$cred = Get-Credential
$Session = New-PSSession -ComputerName $computer -Credential $cred
$Command = {param($domainGrp);  Add-LocalGroupMember -Group "Administrators" -Member $domainGrp}
Invoke-Command -Session $Session -ScriptBlock $Command -ArgumentList $domainGrp