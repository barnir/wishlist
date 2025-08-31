<#!
.SYNOPSIS
  Gera/mostra keystore release e imprime fingerprints SHA-1/SHA-256 (debug + release) para configurar no Firebase.
.DESCRIPTION
  1. Gera keystore release se não existir.
  2. Extrai SHA1/SHA256 do debug keystore padrão e do keystore release.
  3. Produz blocos prontos para colar no Firebase Console.
.PARAMETER Alias
  Alias da chave release. Default: releasekey
.PARAMETER KeystorePath
  Caminho relativo/absoluto para o keystore. Default: android\app\release.keystore
.PARAMETER ValidityDays
  Validade em dias. Default: 10000
.PARAMETER StorePassword
  Password do keystore (se gerar). Default: changeit123
.PARAMETER KeyPassword
  Password da chave (se gerar). Default: changeit123
.EXAMPLE
  pwsh scripts/generate_fingerprints.ps1
.EXAMPLE
  pwsh scripts/generate_fingerprints.ps1 -Alias mykey -StorePassword S3cr3t! -KeyPassword S3cr3t!
#>
[CmdletBinding()]
param(
  [string]$Alias = 'releasekey',
  [string]$KeystorePath = 'android/app/release.keystore',
  [int]$ValidityDays = 10000,
  [System.Security.SecureString]$StorePassword = $(ConvertTo-SecureString 'changeit123' -AsPlainText -Force),
  [System.Security.SecureString]$KeyPassword = $(ConvertTo-SecureString 'changeit123' -AsPlainText -Force)
)

function Write-Section($title) { Write-Host "`n=== $title ===" -ForegroundColor Cyan }

# 1. Geração keystore se não existir
if (-not (Test-Path $KeystorePath)) {
  Write-Section "Gerar keystore release ($KeystorePath)"
    $plainStore = [System.Net.NetworkCredential]::new('', $StorePassword).Password
    $plainKey = [System.Net.NetworkCredential]::new('', $KeyPassword).Password
    & keytool -genkeypair -v `
      -keystore $KeystorePath `
      -storepass $plainStore `
      -keypass $plainKey `
    -keyalg RSA -keysize 2048 -validity $ValidityDays `
    -alias $Alias `
    -dname "CN=Wishlist, OU=Dev, O=Wishlist, L=Lisboa, S=Lisboa, C=PT" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Falha a gerar keystore." }
  Write-Host "Keystore criado." -ForegroundColor Green
} else {
  Write-Section "Keystore já existe - a reutilizar"
}

# 2. Localizar debug keystore
$debugKs = Join-Path $env:USERPROFILE ".android/debug.keystore"
if (-not (Test-Path $debugKs)) {
  Write-Host "Debug keystore não encontrado em $debugKs (gerar ao fazer build debug)." -ForegroundColor Yellow
}

function Get-Fingerprints($ks, $alias, $storepass, $keypass) {
  $tmp = & keytool -list -v -keystore $ks -storepass $storepass -keypass $keypass -alias $alias 2>$null
  if ($LASTEXITCODE -ne 0) { return $null }
  $sha1 = ($tmp | Select-String 'SHA1:' | ForEach-Object { ($_ -split 'SHA1:')[1].Trim() })
  $sha256 = ($tmp | Select-String 'SHA256:' | ForEach-Object { ($_ -split 'SHA256:')[1].Trim() })
  [PSCustomObject]@{ Keystore=$ks; Alias=$alias; SHA1=$sha1; SHA256=$sha256 }
}

Write-Section "Fingerprints"
$results = @()
if (Test-Path $debugKs) {
  $resDebug = Get-Fingerprints $debugKs 'androiddebugkey' 'android' 'android'
  if ($resDebug) { $results += $resDebug }
}
$plainStore = [System.Net.NetworkCredential]::new('', $StorePassword).Password
$plainKey = [System.Net.NetworkCredential]::new('', $KeyPassword).Password
$releaseRes = Get-Fingerprints $KeystorePath $Alias $plainStore $plainKey
if ($releaseRes) { $results += $releaseRes }

if ($results.Count -eq 0) { throw "Nenhuma fingerprint obtida." }

$results | Format-Table -AutoSize

Write-Section "Copiar para Firebase Console (Project Settings > App > Add Fingerprint)"
foreach ($r in $results) {
  Write-Host "# ${($r.Alias)} ($($r.Keystore))" -ForegroundColor Magenta
  Write-Host "SHA1: $($r.SHA1)"
  Write-Host "SHA256: $($r.SHA256)" -ForegroundColor DarkGray
  Write-Host ""
}

Write-Section "Próximos Passos"
@'
1. Abrir Firebase Console > Project Settings > (Separador General) > App Android.
2. Adicionar cada SHA1 e SHA256 (debug + release) em "Fingerprint".
3. Download novo google-services.json e substituir em android/app/.
4. (Opcional) Configurar números de teste: Authentication > Sign-in method > Phone > Add test phone number.
5. Fazer rebuild clean: flutter clean && flutter pub get && flutter run.
6. Testar fluxo OTP – reCAPTCHA deverá reduzir/aparecer menos.
'@ | Write-Host

Write-Host "Concluído." -ForegroundColor Green
