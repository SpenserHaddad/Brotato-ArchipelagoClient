<#
.SYNOPSIS
    Creates symlinks of the apworld and mod to the Archipelago and Brotato dev areas.

.DESCRIPTION
    This project is not designed to be run on its own. Instead, it's two main
    components, the apworld and client mod, are meant to be symlinked to other dev areas
    where they can actually run. These are:

        * apworld/brotato is symlinked to Archipelago/worlds/brotato.
        * client_mod/mods-unpacked/RampagingHippy-Archipelago is symlinked to 
          <BrotatoRoot>/mods-unpacked/RampagingHippy-Archipelago.

    This requires you to have the Archipelago source code cloned somewhere local from
    https://github.com/ArchipelagoMW/Archipelago/, and to have an unpacked version of
    Brotato, such as from running ./extract_brotato.ps1.

    The Archipelago and Brotato roots are specified as command line arguments. This only
    creates symlinks for the arguments passed in. This allows you to, for example,
    update the client mod symlink if you rebuild the Brotato area without changing the
    apworld's.

.PARAMETER brotatoDir
    The root of the *unpacked* Brotato code. See ./extract_brotato.ps1 for details.
    
#>

param (
    [Parameter][string]$brotatoDir,
    [Parameter][string]$archipelagoDir
)

$GodotExtractTool = "C:\Users\sahko\Projects\BrotatoArchipelago\GDRE_tools-v0.8.0-windows\gdre_tools.exe"

$BrotatoGameDir = "G:\SteamLibrary\steamapps\common\Brotato"
$BrotatoGamePacks = @("Brotato.pck", "BrotatoAbyssalTerrors.pck")

$BrotatoUnpackedPath = "C:\Users\sahko\Projects\BrotatoArchipelago\BrotatoUnpacked"
$BrotatoModsPath = Join-Path -Path $BrotatoUnpackedPath -ChildPath "mods-unpacked"

$ModSrcPath = [IO.Path]::Combine($PSScriptRoot, "client_mod", "mods-unpacked", "RampagingHippy-Archipelago")
$ModDestPath = Join-Path -Path $BrotatoModsPath -ChildPath "RampagingHippy-Archipelago"

$ApRoot = Resolve-Path -Path $([IO.Path]::Combine("..", "..", "Archipelago", "worlds"))
$ApWorldSrcPath = [IO.Path]::Combine($PSScriptRoot, "apworld", "brotato")
$ApWorldDestPath = Join-Path -Path $ApRoot -ChildPath "brotato"

# foreach ($pack in $BrotatoGamePacks) {
#     $PackFullDir = Join-Path -Path $BrotatoGameDir -ChildPath $pack
#     Start-Process -Wait -FilePath $GodotExtractTool -ArgumentList "--extract=$PackFullDir", "--output-dir=$BrotatoUnpackedPath"
#     Write-Output "Extracted $PackFullDir to $BrotatoUnpacked Path"
# }

if (!(Test-Path -Path $BrotatoModsPath)) {
    New-Item -Path $(Join-Path -Path $BrotatoUnpackedPath -ChildPath "mods-unpacked") -ItemType Directory
}

if (Test-Path -Path $ModDestPath) {
    Remove-Item -Path $ModDestPath -Recurse
}

New-Item -Path $ModDestPath -ItemType SymbolicLink -Value $ModSrcPath

# Setup apworld
if (Test-Path -Path $ApWorldDestPath) {
    Remove-Item -Path $ApWorldDestPath -Recurse
}

New-Item -Path $ApWorldDestPath -ItemType Junction -Value $ApWorldSrcPath

