# Demander à l'utilisateur d'entrer le chemin du répertoire à surveiller
$CheminRepertoire = Read-Host -Prompt "Entrez le chemin du répertoire à surveiller"

# Demander à l'utilisateur d'entrer le chemin du fichier journal
$CheminJournal = Read-Host -Prompt "Entrez le chemin du fichier journal"

# Demander à l'utilisateur d'entrer la durée de rétention des fichiers en jours
$DureeRetention = Read-Host -Prompt "Entrez la durée de rétention des fichiers en jours"

# Demander à l'utilisateur d'entrer le seuil de remplissage du disque à partir duquel la suppression doit être déclenchée
$SeuilRemplissageDisque = Read-Host -Prompt "Entrez le seuil de remplissage du disque à partir duquel la suppression doit être déclenchée"

# Espace de disque disponible
$EspaceDisque = ((Get-PSDrive -Name C).Used / ((Get-PSDrive -Name C).Used + (Get-PSDrive -Name C).Free)) * 100
Write-Host "Espace disque disponible : $EspaceDisque%"

# Fonction Delete-Files pour la suppresion des fichiers selon les paramètres données
function Delete-Files {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$CheminRepertoire,

        [Parameter(Mandatory=$true)]
        [int]$DureeRetention,

        [Parameter(Mandatory=$true)]
        [int]$SeuilRemplissageDisque
    )

    # Comparaison du seuil de remplissage et de l'espace de disque disponible
    if ($EspaceDisque -ge $SeuilRemplissageDisque) {
        # Suppression des fichiers enregistrés avec une durée au dela de la durée de retention donnée
        Get-ChildItem -Path $CheminRepertoire -File -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DureeRetention) } | Remove-Item -Force
        Write-Host "Opération de suppression terminée."
    } else {
        Write-Host "L'espace disque est en dessous du seuil de remplissage. Aucune suppression nécessaire."
    }
}

# Fonction Log-FileDeletionActivity pour enregistrer l'action de suppression
function Log-FileDeletionActivity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogMessage
    )

    $DateHeure = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $CheminJournal -Value "$DateHeure - $LogMessage"
}

# Appeler la fonction Delete-Files pour la suppresion des fichiers
Delete-Files -CheminRepertoire $CheminRepertoire -DureeRetention $DureeRetention -SeuilRemplissageDisque $SeuilRemplissageDisque

# Appeler la fonction Log-FileDeletionActivity pour enregistrer l'action de suppression
if ($EspaceDisque -ge $SeuilRemplissageDisque) {
    Log-FileDeletionActivity -LogMessage "Suppression des fichiers exécutée. Espace disque disponible : $EspaceDisque%"
} else {
    Log-FileDeletionActivity -LogMessage "Aucune suppression nécessaire. Espace disque : $EspaceDisque%"
}
