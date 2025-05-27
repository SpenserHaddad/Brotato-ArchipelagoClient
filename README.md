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

# Installing

## apworld

To host or generate games, you will need to add the apworld to your Archipelago
installation. Download the [`brotato.apworld` from the latest
   release.](https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/releases/latest)
Then, either double click the file (on Windows), or copy into
`<archipelago_installation/custom_worlds>` (on Linux) to install.

## Client Mod

Brotato can be played using either the version on
[Steam](https://store.steampowered.com/app/1942280/Brotato/) or the version on [Epic
Games Store](https://store.epicgames.com/en-US/p/brotato-ed4097). The Xbox/Game Pass
version can NOT be used as it does not ship with `ModLoader`, which is necessary for the
mod to work.

### Steam (Workshop Install)

**WARNING:** The workshop mod automatically updates whenever a new version is available.
If you need to use an older version of the mod to complete a multiworld, you will need
to use the manual intallation instructions below.

1. Open the [Steam Workshop for
   Brotato.](https://steamcommunity.com/app/1942280/workshop/)
2. Search for the "Archipelago" mod.
3. Subscribe to the mod to install it.

### Steam (Manual Install)

As of the 1.1.0.0 update, Brotato does not accept mods added any way apart from via the
Workshop. As a workaround, we can use the placeholder mod, and place the Archipelago mod
in that folder.

1. Download [`RampagingHippy-Archipelago.zip` from the latest
   release.](https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/releases/latest)
2. Open the [Steam Workshop for
   Brotato.](https://steamcommunity.com/app/1942280/workshop/)
3. Subscribe to the [[Modders]
   mode](https://steamcommunity.com/sharedfiles/filedetails/?id=3369699033) to download
   it.
4. In a File Explorer, navigate to your Brotato Steam Workshop folder. On Windows, this
   defaults to `C:\Program Files (x86)\steamapps\workshop\content\1942280` (`1942280` is
   Brotato's Steam ID).
5. Open the folder titled `3369699033` in the above directory.
6. Copy the zip file we downloaded in step 1. into this folder.
  - **DO NOT UNZIP THE FILE.**
  - **DO NOT REMOVE ANY OTHER FILES HERE.**

### Epic Games Store

1. Download [`RampagingHippy-Archipelago.zip` from the latest
   release.](https://github.com/SpenserHaddad/Brotato-ArchipelagoClient/releases/latest)
2. Copy the zip file to `<brotato_installation>/mods`.
  - **DO NOT UNZIP THE FILE.**
  - To confirm, there is be a file called `add your zipped mods here` in the folder.
  - If you don't know where to look:
    1. Find Brotato in your EGS library
    2. Click on the three horizontal dots next to its name.
    3. In the window that opens, click the folder+magnifying glass next in the
       "Installation" row.

### From source

NOTE: This is not recommended since unreleased code is more likely to have bugs or
unfinished features. This should only be done if you want to contribute to the project
or really want the bleeding edge.

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

# Development Setup

This repo as-is is not enough to actually load the apworld or client mod, or run the
unit tests. To create a working development environment, you will need some additional
software:

* Git
* An Archipelago-compatible version of Python (e.g. 3.10 or 3.11).
* An installation of Brotato from either Steam or Epic Games (NOT the Xbox version). 
* Clone the [Archipelago repository](https://github.com/ArchipelagoMW/Archipelago/).
* Download the latest version of [GDRETools.](https://github.com/GDRETools/gdsdecomp)
* Download the latest version of [GodotSteam
  3.6.](https://github.com/GodotSteam/GodotSteam).
   * You may need to search through the releases for the latest 3.6-compatible release.

Once you have all of this, the scripts in the [tools/](./tools/) directory can help you
get setup:

* Run [tools/extract_brotato.py](./tools/extract_brotato.py) to unpack the Brotato
  source into an editable form.
  * THIS IS PROPRIETARY CODE, DO NOT DISTRIBUTE OR CHECK INTO THIS REPOSITORY.
* Run [tools/create_dev_symlinks](./tools/create_dev_symlinks.py) to link the code in
  this repo into the Archipelago and Brotato work areas.

From here, you should have a checkout of Archipelago with the Brotato apworld usable, so
you can run the unit tests or generate worlds, and a development version of Brotato with
the client mod installed for easier development and debugging. You can open the Brotato
project with GodotSteam 3.6 to build and run the game.

For additional reading, see [darkly77's Modding Guide on
Steam.](https://steamcommunity.com/sharedfiles/filedetails/?id=2931079751)