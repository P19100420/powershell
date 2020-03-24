$srv = Read-Host "Name des zu löschenden Server eingeben"
$computerOU = (Get-ADComputer $srv -Properties distinguishedname,cn | Select-Object @{n='ParentContainer';e={$_.distinguishedname -replace '^.+?,(CN|OU.+)','$1'}}).ParentContainer
$ouToDelete = $computerOU.Replace('OU=computer,','')

$correct = Read-Host "Objekte in OU $ouToDelete und OU selbst werden gelöscht. Ist das korrekt? (y/n)"
if($correct -eq 'y') {
    Write-Host "Fahre mit dem Löschen fort."
} elseif($correct -eq 'n') {
    $parentOU = "OU=WEKO-Server,DC=weko,DC=com"
    $newOU = Read-Host "OU des Servers eingeben, der gelöscht werden soll. $parentOU als parent ist fest definiert."
    $ouToDelete = "OU=" + $newOU + "," + $parentOU
} else {
    Write-Host "Kann Eingabe nicht verarbeiten, beende Script ohne Ausführung."
    exit
}
$adObjects = Get-ADObject -SearchBase $ouToDelete -Filter 'ObjectClass -ne "organizationalUnit"'
foreach($adObject in $adObjects) {
    try {
        Remove-ADObject -Identity $adObject -Confirm:$true
    }
    catch {
        Write-Host "Error! Bei $adObject"
        Write-Error $error[0].Exception.GetType().FullName
    }
}

$adObjects = Get-ADObject -SearchBase $ouToDelete -Filter 'ObjectClass -ne "organizationalUnit"'
#Test, ob die OU bis auf andere OUs leer ist. Falls ja, löschen.
if(!($adObjects)) {
    try {
        Set-ADOrganizationalUnit $ouToDelete -ProtectedFromAccidentalDeletion $false
        Remove-ADOrganizationalUnit -Identity $ouToDelete -Recursive -Confirm:$true
    }
    catch {
        Write-Host "Error! Beim löschen der OUs."
        Write-Error $error[0].Exception.GetType().FullName
    }
}