param([ValidateSet('windows','android','all')][string]$Target='all')
$ErrorActionPreference='Stop'
Push-Location $PSScriptRoot
try {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no se encuentra en PATH.' }
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falló la descarga de dependencias.' }
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'El análisis detectó problemas.' }
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Las pruebas no pasaron.' }
    New-Item -ItemType Directory -Force releases | Out-Null
    if ($Target -in @('windows','all')) {
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación para Windows.' }
        Compress-Archive -Path build/windows/x64/runner/Release/* -DestinationPath releases/Gaspi-Windows.zip -Force
        Write-Host 'Windows: releases/Gaspi-Windows.zip'
    }
    if ($Target -in @('android','all')) {
        & flutter build apk --release
        if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación para Android.' }
        Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-release.apk -Destination releases/Gaspi-Android.apk -Force
        Write-Host 'Android: releases/Gaspi-Android.apk'
    }
} finally { Pop-Location }

