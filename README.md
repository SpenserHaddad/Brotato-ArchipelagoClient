# Archipelago Brotato

This adds [Brotato](https://store.steampowered.com/app/1942280/Brotato/) as a game to
be used in [Archipelago](archipelago.gg) multi-world randomizers.

This repo contains two project

* [`brotato_apworld`](./brotato_apworld/): An Archipelago
[apworld](https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/apworld%20specification.md)
folder containing the definitions of items, locations, logic, etc. used by Archipelago
to generate games.
* [`brotato_client_mod`](./brotato_client_mod/): A Brotato game mod which includes an
  Archipelago WebSocket client and hooks for sending locations and receiving items from
  the AP server.

## Installing

### From a release

To host or generate games, you will need to add the apworld to your Archipelago
installation. Download the latest apworld release from the releases page, then copy it
into your Archipelago `worlds/` folder. On Windows by default, this is
`C:\ProgramData\Archipelago\lib\worlds\`.

To play Brotato as part of a randomizer, download the latest version of
`RampagingHippy-ArchipelagoClient`, then copy it into your Steam workshop folder for
Brotato. On Windows by default, this is `C:\Program Files
(x86)\steamapps\workshop\content\1942280` (`1942280` being Brotato's Steam ID). Unzip
the mod into this folder so it's a sub-folder of `1942280`.

### From source

NOTE: This is not recommended since unreleased code is more likely to have bugs or
unfinished features. This should only be done if you want to contribute to the project.

Instead of downloading the .apworld file and mod zip from the releases page, copy the 
`brotato_apworld` folder to the Archipelago `worlds/` folder, renaming it to `brotato`,
and copy the `brotato_client_mod` folder to the Brotato Steam workshop folder.


## Playing Brotato with the mod installed.

If the mod is installed correctly, Brotato's main menu should have an "Archipelago"
button above the "New Game" button. Press it to open the connection menu. Put in the
address/port of the server, your slot name for the game, and the password if necessary.

Once connected to the server, the client mod will override the game state to match your
progress in the AP game. This includes:

* Only unlocking characters that you start with or that someone has found.
* Giving you extra XP, gold, upgrades, and items depending on the items found.
* (WIP) Modifying the number of shop items available based on the progressive shop items
  found.

This won't affect your normal progress. Once you disconnect from the AP server, your
original progress will be reapplied.