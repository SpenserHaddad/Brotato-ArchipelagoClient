# Archipelago Brotato

This adds [Brotato](https://store.steampowered.com/app/1942280/Brotato/) as a game to
be used in [Archipelago](archipelago.gg) multi-world randomizers.

This repo contains two projects:

* [`apworld/brotato`](./apworld/brotato): An Archipelago
[apworld](https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/apworld%20specification.md)
folder containing the definitions of items, locations, logic, etc. used by Archipelago
to generate games.
* [`client_mod`](./client_mod/): A Brotato game mod which includes an
  Archipelago WebSocket client and hooks for sending locations and receiving items from
  the Archipelago server.

## Installing

### From a release

To host or generate games, you will need to add the apworld to your Archipelago
installation. Download the latest apworld release from the releases page, then copy it
into your Archipelago `worlds/` folder. On Windows by default, this is
`C:\ProgramData\Archipelago\lib\worlds\`.

To play Brotato as part of a randomizer, download the latest version of
`RampagingHippy-Archipelago.zip`, then copy it **without unzipping** into your Steam
workshop folder for Brotato. For example, on Windows by default this may be `C:\Program
Files
(x86)\steamapps\workshop\content\1942280\Archipelago\RampagingHippy-Archipelago.zip`
(`1942280` being Brotato's Steam ID). Note that the `Archipelago` sub-folder can be
named anything; the .zip file just needs to be within a sub-folder of the `1942280`
folder.

The client mod will eventually be hosted as a Steam workshop mod once it is more stable.

### From source

NOTE: This is not recommended since unreleased code is more likely to have bugs or
unfinished features. This should only be done if you want to contribute to the project.

Instead of downloading the .apworld file and mod zip from the releases page, copy the 
`apworld/brotato` folder to the Archipelago `worlds/` folder, and zip the `client_mod`
folder into a zip called `RampagingHippy-Archipelago.zip` and copy it to Brotato's mod
folder as described above.


## Playing Brotato with the mod installed.

If the mod is installed correctly, Brotato's main menu should have an "Archipelago"
button above the "New Game" button. Press it to open the connection menu. Put in the
address/port of the server, your slot name for the game, and the password if necessary.

Once connected to the server, the client mod will override the game state to match your
progress in the AP game. This includes:

* Only unlocking characters that you start with or that someone has found.
* Giving you extra XP, gold, upgrades, and items depending on the items found.
* Modifying the number of shop items available based on the progressive shop items
  found.

This won't affect your normal progress. Once you disconnect from the AP server, your
original progress will be reapplied.