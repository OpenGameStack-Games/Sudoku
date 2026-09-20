param (
    [string]$AabPath = "game/Game.aab",
    [string]$BundletoolVersion = "1.17.2"
)

$ErrorActionPreference = "Stop"

Write-Host "Exporting Android AAB..."
godot --headless --path ./game --export-release "Android" $AabPath

if (-not (Test-Path "bundletool.jar")) {
    Write-Host "Downloading bundletool..."
    Invoke-WebRequest -Uri "https://github.com/google/bundletool/releases/download/$BundletoolVersion/bundletool-all-$BundletoolVersion.jar" -OutFile "bundletool.jar"
}

Write-Host "Generating APKs..."
$ApksPath = "Game.apks"
java -jar bundletool.jar build-apks --bundle=$AabPath --output=$ApksPath --mode=universal

Write-Host "Extracting APKs..."
if (Test-Path "apks_out") { Remove-Item -Recurse -Force "apks_out" }
Expand-Archive -Path $ApksPath -DestinationPath "apks_out" -Force

Write-Host "Validating and aligning APKs with 16KB page size..."
$ApkFiles = Get-ChildItem -Path "apks_out" -Filter "*.apk"
foreach ($apk in $ApkFiles) {
    Write-Host "Aligning $($apk.Name)..."
    $alignedApk = "$($apk.FullName).aligned"
    zipalign -p -P 16 -f -v 4 $apk.FullName $alignedApk
    Move-Item -Path $alignedApk -Destination $apk.FullName -Force
    
    Write-Host "Validating 16KB alignment for $($apk.Name)..."
    zipalign -c -P 16 -v 4 $apk.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "16KB Alignment validation failed for $($apk.Name)"
        exit 1
    }
}

Write-Host "Release export pipeline completed successfully."
