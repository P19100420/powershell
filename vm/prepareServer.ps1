<#
Anlage neuer Server und löschen Bestandsserver.

Anlage in VMware über die Vmware PowerCLI und Anlage aller nötigen Sicherheitsgruppen, Lokaler Admins etc. nach einem gewissen Naming.
Löschen eines Servers in der Vmware, löschen des Computerkontos und löschen aller angelegten Gruppen/User.
Jeweils mit abfrage "Wollen Sie wirklich Gruppe X, GruppeY" "Wollen sie wirklich Computerkonto xy" usw. löschen?
#>

$parentOU = "OU=WEKO-Server,DC=weko,DC=com"
#$server = Read-Host "Names des Server eingeben"
#$newOU = Read-Host "OU des Servers eingeben. $parentOU als parent ist fest definiert"
$server = "srv-pstest"
$newOU = "pstest"
$subOU = "OU=" + $newOU + "," + $parentOU
$admGrp = "adm_" + $server

#create the AD OUs
$OUs = @("computer", "local-admins", "security-groups", "share", "user")

try {
    New-ADOrganizationalUnit $newOU -Path $parentOU 
}
catch [Microsoft.ActiveDirectory.Management.ADException] {
    Write-Host "OU existiert bereits, fahre dennoch fort. Eine Überprüfung des Ergebnis kann sinnvoll sein."
}
catch {
    Write-Error "Ein unbehandelter Fehler ist beim Anlegen der OU $newOU aufgetreten, beende Script. Es wurde noch nichts angelegt."
    Write-Error $error[0].Exception.GetType().FullName
    exit
}

foreach ($OU in $OUs) {
    try {
        New-ADOrganizationalUnit $OU -Path $subOU 
    }
    catch [Microsoft.ActiveDirectory.Management.ADException] {
        Write-Host "OU existiert bereits, fahre dennoch fort. Eine Überprüfung des Ergebnis kann sinnvoll sein."
    }
    catch {
        Write-Error "Ein unbehandelter Fehler ist beim Anlegen der OU $OU aufgetreten, beende Script. Bereits erstellte OUs, Gruppen und Accounts sollten entfernt werden."
        Write-Error $error[0].Exception.GetType().FullName
        exit
    }
}

#Computer Konto erstellen
$computerOU = "OU=computer," + $subOU
try {
    New-ADComputer -Name $server -SAMAccountName $server -Path $computerOU
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
    Write-Error "Fehler! $server existiert bereits, beende Script. Bereits erstellte OUs, Gruppen und Accounts sollten entfernt werden."
    #exit
}
catch {
    Write-Error "Ein unbehandelter Fehler ist beim Anlegen des Computerkontos $server aufgetreten, beende Script. Bereits erstellte OUs, Gruppen und Accounts sollten entfernt werden."
    Write-Error $error[0].Exception.GetType().FullName
    exit
}

#Local Admin Gruppe erstellen
$localAdminOU = "OU=local-admins," + $subOU
try {
    New-ADGroup -Name $admGrp -Path $localAdminOU -SamAccountName $admGrp -GroupCategory Security -GroupScope DomainLocal -Description "Sicherheitsgruppe für lokale Administratoren für $server."
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
    Write-Error "Fehler! $admGrp existiert bereits, beende Script. Bereits erstellte OUs, Gruppen und Accounts sollten entfernt werden."
    #exit
}
catch {
    Write-Error "Ein unbehandelter Fehler ist beim Anlegen der Sicherheitsgruppe $admGrp aufgetreten, beende Script. Bereits erstellte OUs, Gruppen und Accounts sollten entfernt werden."
    Write-Error $error[0].Exception.GetType().FullName
    exit
}

$admin4server = Read-Host "Soll ein admin4XXX User erstellt werden? Wenn ja, Name eingeben, wenn nein, Abfrage leer lassen"
if($admin4server) {
    $userOU = "OU=user," + $subOU
    Write-Host "Passwort bitte in KeePass erzeugen und speichern."
    $password = Read-Host -Prompt "Enter password" -AsSecureString 
    try {
        New-ADUser -SamAccountName $admin4server -UserPrincipalName $admin4server -Name $admin4server -Path $userOU -AccountPassword $password -ChangePasswordAtLogon $False -Enabled $True -AllowReversiblePasswordEncryption $false -PasswordNeverExpires $True
        Set-ADUser $admin4server -Description "Adminuser für $server."
        Add-ADGroupMember -Identity $admGrp -Members $admin4server
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
        Write-Error "Fehler! $admin4server existiert bereits, beende Script. Bereits erstellte OUs, Gruppen und Accounts sollten entfernt werden."
        exit
    }
    catch {
        Write-Error "Ein unbehandelter Fehler ist beim Anlegen des Accounts $admin4server aufgetreten, beende Script. Bereits erstellte OUs, Gruppen und Accounts sollten entfernt werden."
        Write-Error $error[0].Exception.GetType().FullName
        exit
    }
}