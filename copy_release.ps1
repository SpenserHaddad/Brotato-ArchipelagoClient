$apworld_path = "C:\ProgramData\Archipelago\lib\worlds\brotato.apworld"
# $mod_path = "G:\SteamLibrary\steamapps\workshop\content\1942280\3384736668\RampagingHippy-Archipelago"
$mod_paths = @(
    "G:\SteamLibrary\steamapps\workshop\content\1942280\3384736668\RampagingHippy-Archipelago",
    "G:\Epic Games\Brotato\mods\RampagingHippy-Archipelago"
)

if (Test-Path -Path $apworld_path) {
    Remove-Item -Path $apworld_path
}


if (Test-Path -Path .\apworld\brotato\__pycache__) {
    Remove-Item .\apworld\brotato\__pycache__
}

# Compress-Archive -Path .\apworld\* -DestinationPath $apworld_path


foreach ($mod_path in $mod_paths) {
    if (Test-Path -Path $mod_path) {
        Remove-Item -Path $mod_path
    }
    Write-Host "Creating mod zip at $mod_path"
    Compress-Archive -Force -Path .\client_mod\* -DestinationPath $mod_path

}