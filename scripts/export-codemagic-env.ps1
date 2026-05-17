param(
    [string]$ApiKey = "PASTE_BACKEND_API_SECRET_KEY_HERE"
)

$ErrorActionPreference = "Stop"

function Convert-FileToBase64 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label introuvable: $Path"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    return [Convert]::ToBase64String([IO.File]::ReadAllBytes($resolvedPath))
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..")).Path

$iosPlistPath = Join-Path $projectRoot "ios\Runner\GoogleService-Info.plist"
$androidJsonPath = Join-Path $projectRoot "android\app\google-services.json"
$outputPath = Join-Path $projectRoot "codemagic-secrets.local.env"

$iosBase64 = Convert-FileToBase64 -Path $iosPlistPath -Label "GoogleService-Info.plist iOS"
$androidBase64 = Convert-FileToBase64 -Path $androidJsonPath -Label "google-services.json Android"

$lines = @(
    "# Fichier genere localement pour Codemagic. NE PAS COMMIT.",
    "# Dans Codemagic, cree le groupe de variables: itga_mobile",
    "# Ajoute chaque variable ci-dessous en mode Secure/Secret.",
    "",
    "ITGA_API_KEY=$ApiKey",
    "FIREBASE_IOS_PLIST_B64=$iosBase64",
    "FIREBASE_ANDROID_JSON_B64=$androidBase64"
)

Set-Content -LiteralPath $outputPath -Value $lines -Encoding ASCII

Write-Host ""
Write-Host "OK: fichier genere." -ForegroundColor Green
Write-Host $outputPath
Write-Host ""
Write-Host "Prochaine action:" -ForegroundColor Cyan
Write-Host "1. Ouvre ce fichier."
Write-Host "2. Copie la valeur apres ITGA_API_KEY= et remplace-la par la vraie cle backend si ce n'est pas deja fait."
Write-Host "3. Dans Codemagic, cree le groupe itga_mobile."
Write-Host "4. Ajoute ITGA_API_KEY, FIREBASE_IOS_PLIST_B64, FIREBASE_ANDROID_JSON_B64 en Secure/Secret."
Write-Host "5. Ne commit jamais codemagic-secrets.local.env."
Write-Host ""
